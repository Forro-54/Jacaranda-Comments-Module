<%@ Control Language="C#" AutoEventWireup="true" Inherits="DotNetNuke.Entities.Modules.PortalModuleBase" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Security.Cryptography" %>
<%@ Import Namespace="DotNetNuke.Common.Utilities" %>
<%@ Import Namespace="DotNetNuke.Data" %>
<%@ Import Namespace="DotNetNuke.Services.Exceptions" %>

<script runat="server">
    private const int MaximumBlockedTermsSettingLength = 8000;
    private const int MaximumBlockedTermCount = 250;
    private const int MaximumBlockedTermLength = 100;
    private const int MaximumNotificationAddressLength = 2000;
    private const string SecurityTokenSessionKeyPrefix = "JacarandaComments_PortalSettingsSecurityToken_";

    private string ConnectionString
    {
        get { return Config.GetConnectionString(); }
    }

    private string PortalSettingsTable
    {
        get
        {
            var provider = DataProvider.Instance();
            var owner = CleanSqlIdentifierPart(provider.DatabaseOwner, "dbo");
            var qualifier = CleanSqlIdentifierPart(provider.ObjectQualifier, String.Empty);
            return "[" + owner + "].[" + qualifier + "JacarandaCommentsPortalSettings]";
        }
    }

    private string SecurityTokenSessionKey
    {
        get { return SecurityTokenSessionKeyPrefix + PortalId + "_" + ModuleId + "_" + UserId; }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        try
        {
            if (!CanManagePortalSettings())
            {
                Response.StatusCode = 403;
                pnlAccessDenied.Visible = true;
                pnlPortalSettings.Visible = false;
                return;
            }

            pnlAccessDenied.Visible = false;
            pnlPortalSettings.Visible = true;

            if (!IsPostBack)
            {
                EnsureSecurityToken();
                LoadPortalSettings();
            }
        }
        catch (Exception ex)
        {
            Exceptions.ProcessModuleLoadException(this, ex);
        }
    }

    protected void btnSave_Click(object sender, EventArgs e)
    {
        try
        {
            if (!CanManagePortalSettings())
            {
                Response.StatusCode = 403;
                ShowMessage("You are not authorised to change site-wide Jacaranda Comments settings.", false);
                return;
            }

            if (!ValidateSecurityToken())
            {
                ShowMessage("For your safety, please refresh the page and try again.", false);
                return;
            }

            Page.Validate("PortalSettings");
            if (!Page.IsValid)
            {
                ShowMessage("Please correct the highlighted settings before saving.", false);
                return;
            }

            SavePortalSettings();
            EnsureSecurityToken(true);
            LoadPortalSettings();
            ShowMessage("Site-wide Jacaranda Comments settings have been saved.", true);
        }
        catch (Exception ex)
        {
            Exceptions.ProcessModuleLoadException(this, ex);
        }
    }

    protected void btnCancel_Click(object sender, EventArgs e)
    {
        Response.Redirect(DotNetNuke.Common.Globals.NavigateURL(TabId), false);
        Context.ApplicationInstance.CompleteRequest();
    }

    private bool CanManagePortalSettings()
    {
        if (UserInfo == null)
        {
            return false;
        }

        if (UserInfo.IsSuperUser)
        {
            return true;
        }

        var administratorRoleName = PortalSettings == null
            ? String.Empty
            : (PortalSettings.AdministratorRoleName ?? String.Empty).Trim();

        return !String.IsNullOrWhiteSpace(administratorRoleName)
            && UserInfo.IsInRole(administratorRoleName);
    }

    private void LoadPortalSettings()
    {
        var settings = ReadPortalSettings();

        chkPostingEnabled.Checked = settings.PostingEnabled;
        chkGuestPostingEnabled.Checked = settings.GuestPostingEnabled;
        chkDefaultAllowGuestComments.Checked = settings.DefaultAllowGuestComments;
        chkDefaultRequireApproval.Checked = settings.DefaultRequireApprovalForNonEditors;
        chkDefaultEnableLanguageFilter.Checked = settings.DefaultEnableLanguageFilter;
        txtDefaultBlockedLanguageTerms.Text = settings.DefaultBlockedLanguageTerms;
        txtDefaultMaximumCommentLength.Text = settings.DefaultMaximumCommentLength.ToString();
        chkDefaultEnableRateLimiting.Checked = settings.DefaultEnableRateLimiting;
        txtDefaultRateLimitSeconds.Text = settings.DefaultRateLimitSeconds.ToString();
        txtDefaultRateLimitMaxPosts.Text = settings.DefaultRateLimitMaxPosts.ToString();
        txtDefaultRateLimitWindowMinutes.Text = settings.DefaultRateLimitWindowMinutes.ToString();
        chkDefaultEnableCaptcha.Checked = settings.DefaultEnableCaptcha;
        chkDefaultEnableNotifications.Checked = settings.DefaultEnableNotifications;
        txtDefaultNotificationEmailAddresses.Text = settings.DefaultNotificationEmailAddresses;
        chkDefaultIncludeCommentTextInNotifications.Checked = settings.DefaultIncludeCommentTextInNotifications;

        if (settings.ModifiedOnDate.HasValue)
        {
            litAudit.Text = "Last changed "
                + Server.HtmlEncode(FormatUtc(settings.ModifiedOnDate.Value))
                + " by DNN user ID "
                + settings.ModifiedByUserId.ToString()
                + ".";
        }
        else
        {
            litAudit.Text = "No site-wide settings have been saved yet. Built-in safe defaults are currently in use.";
        }
    }

    private PortalCommentSettings ReadPortalSettings()
    {
        var settings = PortalCommentSettings.CreateDefaults();

        using (var connection = new SqlConnection(ConnectionString))
        using (var command = connection.CreateCommand())
        {
            command.CommandText = @"
SELECT PostingEnabled,
       GuestPostingEnabled,
       DefaultAllowGuestComments,
       DefaultRequireApprovalForNonEditors,
       DefaultEnableLanguageFilter,
       DefaultBlockedLanguageTerms,
       DefaultMaximumCommentLength,
       DefaultEnableRateLimiting,
       DefaultRateLimitSeconds,
       DefaultRateLimitMaxPosts,
       DefaultRateLimitWindowMinutes,
       DefaultEnableCaptcha,
       DefaultEnableNotifications,
       DefaultNotificationEmailAddresses,
       DefaultIncludeCommentTextInNotifications,
       ModifiedOnDate,
       ModifiedByUserId
FROM " + PortalSettingsTable + @"
WHERE PortalId = @PortalId;";

            command.Parameters.Add("@PortalId", SqlDbType.Int).Value = PortalId;
            connection.Open();

            using (var reader = command.ExecuteReader(CommandBehavior.SingleRow))
            {
                if (!reader.Read())
                {
                    return settings;
                }

                settings.PostingEnabled = ReadBool(reader, "PostingEnabled", true);
                settings.GuestPostingEnabled = ReadBool(reader, "GuestPostingEnabled", true);
                settings.DefaultAllowGuestComments = ReadBool(reader, "DefaultAllowGuestComments", false);
                settings.DefaultRequireApprovalForNonEditors = ReadBool(reader, "DefaultRequireApprovalForNonEditors", true);
                settings.DefaultEnableLanguageFilter = ReadBool(reader, "DefaultEnableLanguageFilter", false);
                settings.DefaultBlockedLanguageTerms = ReadString(reader, "DefaultBlockedLanguageTerms", String.Empty);
                settings.DefaultMaximumCommentLength = ClampInt(ReadInt(reader, "DefaultMaximumCommentLength", 4000), 4000, 250, 10000);
                settings.DefaultEnableRateLimiting = ReadBool(reader, "DefaultEnableRateLimiting", true);
                settings.DefaultRateLimitSeconds = ClampInt(ReadInt(reader, "DefaultRateLimitSeconds", 60), 60, 0, 3600);
                settings.DefaultRateLimitMaxPosts = ClampInt(ReadInt(reader, "DefaultRateLimitMaxPosts", 5), 5, 1, 100);
                settings.DefaultRateLimitWindowMinutes = ClampInt(ReadInt(reader, "DefaultRateLimitWindowMinutes", 15), 15, 1, 1440);
                settings.DefaultEnableCaptcha = ReadBool(reader, "DefaultEnableCaptcha", false);
                settings.DefaultEnableNotifications = ReadBool(reader, "DefaultEnableNotifications", false);
                settings.DefaultNotificationEmailAddresses = ReadString(reader, "DefaultNotificationEmailAddresses", String.Empty);
                settings.DefaultIncludeCommentTextInNotifications = ReadBool(reader, "DefaultIncludeCommentTextInNotifications", true);
                settings.ModifiedOnDate = ReadNullableDateTime(reader, "ModifiedOnDate");
                settings.ModifiedByUserId = ReadInt(reader, "ModifiedByUserId", -1);
            }
        }

        return settings;
    }

    private void SavePortalSettings()
    {
        var blockedTerms = NormalizeBlockedTermsSetting(txtDefaultBlockedLanguageTerms.Text);
        var notificationAddresses = Truncate((txtDefaultNotificationEmailAddresses.Text ?? String.Empty).Trim(), MaximumNotificationAddressLength);
        var maximumCommentLength = ClampInt(txtDefaultMaximumCommentLength.Text, 4000, 250, 10000);
        var rateLimitSeconds = ClampInt(txtDefaultRateLimitSeconds.Text, 60, 0, 3600);
        var rateLimitMaxPosts = ClampInt(txtDefaultRateLimitMaxPosts.Text, 5, 1, 100);
        var rateLimitWindowMinutes = ClampInt(txtDefaultRateLimitWindowMinutes.Text, 15, 1, 1440);

        using (var connection = new SqlConnection(ConnectionString))
        using (var command = connection.CreateCommand())
        {
            command.CommandText = @"
IF EXISTS (SELECT 1 FROM " + PortalSettingsTable + @" WHERE PortalId = @PortalId)
BEGIN
    UPDATE " + PortalSettingsTable + @"
    SET PostingEnabled = @PostingEnabled,
        GuestPostingEnabled = @GuestPostingEnabled,
        DefaultAllowGuestComments = @DefaultAllowGuestComments,
        DefaultRequireApprovalForNonEditors = @DefaultRequireApprovalForNonEditors,
        DefaultEnableLanguageFilter = @DefaultEnableLanguageFilter,
        DefaultBlockedLanguageTerms = @DefaultBlockedLanguageTerms,
        DefaultMaximumCommentLength = @DefaultMaximumCommentLength,
        DefaultEnableRateLimiting = @DefaultEnableRateLimiting,
        DefaultRateLimitSeconds = @DefaultRateLimitSeconds,
        DefaultRateLimitMaxPosts = @DefaultRateLimitMaxPosts,
        DefaultRateLimitWindowMinutes = @DefaultRateLimitWindowMinutes,
        DefaultEnableCaptcha = @DefaultEnableCaptcha,
        DefaultEnableNotifications = @DefaultEnableNotifications,
        DefaultNotificationEmailAddresses = @DefaultNotificationEmailAddresses,
        DefaultIncludeCommentTextInNotifications = @DefaultIncludeCommentTextInNotifications,
        ModifiedOnDate = GETUTCDATE(),
        ModifiedByUserId = @ModifiedByUserId
    WHERE PortalId = @PortalId;
END
ELSE
BEGIN
    INSERT INTO " + PortalSettingsTable + @" (
        PortalId,
        PostingEnabled,
        GuestPostingEnabled,
        DefaultAllowGuestComments,
        DefaultRequireApprovalForNonEditors,
        DefaultEnableLanguageFilter,
        DefaultBlockedLanguageTerms,
        DefaultMaximumCommentLength,
        DefaultEnableRateLimiting,
        DefaultRateLimitSeconds,
        DefaultRateLimitMaxPosts,
        DefaultRateLimitWindowMinutes,
        DefaultEnableCaptcha,
        DefaultEnableNotifications,
        DefaultNotificationEmailAddresses,
        DefaultIncludeCommentTextInNotifications,
        ModifiedOnDate,
        ModifiedByUserId
    )
    VALUES (
        @PortalId,
        @PostingEnabled,
        @GuestPostingEnabled,
        @DefaultAllowGuestComments,
        @DefaultRequireApprovalForNonEditors,
        @DefaultEnableLanguageFilter,
        @DefaultBlockedLanguageTerms,
        @DefaultMaximumCommentLength,
        @DefaultEnableRateLimiting,
        @DefaultRateLimitSeconds,
        @DefaultRateLimitMaxPosts,
        @DefaultRateLimitWindowMinutes,
        @DefaultEnableCaptcha,
        @DefaultEnableNotifications,
        @DefaultNotificationEmailAddresses,
        @DefaultIncludeCommentTextInNotifications,
        GETUTCDATE(),
        @ModifiedByUserId
    );
END";

            command.Parameters.Add("@PortalId", SqlDbType.Int).Value = PortalId;
            command.Parameters.Add("@PostingEnabled", SqlDbType.Bit).Value = chkPostingEnabled.Checked;
            command.Parameters.Add("@GuestPostingEnabled", SqlDbType.Bit).Value = chkGuestPostingEnabled.Checked;
            command.Parameters.Add("@DefaultAllowGuestComments", SqlDbType.Bit).Value = chkDefaultAllowGuestComments.Checked;
            command.Parameters.Add("@DefaultRequireApprovalForNonEditors", SqlDbType.Bit).Value = chkDefaultRequireApproval.Checked;
            command.Parameters.Add("@DefaultEnableLanguageFilter", SqlDbType.Bit).Value = chkDefaultEnableLanguageFilter.Checked;
            command.Parameters.Add("@DefaultBlockedLanguageTerms", SqlDbType.NVarChar, -1).Value = blockedTerms;
            command.Parameters.Add("@DefaultMaximumCommentLength", SqlDbType.Int).Value = maximumCommentLength;
            command.Parameters.Add("@DefaultEnableRateLimiting", SqlDbType.Bit).Value = chkDefaultEnableRateLimiting.Checked;
            command.Parameters.Add("@DefaultRateLimitSeconds", SqlDbType.Int).Value = rateLimitSeconds;
            command.Parameters.Add("@DefaultRateLimitMaxPosts", SqlDbType.Int).Value = rateLimitMaxPosts;
            command.Parameters.Add("@DefaultRateLimitWindowMinutes", SqlDbType.Int).Value = rateLimitWindowMinutes;
            command.Parameters.Add("@DefaultEnableCaptcha", SqlDbType.Bit).Value = chkDefaultEnableCaptcha.Checked;
            command.Parameters.Add("@DefaultEnableNotifications", SqlDbType.Bit).Value = chkDefaultEnableNotifications.Checked;
            command.Parameters.Add("@DefaultNotificationEmailAddresses", SqlDbType.NVarChar, MaximumNotificationAddressLength).Value = notificationAddresses;
            command.Parameters.Add("@DefaultIncludeCommentTextInNotifications", SqlDbType.Bit).Value = chkDefaultIncludeCommentTextInNotifications.Checked;
            command.Parameters.Add("@ModifiedByUserId", SqlDbType.Int).Value = UserId;

            connection.Open();
            command.ExecuteNonQuery();
        }
    }

    private void EnsureSecurityToken()
    {
        EnsureSecurityToken(false);
    }

    private void EnsureSecurityToken(bool rotate)
    {
        if (Session == null || hdnSecurityToken == null)
        {
            return;
        }

        var token = rotate ? String.Empty : Convert.ToString(Session[SecurityTokenSessionKey]);

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

        return SecureEquals(Convert.ToString(Session[SecurityTokenSessionKey]), hdnSecurityToken.Value);
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

    private void ShowMessage(string message, bool success)
    {
        pnlMessage.Visible = true;
        pnlMessage.CssClass = success ? "jc-message jc-message-success" : "jc-message jc-message-error";
        litMessage.Text = Server.HtmlEncode(message ?? String.Empty);
    }

    private string NormalizeBlockedTermsSetting(string raw)
    {
        raw = raw ?? String.Empty;
        if (raw.Length > MaximumBlockedTermsSettingLength)
        {
            raw = raw.Substring(0, MaximumBlockedTermsSettingLength);
        }

        var terms = new List<string>();
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var lines = raw.Replace("\r\n", "\n").Replace('\r', '\n')
            .Split(new[] { '\n' }, StringSplitOptions.RemoveEmptyEntries);

        foreach (var line in lines)
        {
            var term = RemoveControlCharacters((line ?? String.Empty).Trim());
            if (String.IsNullOrWhiteSpace(term)) continue;
            if (term.Length > MaximumBlockedTermLength) term = term.Substring(0, MaximumBlockedTermLength).Trim();
            if (term.Length == 0 || !seen.Add(term)) continue;
            terms.Add(term);
            if (terms.Count >= MaximumBlockedTermCount) break;
        }

        return String.Join(Environment.NewLine, terms.ToArray());
    }

    private static string RemoveControlCharacters(string value)
    {
        if (String.IsNullOrEmpty(value)) return String.Empty;
        var characters = new List<char>(value.Length);
        foreach (var character in value)
        {
            if (!Char.IsControl(character)) characters.Add(character);
        }
        return new String(characters.ToArray());
    }

    private static int ClampInt(string raw, int defaultValue, int minValue, int maxValue)
    {
        int value;
        if (!Int32.TryParse((raw ?? String.Empty).Trim(), out value)) value = defaultValue;
        return ClampInt(value, defaultValue, minValue, maxValue);
    }

    private static int ClampInt(int value, int defaultValue, int minValue, int maxValue)
    {
        if (value < minValue) value = minValue;
        if (value > maxValue) value = maxValue;
        return value;
    }

    private static string Truncate(string value, int maximumLength)
    {
        value = value ?? String.Empty;
        return value.Length <= maximumLength ? value : value.Substring(0, maximumLength);
    }

    private static bool ReadBool(IDataRecord record, string name, bool defaultValue)
    {
        var ordinal = record.GetOrdinal(name);
        return record.IsDBNull(ordinal) ? defaultValue : Convert.ToBoolean(record.GetValue(ordinal));
    }

    private static int ReadInt(IDataRecord record, string name, int defaultValue)
    {
        var ordinal = record.GetOrdinal(name);
        return record.IsDBNull(ordinal) ? defaultValue : Convert.ToInt32(record.GetValue(ordinal));
    }

    private static string ReadString(IDataRecord record, string name, string defaultValue)
    {
        var ordinal = record.GetOrdinal(name);
        return record.IsDBNull(ordinal) ? defaultValue : Convert.ToString(record.GetValue(ordinal));
    }

    private static DateTime? ReadNullableDateTime(IDataRecord record, string name)
    {
        var ordinal = record.GetOrdinal(name);
        return record.IsDBNull(ordinal) ? (DateTime?)null : Convert.ToDateTime(record.GetValue(ordinal));
    }

    private static string FormatUtc(DateTime value)
    {
        return DateTime.SpecifyKind(value, DateTimeKind.Utc).ToString("dd MMM yyyy, h:mm tt") + " UTC";
    }

    private static string CleanSqlIdentifierPart(string value, string defaultValue)
    {
        value = (value ?? String.Empty).Trim();
        if (value.EndsWith(".", StringComparison.Ordinal)) value = value.Substring(0, value.Length - 1);
        value = value.Replace("[", String.Empty).Replace("]", String.Empty).Trim();
        if (String.IsNullOrEmpty(value)) return defaultValue ?? String.Empty;

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

    private sealed class PortalCommentSettings
    {
        public bool PostingEnabled { get; set; }
        public bool GuestPostingEnabled { get; set; }
        public bool DefaultAllowGuestComments { get; set; }
        public bool DefaultRequireApprovalForNonEditors { get; set; }
        public bool DefaultEnableLanguageFilter { get; set; }
        public string DefaultBlockedLanguageTerms { get; set; }
        public int DefaultMaximumCommentLength { get; set; }
        public bool DefaultEnableRateLimiting { get; set; }
        public int DefaultRateLimitSeconds { get; set; }
        public int DefaultRateLimitMaxPosts { get; set; }
        public int DefaultRateLimitWindowMinutes { get; set; }
        public bool DefaultEnableCaptcha { get; set; }
        public bool DefaultEnableNotifications { get; set; }
        public string DefaultNotificationEmailAddresses { get; set; }
        public bool DefaultIncludeCommentTextInNotifications { get; set; }
        public DateTime? ModifiedOnDate { get; set; }
        public int ModifiedByUserId { get; set; }

        public static PortalCommentSettings CreateDefaults()
        {
            return new PortalCommentSettings
            {
                PostingEnabled = true,
                GuestPostingEnabled = true,
                DefaultAllowGuestComments = false,
                DefaultRequireApprovalForNonEditors = true,
                DefaultEnableLanguageFilter = false,
                DefaultBlockedLanguageTerms = String.Empty,
                DefaultMaximumCommentLength = 4000,
                DefaultEnableRateLimiting = true,
                DefaultRateLimitSeconds = 60,
                DefaultRateLimitMaxPosts = 5,
                DefaultRateLimitWindowMinutes = 15,
                DefaultEnableCaptcha = false,
                DefaultEnableNotifications = false,
                DefaultNotificationEmailAddresses = String.Empty,
                DefaultIncludeCommentTextInNotifications = true,
                ModifiedOnDate = null,
                ModifiedByUserId = -1
            };
        }
    }
</script>

<div class="jacaranda-comments jc-settings jc-portal-settings">
    <asp:Panel ID="pnlAccessDenied" runat="server" Visible="false" CssClass="jc-message jc-message-error">
        Site-wide Jacaranda Comments settings are restricted to DNN portal administrators and superusers.
    </asp:Panel>

    <asp:Panel ID="pnlPortalSettings" runat="server">
        <h2>Site-wide Jacaranda Comments Settings</h2>
        <p class="jc-setting-help">
            These settings apply only to this DNN portal. Emergency switches affect every Jacaranda Comments instance in the portal. Defaults affect only modules that explicitly choose to inherit site-wide settings.
        </p>

        <asp:Panel ID="pnlMessage" runat="server" Visible="false" CssClass="jc-message">
            <asp:Literal ID="litMessage" runat="server" />
        </asp:Panel>

        <asp:HiddenField ID="hdnSecurityToken" runat="server" />

        <fieldset class="jc-settings-section jc-emergency-settings">
            <legend>Emergency controls</legend>

            <div class="jc-setting-row">
                <asp:CheckBox ID="chkPostingEnabled" runat="server" Text="Allow new comments and replies anywhere on this portal" />
                <p class="jc-setting-warning">
                    Clearing this switch immediately disables all new comments and replies across the portal. Existing comments remain visible and moderators can still approve or delete them.
                </p>
            </div>

            <div class="jc-setting-row">
                <asp:CheckBox ID="chkGuestPostingEnabled" runat="server" Text="Allow guest posting anywhere on this portal" />
                <p class="jc-setting-warning">
                    Clearing this switch disables guest posting across every module, even where a local module setting or inherited default would otherwise allow guests. Registered-user posting is unaffected.
                </p>
            </div>
        </fieldset>

        <fieldset class="jc-settings-section">
            <legend>Portal defaults</legend>
            <p class="jc-setting-help">
                These values are used only by module instances with “Use site-wide defaults” enabled. Existing modules keep their current local settings after upgrade until an administrator deliberately opts them in.
            </p>

            <div class="jc-setting-row">
                <asp:CheckBox ID="chkDefaultAllowGuestComments" runat="server" Text="Allow guest comments and replies by default" />
            </div>

            <div class="jc-setting-row">
                <asp:CheckBox ID="chkDefaultRequireApproval" runat="server" Text="Hold comments and replies from non-editors for approval by default" />
            </div>

            <div class="jc-setting-row">
                <asp:CheckBox ID="chkDefaultEnableLanguageFilter" runat="server" Text="Enable the private language filter by default" />
            </div>

            <div class="jc-field">
                <asp:Label ID="lblDefaultBlockedLanguageTerms" runat="server" AssociatedControlID="txtDefaultBlockedLanguageTerms" Text="Default private language-filter terms" />
                <asp:TextBox ID="txtDefaultBlockedLanguageTerms" runat="server" TextMode="MultiLine" Rows="7" CssClass="jc-textarea jc-language-terms" />
                <p class="jc-setting-help">Enter one private term or phrase per line. Maximum 250 entries and 100 characters per entry.</p>
            </div>

            <div class="jc-field jc-setting-number">
                <asp:Label ID="lblDefaultMaximumCommentLength" runat="server" AssociatedControlID="txtDefaultMaximumCommentLength" Text="Default maximum characters per comment or reply" />
                <asp:TextBox ID="txtDefaultMaximumCommentLength" runat="server" CssClass="jc-input" MaxLength="5" />
                <asp:RequiredFieldValidator ID="valDefaultMaximumCommentLengthRequired" runat="server" ValidationGroup="PortalSettings" ControlToValidate="txtDefaultMaximumCommentLength" CssClass="jc-validation" Display="Dynamic" ErrorMessage="Enter a maximum comment length." />
                <asp:RangeValidator ID="valDefaultMaximumCommentLengthRange" runat="server" ValidationGroup="PortalSettings" ControlToValidate="txtDefaultMaximumCommentLength" CssClass="jc-validation" Display="Dynamic" Type="Integer" MinimumValue="250" MaximumValue="10000" ErrorMessage="Enter a whole number from 250 to 10,000." />
            </div>
        </fieldset>

        <fieldset class="jc-settings-section">
            <legend>Default rate limiting</legend>
            <div class="jc-setting-row">
                <asp:CheckBox ID="chkDefaultEnableRateLimiting" runat="server" Text="Enable rate limiting for non-editor posters by default" />
            </div>
            <div class="jc-setting-grid">
                <div class="jc-field">
                    <asp:Label ID="lblDefaultRateLimitSeconds" runat="server" AssociatedControlID="txtDefaultRateLimitSeconds" Text="Minimum seconds between posts" />
                    <asp:TextBox ID="txtDefaultRateLimitSeconds" runat="server" CssClass="jc-input" MaxLength="4" />
                </div>
                <div class="jc-field">
                    <asp:Label ID="lblDefaultRateLimitMaxPosts" runat="server" AssociatedControlID="txtDefaultRateLimitMaxPosts" Text="Maximum posts per window" />
                    <asp:TextBox ID="txtDefaultRateLimitMaxPosts" runat="server" CssClass="jc-input" MaxLength="3" />
                </div>
                <div class="jc-field">
                    <asp:Label ID="lblDefaultRateLimitWindowMinutes" runat="server" AssociatedControlID="txtDefaultRateLimitWindowMinutes" Text="Window length in minutes" />
                    <asp:TextBox ID="txtDefaultRateLimitWindowMinutes" runat="server" CssClass="jc-input" MaxLength="4" />
                </div>
            </div>
        </fieldset>

        <fieldset class="jc-settings-section">
            <legend>Default CAPTCHA</legend>
            <div class="jc-setting-row">
                <asp:CheckBox ID="chkDefaultEnableCaptcha" runat="server" Text="Enable the built-in anti-spam CAPTCHA by default" />
            </div>
        </fieldset>

        <fieldset class="jc-settings-section">
            <legend>Default email notifications</legend>
            <div class="jc-setting-row">
                <asp:CheckBox ID="chkDefaultEnableNotifications" runat="server" Text="Email moderators when a new comment or reply is submitted by default" />
            </div>
            <div class="jc-field">
                <asp:Label ID="lblDefaultNotificationEmailAddresses" runat="server" AssociatedControlID="txtDefaultNotificationEmailAddresses" Text="Default notification email address(es)" />
                <asp:TextBox ID="txtDefaultNotificationEmailAddresses" runat="server" TextMode="MultiLine" Rows="3" CssClass="jc-textarea" MaxLength="2000" />
                <p class="jc-setting-help">Separate multiple addresses with commas or semicolons. Leave blank to use the portal email address.</p>
            </div>
            <div class="jc-setting-row">
                <asp:CheckBox ID="chkDefaultIncludeCommentTextInNotifications" runat="server" Text="Include submitted comment text in notification emails by default" />
            </div>
        </fieldset>

        <div class="jc-audit-note"><asp:Literal ID="litAudit" runat="server" /></div>

        <div class="jc-settings-actions">
            <asp:Button ID="btnSave" runat="server" Text="Save site-wide settings" CssClass="jc-submit" ValidationGroup="PortalSettings" OnClick="btnSave_Click" OnClientClick="return confirm('Save these portal-wide Jacaranda Comments settings? Emergency controls may affect every module instance on this portal.');" />
            <asp:Button ID="btnCancel" runat="server" Text="Cancel" CssClass="jc-secondary-button" CausesValidation="false" OnClick="btnCancel_Click" />
        </div>
    </asp:Panel>
</div>
