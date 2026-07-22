<%@ Control Language="C#" AutoEventWireup="true" Inherits="DotNetNuke.Entities.Modules.PortalModuleBase" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Security.Cryptography" %>
<%@ Import Namespace="System.Net.Mail" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="DotNetNuke.Common" %>
<%@ Import Namespace="DotNetNuke.Common.Utilities" %>
<%@ Import Namespace="DotNetNuke.Data" %>
<%@ Import Namespace="DotNetNuke.Services.Exceptions" %>
<%@ Import Namespace="DotNetNuke.Services.Mail" %>

<script runat="server">
    private const int MaxCommentLength = 2000;
    private const int MinCommentLength = 3;
    private const string SettingPrefix = "JacarandaComments_";
    private const string CaptchaAnswerViewStateKey = "JacarandaComments_CaptchaAnswer";
    private const string SecurityTokenSessionKeyPrefix = "JacarandaComments_SecurityToken_";
    private const string PostRedirectMessageSessionKeyPrefix = "JacarandaComments_PostRedirectMessage_";
    private const string PostRedirectSuccessSessionKeyPrefix = "JacarandaComments_PostRedirectSuccess_";
    private const string PostRedirectMessageAnchorPrefix = "jacaranda-comments-message-";
    private const string PostRedirectStatusQueryKey = "jcposted";
    private const string PostRedirectModuleQueryKey = "jcmid";

    private string PostRedirectMessageAnchorId
    {
        get { return PostRedirectMessageAnchorPrefix + ModuleId; }
    }

    private string CommentsTable
    {
        get
        {
            var provider = DataProvider.Instance();
            var owner = CleanSqlIdentifierPart(provider.DatabaseOwner, "dbo");
            var qualifier = CleanSqlIdentifierPart(provider.ObjectQualifier, String.Empty);

            return "[" + owner + "].[" + qualifier + "JacarandaComments]";
        }
    }

    private string SecurityTokenSessionKey
    {
        get
        {
            return SecurityTokenSessionKeyPrefix + PortalId + "_" + TabId + "_" + ModuleId + "_" + UserId;
        }
    }

    private string PostRedirectMessageSessionKey
    {
        get
        {
            return PostRedirectMessageSessionKeyPrefix + PortalId + "_" + TabId + "_" + ModuleId + "_" + UserId;
        }
    }

    private string PostRedirectSuccessSessionKey
    {
        get
        {
            return PostRedirectSuccessSessionKeyPrefix + PortalId + "_" + TabId + "_" + ModuleId + "_" + UserId;
        }
    }

    private string ConnectionString
    {
        get { return Config.GetConnectionString(); }
    }

    protected bool CanPostComments
    {
        get { return UserInfo != null && UserId > -1 && !UserInfo.IsDeleted; }
    }

    protected bool CanModerateComments()
    {
        return UserInfo != null && (UserInfo.IsSuperUser || IsEditable);
    }

    private bool RequireApprovalForNonEditors
    {
        get { return GetModuleSettingBool("RequireApprovalForNonEditors", true); }
    }

    private bool EnableRateLimiting
    {
        get { return GetModuleSettingBool("EnableRateLimiting", true); }
    }

    private int RateLimitSeconds
    {
        get { return GetModuleSettingInt("RateLimitSeconds", 60, 0, 3600); }
    }

    private int RateLimitMaxPosts
    {
        get { return GetModuleSettingInt("RateLimitMaxPosts", 5, 1, 100); }
    }

    private int RateLimitWindowMinutes
    {
        get { return GetModuleSettingInt("RateLimitWindowMinutes", 15, 1, 1440); }
    }

    private bool EnableCaptcha
    {
        get { return GetModuleSettingBool("EnableCaptcha", false); }
    }

    private bool EnableNotifications
    {
        get { return GetModuleSettingBool("EnableNotifications", false); }
    }

    private string NotificationEmailAddresses
    {
        get { return GetModuleSettingString("NotificationEmailAddresses", String.Empty); }
    }

    private bool IncludeCommentTextInNotifications
    {
        get { return GetModuleSettingBool("IncludeCommentTextInNotifications", true); }
    }

    private bool CaptchaAppliesToCurrentUser
    {
        get { return EnableCaptcha && CanPostComments && !CanModerateComments(); }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            EnsureSecurityToken();
            ConfigureForm();
            ClearReplyContext();
            ClearCommentEntryFields();
            EnsureCaptchaChallenge();
            ShowPostCompletionMessageFromRedirect();
            BindComments();
        }
    }

    private string GetCurrentUserDisplayName()
    {
        if (UserInfo == null)
        {
            return "User";
        }

        var displayName = UserInfo.DisplayName;

        if (String.IsNullOrWhiteSpace(displayName))
        {
            displayName = UserInfo.Username;
        }

        if (String.IsNullOrWhiteSpace(displayName))
        {
            displayName = "User " + UserId;
        }

        return Truncate(displayName.Trim(), 100);
    }

    private void EnsureSecurityToken()
    {
        if (Session == null || hdnSecurityToken == null)
        {
            return;
        }

        var token = Convert.ToString(Session[SecurityTokenSessionKey]);

        if (String.IsNullOrWhiteSpace(token))
        {
            token = GenerateSecurityToken();
            Session[SecurityTokenSessionKey] = token;
        }

        hdnSecurityToken.Value = token;
    }

    private bool ValidateSecurityToken()
    {
        if (Session == null || hdnSecurityToken == null)
        {
            return false;
        }

        var expected = Convert.ToString(Session[SecurityTokenSessionKey]);
        var supplied = hdnSecurityToken.Value;

        return SecureEquals(expected, supplied);
    }

    private static string GenerateSecurityToken()
    {
        var bytes = new byte[32];

        using (var rng = RandomNumberGenerator.Create())
        {
            rng.GetBytes(bytes);
        }

        return Convert.ToBase64String(bytes);
    }

    private static bool SecureEquals(string expected, string supplied)
    {
        if (String.IsNullOrEmpty(expected) || String.IsNullOrEmpty(supplied))
        {
            return false;
        }

        var expectedBytes = Encoding.UTF8.GetBytes(expected);
        var suppliedBytes = Encoding.UTF8.GetBytes(supplied);

        var diff = expectedBytes.Length ^ suppliedBytes.Length;
        var length = Math.Min(expectedBytes.Length, suppliedBytes.Length);

        for (var i = 0; i < length; i++)
        {
            diff |= expectedBytes[i] ^ suppliedBytes[i];
        }

        return diff == 0;
    }

    private void ConfigureForm()
    {
        pnlCommentForm.Visible = CanPostComments;
        pnlLoginRequired.Visible = !CanPostComments;
        pnlCaptcha.Visible = CaptchaAppliesToCurrentUser;
        litModerationNote.Text = BuildModerationNote();

        txtDisplayName.ReadOnly = true;
        txtComment.Attributes["autocomplete"] = "off";
        txtCaptcha.Attributes["autocomplete"] = "off";
        txtWebsite.Attributes["autocomplete"] = "off";

        if (CanPostComments)
        {
            txtDisplayName.Text = GetCurrentUserDisplayName();
        }
    }

    private void BindComments()
    {
        var comments = LoadVisibleComments();
        var threadedComments = BuildThreadedComments(comments);

        rptComments.DataSource = threadedComments;
        rptComments.DataBind();

        pnlNoComments.Visible = threadedComments.Rows.Count == 0;
        litCount.Text = threadedComments.Rows.Count == 1 ? "1 comment" : threadedComments.Rows.Count + " comments";
    }

    private DataTable LoadVisibleComments()
    {
        var comments = new DataTable();

        using (var connection = new SqlConnection(ConnectionString))
        using (var command = connection.CreateCommand())
        {
            command.CommandText = @"
SELECT CommentId,
       ParentCommentId,
       DisplayName,
       CommentText,
       IsApproved,
       CreatedOnDate
FROM " + CommentsTable + @"
WHERE PortalId = @PortalId
  AND TabId = @TabId
  AND ModuleId = @ModuleId
  AND IsDeleted = 0
  AND (IsApproved = 1 OR @CanModerate = 1)
ORDER BY CreatedOnDate ASC;";

            command.Parameters.Add("@PortalId", SqlDbType.Int).Value = PortalId;
            command.Parameters.Add("@TabId", SqlDbType.Int).Value = TabId;
            command.Parameters.Add("@ModuleId", SqlDbType.Int).Value = ModuleId;
            command.Parameters.Add("@CanModerate", SqlDbType.Bit).Value = CanModerateComments();

            using (var adapter = new SqlDataAdapter(command))
            {
                adapter.Fill(comments);
            }
        }

        return comments;
    }

    private DataTable BuildThreadedComments(DataTable comments)
    {
        var threadedComments = comments.Clone();

        if (!threadedComments.Columns.Contains("Depth"))
        {
            threadedComments.Columns.Add("Depth", typeof(int));
        }

        AddRowsForParent(comments, threadedComments, null, 0);

        return threadedComments;
    }

    private void AddRowsForParent(DataTable source, DataTable output, int? parentCommentId, int depth)
    {
        // Safety guard in case someone manually edits the database and creates a circular parent/reply chain.
        if (depth > 10)
        {
            return;
        }

        foreach (DataRow sourceRow in source.Rows)
        {
            var rowParentValue = sourceRow["ParentCommentId"];

            var isRootRow = rowParentValue == DBNull.Value || rowParentValue == null;
            var isMatch = parentCommentId.HasValue
                ? (!isRootRow && Convert.ToInt32(rowParentValue) == parentCommentId.Value)
                : isRootRow;

            if (!isMatch)
            {
                continue;
            }

            var outputRow = output.NewRow();

            foreach (DataColumn column in source.Columns)
            {
                outputRow[column.ColumnName] = sourceRow[column.ColumnName];
            }

            outputRow["Depth"] = depth > 3 ? 3 : depth;
            output.Rows.Add(outputRow);

            AddRowsForParent(source, output, Convert.ToInt32(sourceRow["CommentId"]), depth + 1);
        }
    }

    protected void btnSubmit_Click(object sender, EventArgs e)
    {
        pnlMessage.Visible = false;

        if (!CanPostComments)
        {
            ShowMessage("Please sign in before posting a comment.", false);
            ConfigureForm();
            BindComments();
            return;
        }

        if (!ValidateSecurityToken())
        {
            ShowMessage("For your safety, please refresh the page and try again.", false);
            ConfigureForm();
            BindComments();
            return;
        }

        // Honeypot: real people should never fill this hidden field.
        if (!String.IsNullOrWhiteSpace(txtWebsite.Text))
        {
            ClearCommentEntryFields();
            GenerateCaptchaChallenge();

            var honeypotMessage = "Your comment has been received. You can refresh the page safely.";
            QueuePostRedirectMessage(honeypotMessage, true);

            if (TryRedirectAfterSuccessfulPost("received"))
            {
                return;
            }

            ShowMessage(honeypotMessage, true);
            ConfigureForm();
            BindComments();
            RegisterClearCommentFormScript();
            return;
        }

        var displayName = GetCurrentUserDisplayName();
        var commentText = (txtComment.Text ?? String.Empty).Trim();

        if (commentText.Length < MinCommentLength)
        {
            RestoreReplyContextFromHiddenField();
            ShowMessage("Please enter a longer comment.", false);
            ConfigureForm();
            BindComments();
            return;
        }

        if (commentText.Length > MaxCommentLength)
        {
            RestoreReplyContextFromHiddenField();
            ShowMessage("Please keep comments under " + MaxCommentLength + " characters.", false);
            ConfigureForm();
            BindComments();
            return;
        }

        string captchaError;
        if (!ValidateCaptcha(out captchaError))
        {
            RestoreReplyContextFromHiddenField();
            GenerateCaptchaChallenge();
            ShowMessage(captchaError, false);
            ConfigureForm();
            BindComments();
            return;
        }

        string rateLimitError;
        if (!CheckRateLimit(out rateLimitError))
        {
            RestoreReplyContextFromHiddenField();
            ShowMessage(rateLimitError, false);
            ConfigureForm();
            BindComments();
            return;
        }

        int? parentCommentId = null;
        string parentDisplayName = String.Empty;

        if (!TryGetSelectedParentComment(out parentCommentId, out parentDisplayName))
        {
            ClearReplyContext();
            ShowMessage("The comment you are replying to could not be found.", false);
            ConfigureForm();
            BindComments();
            return;
        }

        var autoApprove = CanModerateComments() || !RequireApprovalForNonEditors;
        var newCommentId = 0;

        using (var connection = new SqlConnection(ConnectionString))
        using (var command = connection.CreateCommand())
        {
            command.CommandText = @"
INSERT INTO " + CommentsTable + @" (
    PortalId,
    TabId,
    ModuleId,
    ParentCommentId,
    UserId,
    DisplayName,
    CommentText,
    IsApproved,
    IsDeleted,
    CreatedOnDate,
    CreatedByUserId
)
VALUES (
    @PortalId,
    @TabId,
    @ModuleId,
    @ParentCommentId,
    @UserId,
    @DisplayName,
    @CommentText,
    @IsApproved,
    0,
    GETUTCDATE(),
    @CreatedByUserId
);

SELECT CONVERT(INT, SCOPE_IDENTITY());";

            command.Parameters.Add("@PortalId", SqlDbType.Int).Value = PortalId;
            command.Parameters.Add("@TabId", SqlDbType.Int).Value = TabId;
            command.Parameters.Add("@ModuleId", SqlDbType.Int).Value = ModuleId;

            var parentParameter = command.Parameters.Add("@ParentCommentId", SqlDbType.Int);
            parentParameter.Value = parentCommentId.HasValue ? (object)parentCommentId.Value : DBNull.Value;

            command.Parameters.Add("@UserId", SqlDbType.Int).Value = UserId;
            command.Parameters.Add("@DisplayName", SqlDbType.NVarChar, 100).Value = Truncate(displayName, 100);
            command.Parameters.Add("@CommentText", SqlDbType.NVarChar, MaxCommentLength).Value = commentText;
            command.Parameters.Add("@IsApproved", SqlDbType.Bit).Value = autoApprove;
            command.Parameters.Add("@CreatedByUserId", SqlDbType.Int).Value = UserId;

            connection.Open();
            newCommentId = Convert.ToInt32(command.ExecuteScalar());
        }

        SendNotificationEmail(newCommentId, parentCommentId.HasValue, autoApprove, displayName, commentText);

        ClearCommentEntryFields();
        ClearReplyContext();
        GenerateCaptchaChallenge();
        RegisterClearCommentFormScript();

        var successMessage = autoApprove
            ? (parentCommentId.HasValue
                ? "Your reply has been posted. You can refresh the page safely."
                : "Your comment has been posted. You can refresh the page safely.")
            : (parentCommentId.HasValue
                ? "Your reply was received and is waiting for approval. You can refresh the page safely."
                : "Your comment was received and is waiting for approval. You can refresh the page safely.");

        var statusCode = GetPostRedirectStatusCode(parentCommentId.HasValue, autoApprove);

        QueuePostRedirectMessage(successMessage, true);

        if (TryRedirectAfterSuccessfulPost(statusCode))
        {
            return;
        }

        ShowMessage(successMessage, true);
        ConfigureForm();
        BindComments();
        RegisterClearCommentFormScript();
        return;
    }

    protected void btnCancelReply_Click(object sender, EventArgs e)
    {
        pnlMessage.Visible = false;
        ClearReplyContext();
        ConfigureForm();
        EnsureCaptchaChallenge();
        BindComments();
        RegisterCommentFormFocusScript();
    }

    protected void rptComments_ItemCommand(object source, System.Web.UI.WebControls.RepeaterCommandEventArgs e)
    {
        pnlMessage.Visible = false;

        int commentId;
        if (!Int32.TryParse(Convert.ToString(e.CommandArgument), out commentId))
        {
            ShowMessage("That comment could not be found.", false);
            return;
        }

        if (!ValidateSecurityToken())
        {
            ShowMessage("For your safety, please refresh the page and try again.", false);
            ConfigureForm();
            BindComments();
            return;
        }

        if (String.Equals(e.CommandName, "ReplyTo", StringComparison.OrdinalIgnoreCase))
        {
            if (!CanPostComments)
            {
                ShowMessage("Please sign in before replying.", false);
                ConfigureForm();
                BindComments();
                return;
            }

            string replyToDisplayName;
            if (!TryGetCommentDisplayName(commentId, out replyToDisplayName))
            {
                ShowMessage("The comment you are replying to could not be found.", false);
                ConfigureForm();
                BindComments();
                return;
            }

            SetReplyContext(commentId, replyToDisplayName);
            ConfigureForm();
            EnsureCaptchaChallenge();
            BindComments();
            RegisterCommentFormFocusScript();
            return;
        }

        if (!CanModerateComments())
        {
            ShowMessage("You do not have permission to moderate comments.", false);
            return;
        }

        string moderationMessage = String.Empty;
        string moderationStatusCode = String.Empty;

        if (String.Equals(e.CommandName, "Approve", StringComparison.OrdinalIgnoreCase))
        {
            UpdateCommentApproval(commentId, true);
            moderationMessage = "Comment approved.";
            moderationStatusCode = "comment-approved";
        }
        else if (String.Equals(e.CommandName, "Delete", StringComparison.OrdinalIgnoreCase))
        {
            SoftDeleteComment(commentId);
            moderationMessage = "Comment deleted.";
            moderationStatusCode = "comment-deleted";
        }

        if (!String.IsNullOrWhiteSpace(moderationMessage))
        {
            QueuePostRedirectMessage(moderationMessage, true);

            if (TryRedirectAfterSuccessfulPost(moderationStatusCode))
            {
                return;
            }

            ShowMessage(moderationMessage, true);
        }

        ConfigureForm();
        BindComments();
    }

    private bool TryGetSelectedParentComment(out int? parentCommentId, out string displayName)
    {
        parentCommentId = null;
        displayName = String.Empty;

        var rawParentCommentId = (hdnParentCommentId.Value ?? String.Empty).Trim();

        if (String.IsNullOrWhiteSpace(rawParentCommentId))
        {
            return true;
        }

        int parsedParentCommentId;
        if (!Int32.TryParse(rawParentCommentId, out parsedParentCommentId))
        {
            return false;
        }

        if (!TryGetCommentDisplayName(parsedParentCommentId, out displayName))
        {
            return false;
        }

        parentCommentId = parsedParentCommentId;
        return true;
    }

    private void RestoreReplyContextFromHiddenField()
    {
        int? parentCommentId;
        string displayName;

        if (TryGetSelectedParentComment(out parentCommentId, out displayName) && parentCommentId.HasValue)
        {
            SetReplyContext(parentCommentId.Value, displayName);
        }
    }

    private bool TryGetCommentDisplayName(int commentId, out string displayName)
    {
        displayName = String.Empty;

        using (var connection = new SqlConnection(ConnectionString))
        using (var command = connection.CreateCommand())
        {
            command.CommandText = @"
SELECT TOP 1 DisplayName
FROM " + CommentsTable + @"
WHERE CommentId = @CommentId
  AND PortalId = @PortalId
  AND TabId = @TabId
  AND ModuleId = @ModuleId
  AND IsDeleted = 0
  AND (IsApproved = 1 OR @CanModerate = 1);";

            command.Parameters.Add("@CommentId", SqlDbType.Int).Value = commentId;
            command.Parameters.Add("@PortalId", SqlDbType.Int).Value = PortalId;
            command.Parameters.Add("@TabId", SqlDbType.Int).Value = TabId;
            command.Parameters.Add("@ModuleId", SqlDbType.Int).Value = ModuleId;
            command.Parameters.Add("@CanModerate", SqlDbType.Bit).Value = CanModerateComments();

            connection.Open();
            var result = command.ExecuteScalar();

            if (result == null || result == DBNull.Value)
            {
                return false;
            }

            displayName = Convert.ToString(result);
            return true;
        }
    }

    private void SetReplyContext(int parentCommentId, string displayName)
    {
        hdnParentCommentId.Value = parentCommentId.ToString();
        pnlReplyContext.Visible = true;
        litReplyContext.Text = "Replying to " + Server.HtmlEncode(displayName);
        litFormTitle.Text = "Leave a reply";
        btnSubmit.Text = "Post reply";
    }

    private void ClearReplyContext()
    {
        hdnParentCommentId.Value = String.Empty;
        pnlReplyContext.Visible = false;
        litReplyContext.Text = String.Empty;
        litFormTitle.Text = "Leave a comment";
        btnSubmit.Text = "Post comment";
    }

    private void ClearCommentEntryFields()
    {
        txtComment.Text = String.Empty;
        txtCaptcha.Text = String.Empty;
        txtWebsite.Text = String.Empty;
    }


    private void RegisterStartupScript(string key, string script)
    {
        if (Page == null || String.IsNullOrWhiteSpace(script))
        {
            return;
        }

        try
        {
            var scriptManager = System.Web.UI.ScriptManager.GetCurrent(Page);

            if (scriptManager != null)
            {
                System.Web.UI.ScriptManager.RegisterStartupScript(this, GetType(), key, script, true);
            }
            else
            {
                Page.ClientScript.RegisterStartupScript(GetType(), key, script, true);
            }
        }
        catch
        {
            try
            {
                Page.ClientScript.RegisterStartupScript(GetType(), key, script, true);
            }
            catch
            {
                // Do not break comment posting because a cleanup script could not be registered.
            }
        }
    }

    private void RegisterClearCommentFormScript()
    {
        if (Page == null)
        {
            return;
        }

        var script = @"
(function () {
    function clearField(id) {
        var field = document.getElementById(id);
        if (!field) {
            return;
        }

        field.value = '';
        field.defaultValue = '';
    }

    clearField('" + HttpUtility.JavaScriptStringEncode(txtComment.ClientID) + @"');
    clearField('" + HttpUtility.JavaScriptStringEncode(txtCaptcha.ClientID) + @"');
    clearField('" + HttpUtility.JavaScriptStringEncode(txtWebsite.ClientID) + @"');
})();";

        RegisterStartupScript("JacarandaCommentsClearForm_" + ModuleId, script);
    }

    private bool CheckRateLimit(out string errorMessage)
    {
        errorMessage = String.Empty;

        if (!EnableRateLimiting || CanModerateComments())
        {
            return true;
        }

        var windowMinutes = RateLimitWindowMinutes;
        var maxPosts = RateLimitMaxPosts;
        var minimumSeconds = RateLimitSeconds;

        using (var connection = new SqlConnection(ConnectionString))
        using (var command = connection.CreateCommand())
        {
            command.CommandText = @"
SELECT COUNT(1) AS RecentPostCount,
       ISNULL(DATEDIFF(SECOND, MAX(CreatedOnDate), GETUTCDATE()), 999999) AS SecondsSinceLastPost
FROM " + CommentsTable + @"
WHERE PortalId = @PortalId
  AND CreatedByUserId = @UserId
  AND IsDeleted = 0
  AND CreatedOnDate >= DATEADD(MINUTE, -@WindowMinutes, GETUTCDATE());";

            command.Parameters.Add("@PortalId", SqlDbType.Int).Value = PortalId;
            command.Parameters.Add("@UserId", SqlDbType.Int).Value = UserId;
            command.Parameters.Add("@WindowMinutes", SqlDbType.Int).Value = windowMinutes;

            connection.Open();

            using (var reader = command.ExecuteReader())
            {
                if (reader.Read())
                {
                    var recentPostCount = Convert.ToInt32(reader["RecentPostCount"]);
                    var secondsSinceLastPost = Convert.ToInt32(reader["SecondsSinceLastPost"]);

                    if (minimumSeconds > 0 && secondsSinceLastPost < minimumSeconds)
                    {
                        var secondsToWait = minimumSeconds - secondsSinceLastPost;
                        errorMessage = "Please wait " + secondsToWait + " more second" + (secondsToWait == 1 ? "" : "s") + " before posting again.";
                        return false;
                    }

                    if (recentPostCount >= maxPosts)
                    {
                        errorMessage = "You have reached the comment limit for this time window. Please try again later.";
                        return false;
                    }
                }
            }
        }

        return true;
    }

    private void EnsureCaptchaChallenge()
    {
        if (CaptchaAppliesToCurrentUser && ViewState[CaptchaAnswerViewStateKey] == null)
        {
            GenerateCaptchaChallenge();
        }
    }

    private void GenerateCaptchaChallenge()
    {
        if (!CaptchaAppliesToCurrentUser)
        {
            litCaptchaQuestion.Text = String.Empty;
            ViewState[CaptchaAnswerViewStateKey] = null;
            return;
        }

        var seed = unchecked(Environment.TickCount + (ModuleId * 31) + (UserId * 17));
        var random = new Random(seed);
        var left = random.Next(2, 10);
        var right = random.Next(1, 9);

        ViewState[CaptchaAnswerViewStateKey] = left + right;
        litCaptchaQuestion.Text = left + " + " + right + " =";
        txtCaptcha.Text = String.Empty;
    }

    private bool ValidateCaptcha(out string errorMessage)
    {
        errorMessage = String.Empty;

        if (!CaptchaAppliesToCurrentUser)
        {
            return true;
        }

        var expectedValue = ViewState[CaptchaAnswerViewStateKey];

        if (expectedValue == null)
        {
            errorMessage = "Please answer the anti-spam question.";
            return false;
        }

        int expectedAnswer;
        if (!Int32.TryParse(Convert.ToString(expectedValue), out expectedAnswer))
        {
            errorMessage = "Please answer the anti-spam question again.";
            return false;
        }

        int suppliedAnswer;
        if (!Int32.TryParse((txtCaptcha.Text ?? String.Empty).Trim(), out suppliedAnswer) || suppliedAnswer != expectedAnswer)
        {
            errorMessage = "The anti-spam answer was not correct. Please try again.";
            return false;
        }

        return true;
    }

    private void SendNotificationEmail(int commentId, bool isReply, bool isApproved, string displayName, string commentText)
    {
        if (!EnableNotifications)
        {
            return;
        }

        var recipients = GetNotificationRecipients();

        if (recipients.Count == 0)
        {
            return;
        }

        var fromAddress = PortalSettings != null ? PortalSettings.Email : String.Empty;

        if (String.IsNullOrWhiteSpace(fromAddress) || !IsValidEmailAddress(fromAddress))
        {
            fromAddress = recipients[0];
        }

        if (String.IsNullOrWhiteSpace(fromAddress) || !IsValidEmailAddress(fromAddress))
        {
            return;
        }

        var subject = CleanEmailHeader("New " + (isReply ? "reply" : "comment") + " on " + GetPortalName());
        var body = BuildNotificationBody(commentId, isReply, isApproved, displayName, commentText);

        foreach (var recipient in recipients)
        {
            try
            {
                Mail.SendEmail(fromAddress, recipient, subject, body);
            }
            catch (Exception ex)
            {
                // Do not block comment posting if SMTP is not available.
                Exceptions.LogException(ex);
            }
        }
    }

    private List<string> GetNotificationRecipients()
    {
        var recipients = new List<string>();
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var raw = NotificationEmailAddresses;

        if (String.IsNullOrWhiteSpace(raw) && PortalSettings != null)
        {
            raw = PortalSettings.Email;
        }

        if (String.IsNullOrWhiteSpace(raw))
        {
            return recipients;
        }

        var parts = raw.Split(new[] { ',', ';', '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);

        foreach (var part in parts)
        {
            var email = (part ?? String.Empty).Trim();

            if (String.IsNullOrWhiteSpace(email))
            {
                continue;
            }

            if (!IsValidEmailAddress(email))
            {
                continue;
            }

            if (seen.Add(email))
            {
                recipients.Add(email);
            }
        }

        return recipients;
    }

    private bool IsValidEmailAddress(string email)
    {
        if (String.IsNullOrWhiteSpace(email))
        {
            return false;
        }

        email = email.Trim();

        if (email.IndexOfAny(new[] { '\r', '\n' }) >= 0)
        {
            return false;
        }

        try
        {
            var address = new MailAddress(email);

            if (!String.Equals(address.Address, email, StringComparison.OrdinalIgnoreCase))
            {
                return false;
            }

            try
            {
                return Mail.IsValidEmailAddress(email, PortalId);
            }
            catch
            {
                return true;
            }
        }
        catch
        {
            return false;
        }
    }

    private string CleanEmailHeader(string value)
    {
        value = (value ?? String.Empty).Replace("\r", " ").Replace("\n", " ").Trim();

        if (value.Length > 150)
        {
            value = value.Substring(0, 150);
        }

        return value;
    }

    private static string CleanSqlIdentifierPart(string value, string defaultValue)
    {
        value = (value ?? String.Empty).Trim();

        if (value.EndsWith(".", StringComparison.Ordinal))
        {
            value = value.Substring(0, value.Length - 1);
        }

        value = value.Replace("[", String.Empty).Replace("]", String.Empty).Trim();

        if (String.IsNullOrEmpty(value))
        {
            return defaultValue ?? String.Empty;
        }

        for (var i = 0; i < value.Length; i++)
        {
            var c = value[i];

            if (!((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_'))
            {
                return defaultValue ?? String.Empty;
            }
        }

        return value;
    }

    private string BuildNotificationBody(int commentId, bool isReply, bool isApproved, string displayName, string commentText)
    {
        var body = new StringBuilder();

        body.AppendLine("A new " + (isReply ? "reply" : "comment") + " has been submitted.");
        body.AppendLine();
        body.AppendLine("Portal: " + GetPortalName());
        body.AppendLine("Page: " + GetPageUrl());
        body.AppendLine("Module: " + (ModuleConfiguration != null ? ModuleConfiguration.ModuleTitle : "Jacaranda Comments"));
        body.AppendLine("Comment ID: " + commentId);
        body.AppendLine("Author: " + displayName);
        body.AppendLine("Status: " + (isApproved ? "Approved" : "Waiting for approval"));
        body.AppendLine("Submitted UTC: " + DateTime.UtcNow.ToString("dd MMM yyyy, h:mm tt") + " UTC");

        if (IncludeCommentTextInNotifications)
        {
            body.AppendLine();
            body.AppendLine("Comment:");
            body.AppendLine(commentText);
        }

        body.AppendLine();
        body.AppendLine("Sign in to DNN and open the page/module settings to moderate comments.");

        return body.ToString();
    }

    private string GetPortalName()
    {
        if (PortalSettings != null && !String.IsNullOrWhiteSpace(PortalSettings.PortalName))
        {
            return PortalSettings.PortalName;
        }

        return "DNN site";
    }

    private string GetPageUrl()
    {
        try
        {
            var pageUrl = DotNetNuke.Common.Globals.NavigateURL(TabId);

            if (Request != null && !String.IsNullOrWhiteSpace(pageUrl) && !pageUrl.StartsWith("http", StringComparison.OrdinalIgnoreCase))
            {
                if (pageUrl.StartsWith("/", StringComparison.Ordinal))
                {
                    pageUrl = Request.Url.GetLeftPart(UriPartial.Authority) + pageUrl;
                }
                else
                {
                    pageUrl = Request.Url.GetLeftPart(UriPartial.Authority) + ResolveUrl(pageUrl);
                }
            }

            return pageUrl;
        }
        catch
        {
            return String.Empty;
        }
    }

    private string BuildModerationNote()
    {
        var moderationText = RequireApprovalForNonEditors
            ? "Comments and replies from non-editors are held for approval."
            : "Comments and replies from signed-in users are posted immediately.";

        if (EnableRateLimiting && !CanModerateComments())
        {
            moderationText += " Posting is rate-limited to help reduce spam.";
        }

        if (CaptchaAppliesToCurrentUser)
        {
            moderationText += " Please answer the anti-spam question before posting.";
        }

        return moderationText;
    }

    private void UpdateCommentApproval(int commentId, bool isApproved)
    {
        using (var connection = new SqlConnection(ConnectionString))
        using (var command = connection.CreateCommand())
        {
            command.CommandText = @"
UPDATE " + CommentsTable + @"
SET IsApproved = @IsApproved,
    LastModifiedOnDate = GETUTCDATE(),
    LastModifiedByUserId = @UserId
WHERE CommentId = @CommentId
  AND PortalId = @PortalId
  AND TabId = @TabId
  AND ModuleId = @ModuleId;";

            command.Parameters.Add("@IsApproved", SqlDbType.Bit).Value = isApproved;
            command.Parameters.Add("@UserId", SqlDbType.Int).Value = UserId;
            command.Parameters.Add("@CommentId", SqlDbType.Int).Value = commentId;
            command.Parameters.Add("@PortalId", SqlDbType.Int).Value = PortalId;
            command.Parameters.Add("@TabId", SqlDbType.Int).Value = TabId;
            command.Parameters.Add("@ModuleId", SqlDbType.Int).Value = ModuleId;

            connection.Open();
            command.ExecuteNonQuery();
        }
    }

    private void SoftDeleteComment(int commentId)
    {
        using (var connection = new SqlConnection(ConnectionString))
        using (var command = connection.CreateCommand())
        {
            command.CommandText = @"
UPDATE " + CommentsTable + @"
SET IsDeleted = 1,
    LastModifiedOnDate = GETUTCDATE(),
    LastModifiedByUserId = @UserId
WHERE CommentId = @CommentId
  AND PortalId = @PortalId
  AND TabId = @TabId
  AND ModuleId = @ModuleId;";

            command.Parameters.Add("@UserId", SqlDbType.Int).Value = UserId;
            command.Parameters.Add("@CommentId", SqlDbType.Int).Value = commentId;
            command.Parameters.Add("@PortalId", SqlDbType.Int).Value = PortalId;
            command.Parameters.Add("@TabId", SqlDbType.Int).Value = TabId;
            command.Parameters.Add("@ModuleId", SqlDbType.Int).Value = ModuleId;

            connection.Open();
            command.ExecuteNonQuery();
        }
    }

    private string GetModuleSettingString(string name, string defaultValue)
    {
        var key = SettingPrefix + name;
        var rawValue = Settings[key];

        if (rawValue == null)
        {
            return defaultValue;
        }

        var value = Convert.ToString(rawValue);

        return String.IsNullOrWhiteSpace(value) ? defaultValue : value;
    }

    private bool GetModuleSettingBool(string name, bool defaultValue)
    {
        var raw = GetModuleSettingString(name, defaultValue.ToString());

        bool boolValue;
        if (Boolean.TryParse(raw, out boolValue))
        {
            return boolValue;
        }

        return String.Equals(raw, "1", StringComparison.OrdinalIgnoreCase)
            || String.Equals(raw, "yes", StringComparison.OrdinalIgnoreCase)
            || String.Equals(raw, "on", StringComparison.OrdinalIgnoreCase);
    }

    private int GetModuleSettingInt(string name, int defaultValue, int minValue, int maxValue)
    {
        var raw = GetModuleSettingString(name, defaultValue.ToString());

        int intValue;
        if (!Int32.TryParse(raw, out intValue))
        {
            intValue = defaultValue;
        }

        if (intValue < minValue) intValue = minValue;
        if (intValue > maxValue) intValue = maxValue;

        return intValue;
    }

    protected string Encode(object value)
    {
        return Server.HtmlEncode(Convert.ToString(value));
    }

    protected string CommentBody(object value)
    {
        var encoded = Server.HtmlEncode(Convert.ToString(value));
        return encoded.Replace("\r\n", "<br />").Replace("\n", "<br />");
    }

    protected string CommentStatusCss(object value)
    {
        return Convert.ToBoolean(value) ? "jc-approved" : "jc-pending";
    }

    protected string CommentDepthCss(object value)
    {
        var depth = 0;

        if (value != null && value != DBNull.Value)
        {
            Int32.TryParse(Convert.ToString(value), out depth);
        }

        if (depth < 0) depth = 0;
        if (depth > 3) depth = 3;

        return "jc-depth-" + depth;
    }

    protected string CommentStatusText(object value)
    {
        return Convert.ToBoolean(value) ? "" : "Pending approval";
    }

    protected string FormatDate(object value)
    {
        if (value == null || value == DBNull.Value) return String.Empty;

        var utcDate = DateTime.SpecifyKind(Convert.ToDateTime(value), DateTimeKind.Utc);

        // Use the server's local time zone. If your DNN server runs UTC, this will remain UTC.
        var localDate = utcDate.ToLocalTime();

        return localDate.ToString("dd MMM yyyy, h:mm tt");
    }

    private static string Truncate(string value, int maxLength)
    {
        if (String.IsNullOrEmpty(value)) return String.Empty;
        return value.Length <= maxLength ? value : value.Substring(0, maxLength);
    }

    private void QueuePostRedirectMessage(string message, bool success)
    {
        if (Session == null)
        {
            return;
        }

        Session[PostRedirectMessageSessionKey] = message ?? String.Empty;
        Session[PostRedirectSuccessSessionKey] = success.ToString();
    }

    private void ShowPostCompletionMessageFromRedirect()
    {
        string message;
        bool success;

        if (TryGetPostRedirectMessageFromQuery(out message, out success))
        {
            ShowMessage(message, success);
            ClearCommentEntryFields();
            RegisterClearCommentFormScript();
            RegisterCleanPostRedirectUrlScript();
            return;
        }

        ShowQueuedPostRedirectMessage();
    }

    private bool TryGetPostRedirectMessageFromQuery(out string message, out bool success)
    {
        message = String.Empty;
        success = true;

        if (Request == null || Request.QueryString == null)
        {
            return false;
        }

        var rawModuleId = Request.QueryString[PostRedirectModuleQueryKey];
        int queryModuleId;

        if (!Int32.TryParse(rawModuleId, out queryModuleId) || queryModuleId != ModuleId)
        {
            return false;
        }

        var statusCode = (Request.QueryString[PostRedirectStatusQueryKey] ?? String.Empty).Trim();

        if (String.IsNullOrWhiteSpace(statusCode))
        {
            return false;
        }

        message = GetPostRedirectStatusMessage(statusCode);

        if (String.IsNullOrWhiteSpace(message) || Session == null)
        {
            return false;
        }

        var rawQueuedMessage = Session[PostRedirectMessageSessionKey];

        // A completion query string is valid only for the first redirected request
        // that still has the matching one-time session message. This prevents a
        // refresh, logout, or copied URL from recreating an old success message.
        if (rawQueuedMessage == null)
        {
            return false;
        }

        var queuedMessage = Convert.ToString(rawQueuedMessage);
        var rawSuccess = Session[PostRedirectSuccessSessionKey];

        Session.Remove(PostRedirectMessageSessionKey);
        Session.Remove(PostRedirectSuccessSessionKey);

        if (!String.IsNullOrWhiteSpace(queuedMessage))
        {
            message = queuedMessage;
        }

        if (!Boolean.TryParse(Convert.ToString(rawSuccess), out success))
        {
            success = true;
        }

        return true;
    }

    private void ShowQueuedPostRedirectMessage()
    {
        if (Session == null)
        {
            return;
        }

        var rawMessage = Session[PostRedirectMessageSessionKey];

        if (rawMessage == null)
        {
            return;
        }

        var message = Convert.ToString(rawMessage);
        var rawSuccess = Session[PostRedirectSuccessSessionKey];

        Session.Remove(PostRedirectMessageSessionKey);
        Session.Remove(PostRedirectSuccessSessionKey);

        if (String.IsNullOrWhiteSpace(message))
        {
            return;
        }

        bool success;
        if (!Boolean.TryParse(Convert.ToString(rawSuccess), out success))
        {
            success = true;
        }

        ShowMessage(message, success);
    }

    private string GetPostRedirectStatusCode(bool isReply, bool isApproved)
    {
        if (isReply)
        {
            return isApproved ? "reply-posted" : "reply-pending";
        }

        return isApproved ? "comment-posted" : "comment-pending";
    }

    private string GetPostRedirectStatusMessage(string statusCode)
    {
        statusCode = (statusCode ?? String.Empty).Trim().ToLowerInvariant();

        switch (statusCode)
        {
            case "comment-posted":
                return "Your comment has been posted. You can refresh the page safely.";
            case "comment-pending":
                return "Your comment was received and is waiting for approval. You can refresh the page safely.";
            case "reply-posted":
                return "Your reply has been posted. You can refresh the page safely.";
            case "reply-pending":
                return "Your reply was received and is waiting for approval. You can refresh the page safely.";
            case "received":
                return "Your comment has been received. You can refresh the page safely.";
            case "comment-approved":
                return "Comment approved. You can refresh the page safely.";
            case "comment-deleted":
                return "Comment deleted. You can refresh the page safely.";
            default:
                return String.Empty;
        }
    }

    private void ClearQueuedPostRedirectMessage()
    {
        if (Session == null)
        {
            return;
        }

        Session.Remove(PostRedirectMessageSessionKey);
        Session.Remove(PostRedirectSuccessSessionKey);
    }

    private void RegisterCleanPostRedirectUrlScript()
    {
        if (Page == null)
        {
            return;
        }

        string cleanUrl;

        try
        {
            cleanUrl = AppendMessageAnchor(DotNetNuke.Common.Globals.NavigateURL(TabId, String.Empty));
        }
        catch
        {
            cleanUrl = "#" + PostRedirectMessageAnchorId;
        }

        var script = @"
(function () {
    if (!window.history || !window.history.replaceState) { return; }

    try {
        window.history.replaceState(null, document.title, '"
            + HttpUtility.JavaScriptStringEncode(cleanUrl) + @"');
    } catch (e) { }
})();";

        RegisterStartupScript("JacarandaCommentsCleanPostRedirectUrl_" + ModuleId, script);
    }

    private bool TryRedirectAfterSuccessfulPost(string statusCode)
    {
        var redirectUrl = BuildPostRedirectUrl(statusCode);

        if (String.IsNullOrWhiteSpace(redirectUrl) || Response == null)
        {
            return false;
        }

        try
        {
            Response.Redirect(redirectUrl, false);

            if (Context != null && Context.ApplicationInstance != null)
            {
                Context.ApplicationInstance.CompleteRequest();
            }

            return true;
        }
        catch
        {
            return false;
        }
    }

    private void RegisterPostSuccessRedirectScript(string statusCode)
    {
        if (Page == null)
        {
            return;
        }

        var redirectUrl = BuildPostRedirectUrl(statusCode);

        if (String.IsNullOrWhiteSpace(redirectUrl))
        {
            return;
        }

        var script = @"
(function () {
    var url = '" + HttpUtility.JavaScriptStringEncode(redirectUrl) + @"';

    function go() {
        try {
            window.location.replace(url);
        } catch (e) {
            window.location.href = url;
        }
    }

    window.setTimeout(go, 250);
})();";

        RegisterStartupScript("JacarandaCommentsPostSuccessRedirect_" + ModuleId, script);
    }

    private string BuildPostRedirectUrl(string statusCode)
    {
        var safeStatusCode = (statusCode ?? String.Empty).Trim().ToLowerInvariant();

        if (String.IsNullOrWhiteSpace(safeStatusCode))
        {
            safeStatusCode = "received";
        }

        string redirectUrl;

        try
        {
            redirectUrl = DotNetNuke.Common.Globals.NavigateURL(
                TabId,
                String.Empty,
                PostRedirectStatusQueryKey + "=" + HttpUtility.UrlEncode(safeStatusCode),
                PostRedirectModuleQueryKey + "=" + ModuleId.ToString());
        }
        catch
        {
            redirectUrl = Request != null ? Request.RawUrl : String.Empty;

            if (!String.IsNullOrWhiteSpace(redirectUrl))
            {
                var hashIndex = redirectUrl.IndexOf('#');
                if (hashIndex >= 0)
                {
                    redirectUrl = redirectUrl.Substring(0, hashIndex);
                }

                var separator = redirectUrl.IndexOf('?') >= 0 ? "&" : "?";
                redirectUrl = redirectUrl + separator
                    + PostRedirectStatusQueryKey + "=" + HttpUtility.UrlEncode(safeStatusCode)
                    + "&" + PostRedirectModuleQueryKey + "=" + ModuleId.ToString();
            }
        }

        redirectUrl = AppendMessageAnchor(redirectUrl);

        return redirectUrl;
    }

    private string AppendMessageAnchor(string redirectUrl)
    {
        if (String.IsNullOrWhiteSpace(redirectUrl))
        {
            return redirectUrl;
        }

        var hashIndex = redirectUrl.IndexOf('#');
        if (hashIndex >= 0)
        {
            redirectUrl = redirectUrl.Substring(0, hashIndex);
        }

        return redirectUrl + "#" + PostRedirectMessageAnchorId;
    }

    private void ShowMessage(string message, bool success)
    {
        pnlMessage.Visible = true;
        pnlMessage.CssClass = success
            ? "jc-message jc-message-success jc-message-complete"
            : "jc-message jc-message-error";
        pnlMessage.Attributes["role"] = success ? "status" : "alert";
        pnlMessage.Attributes["aria-live"] = success ? "polite" : "assertive";
        pnlMessage.Attributes["tabindex"] = "-1";

        var encodedMessage = Server.HtmlEncode(message);

        litMessage.Text = success
            ? "<strong>Process complete.</strong> " + encodedMessage
            : encodedMessage;

        RegisterMessageFocusScript();
    }

    private void RegisterMessageFocusScript()
    {
        RegisterScrollAndFocusScript(
            pnlMessage != null ? pnlMessage.ClientID : String.Empty,
            pnlMessage != null ? pnlMessage.ClientID : String.Empty,
            "Message");
    }

    private void RegisterCommentFormFocusScript()
    {
        RegisterScrollAndFocusScript(
            pnlCommentForm != null ? pnlCommentForm.ClientID : String.Empty,
            txtComment != null ? txtComment.ClientID : String.Empty,
            "CommentForm");
    }

    private void RegisterScrollAndFocusScript(string targetClientId, string focusClientId, string keySuffix)
    {
        if (Page == null || String.IsNullOrWhiteSpace(targetClientId))
        {
            return;
        }

        var targetId = HttpUtility.JavaScriptStringEncode(targetClientId);
        var focusId = HttpUtility.JavaScriptStringEncode(focusClientId ?? String.Empty);

        var script = @"
(function () {
    var hasFocused = false;
    var delays = [0, 150, 400, 800, 1400];

    function focusAndScroll() {
        var target = document.getElementById('" + targetId + @"');
        var focusTarget = document.getElementById('" + focusId + @"');

        if (!target) { return; }

        try {
            target.scrollIntoView({ behavior: 'auto', block: 'center' });
        } catch (e) {
            try { target.scrollIntoView(); } catch (ignoreScroll) { }
        }

        if (!hasFocused && focusTarget) {
            try {
                focusTarget.focus({ preventScroll: true });
            } catch (e) {
                try { focusTarget.focus(); } catch (ignoreFocus) { }
            }

            hasFocused = true;
        }
    }

    function scheduleFocus() {
        for (var i = 0; i < delays.length; i++) {
            window.setTimeout(focusAndScroll, delays[i]);
        }
    }

    scheduleFocus();

    if (window.addEventListener) {
        window.addEventListener('load', scheduleFocus);
    }
})();";

        RegisterStartupScript(
            "JacarandaCommentsFocus" + keySuffix + "_" + ModuleId,
            script);
    }
</script>

<div id="<%= PostRedirectMessageAnchorId %>" class="jacaranda-comments">
    <div class="jc-header">
        <h2>Comments</h2>
        <span class="jc-count"><asp:Literal ID="litCount" runat="server" /></span>
    </div>

    <asp:Panel ID="pnlMessage"
               runat="server"
               Visible="false"
               CssClass="jc-message">
        <asp:Literal ID="litMessage" runat="server" />
    </asp:Panel>

    <asp:Panel ID="pnlNoComments" runat="server" CssClass="jc-empty" Visible="false">
        No comments yet.
    </asp:Panel>

    <asp:Repeater ID="rptComments" runat="server" OnItemCommand="rptComments_ItemCommand">
        <ItemTemplate>
            <article class='jc-comment <%# CommentStatusCss(Eval("IsApproved")) %> <%# CommentDepthCss(Eval("Depth")) %>'>
                <header class="jc-comment-meta">
                    <strong class="jc-comment-author"><%# Encode(Eval("DisplayName")) %></strong>
                    <span class="jc-comment-date"><%# FormatDate(Eval("CreatedOnDate")) %></span>
                    <span class="jc-comment-status"><%# CommentStatusText(Eval("IsApproved")) %></span>
                </header>

                <div class="jc-comment-body">
                    <%# CommentBody(Eval("CommentText")) %>
                </div>

                <div class="jc-comment-actions">
                    <asp:LinkButton ID="btnReply"
                                    runat="server"
                                    CssClass="jc-action jc-reply"
                                    CommandName="ReplyTo"
                                    CommandArgument='<%# Eval("CommentId") %>'
                                    Visible='<%# CanPostComments %>'>
                        Reply
                    </asp:LinkButton>

                    <asp:Panel ID="pnlModeration" runat="server" CssClass="jc-moderation" Visible='<%# CanModerateComments() %>'>
                        <asp:LinkButton ID="btnApprove"
                                        runat="server"
                                        CssClass="jc-action"
                                        CommandName="Approve"
                                        CommandArgument='<%# Eval("CommentId") %>'
                                        Visible='<%# !Convert.ToBoolean(Eval("IsApproved")) %>'>
                            Approve
                        </asp:LinkButton>

                        <asp:LinkButton ID="btnDelete"
                                        runat="server"
                                        CssClass="jc-action jc-action-danger"
                                        CommandName="Delete"
                                        CommandArgument='<%# Eval("CommentId") %>'
                                        OnClientClick="return confirm('Delete this comment and its replies from view?');">
                            Delete
                        </asp:LinkButton>
                    </asp:Panel>
                </div>
            </article>
        </ItemTemplate>
    </asp:Repeater>

    <asp:Panel ID="pnlLoginRequired" runat="server" CssClass="jc-login-required">
        Please sign in to leave a comment or reply.
    </asp:Panel>

    <asp:Panel ID="pnlCommentForm" runat="server" CssClass="jc-form">
        <h3><asp:Literal ID="litFormTitle" runat="server" /></h3>

        <asp:HiddenField ID="hdnSecurityToken" runat="server" />
        <asp:HiddenField ID="hdnParentCommentId" runat="server" />

        <asp:Panel ID="pnlReplyContext" runat="server" CssClass="jc-reply-context" Visible="false">
            <asp:Literal ID="litReplyContext" runat="server" />
            <asp:LinkButton ID="btnCancelReply"
                            runat="server"
                            CssClass="jc-cancel-reply"
                            OnClick="btnCancelReply_Click"
                            CausesValidation="false">
                Cancel reply
            </asp:LinkButton>
        </asp:Panel>

        <div class="jc-field">
            <asp:Label ID="lblDisplayName" runat="server" AssociatedControlID="txtDisplayName" Text="Name shown" />
            <asp:TextBox ID="txtDisplayName" runat="server" MaxLength="100" CssClass="jc-input" />
        </div>

        <div class="jc-field jc-hp" aria-hidden="true">
            <asp:Label ID="lblWebsite" runat="server" AssociatedControlID="txtWebsite" Text="Website" />
            <asp:TextBox ID="txtWebsite" runat="server" CssClass="jc-input" TabIndex="-1" autocomplete="off" />
        </div>

        <div class="jc-field">
            <asp:Label ID="lblComment" runat="server" AssociatedControlID="txtComment" Text="Comment" />
            <asp:TextBox ID="txtComment"
                         runat="server"
                         TextMode="MultiLine"
                         Rows="5"
                         MaxLength="2000"
                         CssClass="jc-textarea"
                         autocomplete="off" />
        </div>

        <asp:Panel ID="pnlCaptcha" runat="server" CssClass="jc-field jc-captcha" Visible="false">
            <asp:Label ID="lblCaptcha" runat="server" AssociatedControlID="txtCaptcha" Text="Anti-spam question" />
            <div class="jc-captcha-row">
                <span class="jc-captcha-question"><asp:Literal ID="litCaptchaQuestion" runat="server" /></span>
                <asp:TextBox ID="txtCaptcha" runat="server" MaxLength="5" CssClass="jc-input jc-captcha-input" autocomplete="off" />
            </div>
        </asp:Panel>

        <asp:Button ID="btnSubmit"
                    runat="server"
                    Text="Post comment"
                    CssClass="jc-submit"
                    OnClick="btnSubmit_Click" />

        <p class="jc-note"><asp:Literal ID="litModerationNote" runat="server" /></p>
    </asp:Panel>
</div>
