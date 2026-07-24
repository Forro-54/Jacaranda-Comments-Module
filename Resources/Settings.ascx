<%@ Control Language="C#" AutoEventWireup="true" Inherits="DotNetNuke.Entities.Modules.ModuleSettingsBase" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="DotNetNuke.Entities.Modules" %>

<script runat="server">
    private const string SettingPrefix = "JacarandaComments_";
    private const int MaximumBlockedTermsSettingLength = 8000;
    private const int MaximumBlockedTermCount = 250;
    private const int MaximumBlockedTermLength = 100;

    public override void LoadSettings()
    {
        base.LoadSettings();

        if (Page.IsPostBack)
        {
            return;
        }

        chkAllowGuestComments.Checked = GetSettingBool("AllowGuestComments", false);
        chkRequireApproval.Checked = GetSettingBool("RequireApprovalForNonEditors", true);

        chkEnableLanguageFilter.Checked = GetSettingBool("EnableLanguageFilter", false);
        txtBlockedLanguageTerms.Text = GetSettingString("BlockedLanguageTerms", String.Empty);

        txtMaximumCommentLength.Text = GetSettingInt("MaximumCommentLength", 4000, 250, 10000).ToString();

        chkEnableRateLimiting.Checked = GetSettingBool("EnableRateLimiting", true);
        txtRateLimitSeconds.Text = GetSettingInt("RateLimitSeconds", 60, 0, 3600).ToString();
        txtRateLimitMaxPosts.Text = GetSettingInt("RateLimitMaxPosts", 5, 1, 100).ToString();
        txtRateLimitWindowMinutes.Text = GetSettingInt("RateLimitWindowMinutes", 15, 1, 1440).ToString();

        chkEnableCaptcha.Checked = GetSettingBool("EnableCaptcha", false);

        chkEnableNotifications.Checked = GetSettingBool("EnableNotifications", false);
        txtNotificationEmailAddresses.Text = GetSettingString("NotificationEmailAddresses", String.Empty);
        chkIncludeCommentTextInNotifications.Checked = GetSettingBool("IncludeCommentTextInNotifications", true);
    }

    public override void UpdateSettings()
    {
        var controller = new ModuleController();

        controller.UpdateModuleSetting(ModuleId, Key("AllowGuestComments"), chkAllowGuestComments.Checked.ToString());
        controller.UpdateModuleSetting(ModuleId, Key("RequireApprovalForNonEditors"), chkRequireApproval.Checked.ToString());

        controller.UpdateModuleSetting(ModuleId, Key("EnableLanguageFilter"), chkEnableLanguageFilter.Checked.ToString());
        controller.UpdateModuleSetting(ModuleId, Key("BlockedLanguageTerms"), NormalizeBlockedTermsSetting(txtBlockedLanguageTerms.Text));

        controller.UpdateModuleSetting(ModuleId, Key("MaximumCommentLength"), ClampInt(txtMaximumCommentLength.Text, 4000, 250, 10000).ToString());

        controller.UpdateModuleSetting(ModuleId, Key("EnableRateLimiting"), chkEnableRateLimiting.Checked.ToString());
        controller.UpdateModuleSetting(ModuleId, Key("RateLimitSeconds"), ClampInt(txtRateLimitSeconds.Text, 60, 0, 3600).ToString());
        controller.UpdateModuleSetting(ModuleId, Key("RateLimitMaxPosts"), ClampInt(txtRateLimitMaxPosts.Text, 5, 1, 100).ToString());
        controller.UpdateModuleSetting(ModuleId, Key("RateLimitWindowMinutes"), ClampInt(txtRateLimitWindowMinutes.Text, 15, 1, 1440).ToString());

        controller.UpdateModuleSetting(ModuleId, Key("EnableCaptcha"), chkEnableCaptcha.Checked.ToString());

        controller.UpdateModuleSetting(ModuleId, Key("EnableNotifications"), chkEnableNotifications.Checked.ToString());
        controller.UpdateModuleSetting(ModuleId, Key("NotificationEmailAddresses"), (txtNotificationEmailAddresses.Text ?? String.Empty).Trim());
        controller.UpdateModuleSetting(ModuleId, Key("IncludeCommentTextInNotifications"), chkIncludeCommentTextInNotifications.Checked.ToString());
    }

    private string Key(string name)
    {
        return SettingPrefix + name;
    }

    private string GetSettingString(string name, string defaultValue)
    {
        var rawValue = Settings[Key(name)];

        if (rawValue == null)
        {
            return defaultValue;
        }

        var value = Convert.ToString(rawValue);

        return String.IsNullOrWhiteSpace(value) ? defaultValue : value;
    }

    private bool GetSettingBool(string name, bool defaultValue)
    {
        var raw = GetSettingString(name, defaultValue.ToString());

        bool boolValue;
        if (Boolean.TryParse(raw, out boolValue))
        {
            return boolValue;
        }

        return String.Equals(raw, "1", StringComparison.OrdinalIgnoreCase)
            || String.Equals(raw, "yes", StringComparison.OrdinalIgnoreCase)
            || String.Equals(raw, "on", StringComparison.OrdinalIgnoreCase);
    }

    private int GetSettingInt(string name, int defaultValue, int minValue, int maxValue)
    {
        return ClampInt(GetSettingString(name, defaultValue.ToString()), defaultValue, minValue, maxValue);
    }

    private int ClampInt(string raw, int defaultValue, int minValue, int maxValue)
    {
        int value;

        if (!Int32.TryParse((raw ?? String.Empty).Trim(), out value))
        {
            value = defaultValue;
        }

        if (value < minValue) value = minValue;
        if (value > maxValue) value = maxValue;

        return value;
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

            if (String.IsNullOrWhiteSpace(term))
            {
                continue;
            }

            if (term.Length > MaximumBlockedTermLength)
            {
                term = term.Substring(0, MaximumBlockedTermLength).Trim();
            }

            if (term.Length == 0 || !seen.Add(term))
            {
                continue;
            }

            terms.Add(term);

            if (terms.Count >= MaximumBlockedTermCount)
            {
                break;
            }
        }

        return String.Join(Environment.NewLine, terms.ToArray());
    }

    private string RemoveControlCharacters(string value)
    {
        if (String.IsNullOrEmpty(value))
        {
            return String.Empty;
        }

        var characters = new List<char>(value.Length);

        foreach (var character in value)
        {
            if (!Char.IsControl(character))
            {
                characters.Add(character);
            }
        }

        return new String(characters.ToArray());
    }
</script>

<div class="jacaranda-comments jc-settings">
    <h2>Jacaranda Comments Settings</h2>

    <fieldset class="jc-settings-section">
        <legend>Guest commenting</legend>

        <div class="jc-setting-row">
            <asp:CheckBox ID="chkAllowGuestComments"
                          runat="server"
                          Text="Allow signed-out visitors to submit guest comments and replies" />
            <p class="jc-setting-help">
                Default: off. Guest name and email are required, the email is never shown publicly, and every guest submission is held for approval. Guests cannot edit after submitting; they must register or sign in before posting to receive the 15-minute edit window.
            </p>
            <p class="jc-setting-warning">
                For public guest commenting, enable CAPTCHA and keep rate limiting enabled. You can turn guest commenting off immediately without affecting existing comments.
            </p>
        </div>
    </fieldset>

    <fieldset class="jc-settings-section">
        <legend>Moderation</legend>

        <div class="jc-setting-row">
            <asp:CheckBox ID="chkRequireApproval"
                          runat="server"
                          Text="Hold comments and replies from non-editors for approval" />
            <p class="jc-setting-help">
                Editors, administrators, and superusers can still post immediately and approve/delete comments from the module view.
            </p>
        </div>
    </fieldset>

    <fieldset class="jc-settings-section">
        <legend>Language filter</legend>

        <div class="jc-setting-row">
            <asp:CheckBox ID="chkEnableLanguageFilter"
                          runat="server"
                          Text="Enable the private language filter for comments and replies" />
            <p class="jc-setting-help">
                Default: off. A matching submission is kept unchanged but forced into moderation. The visitor is only told that the submission is waiting for approval.
            </p>
        </div>

        <div class="jc-field">
            <asp:Label ID="lblBlockedLanguageTerms"
                       runat="server"
                       AssociatedControlID="txtBlockedLanguageTerms"
                       Text="Terms or phrases to hold for review" />
            <asp:TextBox ID="txtBlockedLanguageTerms"
                         runat="server"
                         CssClass="jc-textarea jc-language-terms"
                         TextMode="MultiLine"
                         Rows="7"
                         MaxLength="8000" />
            <p class="jc-setting-help">
                Enter one term or phrase per line. Matching is not case-sensitive and treats punctuation as a separator. The list is available only on this authorised settings screen and is not sent to the public comment form. Up to 250 entries are retained, with a maximum of 100 characters per entry.
            </p>
            <p class="jc-setting-warning">
                This is a moderation aid, not a complete content-safety system. Review flagged submissions before approval because simple language filters can produce false matches or be deliberately evaded.
            </p>
        </div>
    </fieldset>

    <fieldset class="jc-settings-section">
        <legend>Comment length</legend>

        <div class="jc-field jc-setting-number">
            <asp:Label ID="lblMaximumCommentLength"
                       runat="server"
                       AssociatedControlID="txtMaximumCommentLength"
                       Text="Maximum characters per comment or reply" />
            <asp:TextBox ID="txtMaximumCommentLength"
                         runat="server"
                         CssClass="jc-input"
                         MaxLength="5" />
            <asp:RequiredFieldValidator ID="valMaximumCommentLengthRequired"
                                        runat="server"
                                        ControlToValidate="txtMaximumCommentLength"
                                        CssClass="jc-validation"
                                        Display="Dynamic"
                                        ErrorMessage="Enter a maximum comment length." />
            <asp:RangeValidator ID="valMaximumCommentLengthRange"
                                runat="server"
                                ControlToValidate="txtMaximumCommentLength"
                                CssClass="jc-validation"
                                Display="Dynamic"
                                Type="Integer"
                                MinimumValue="250"
                                MaximumValue="10000"
                                ErrorMessage="Enter a whole number from 250 to 10,000." />
            <p class="jc-setting-help">
                Default: 4,000 characters. This setting applies to both comments and replies and is stored separately for each module instance.
            </p>
        </div>
    </fieldset>

    <fieldset class="jc-settings-section">
        <legend>Rate limiting</legend>

        <div class="jc-setting-row">
            <asp:CheckBox ID="chkEnableRateLimiting"
                          runat="server"
                          Text="Enable rate limiting for non-editor posters" />
        </div>

        <div class="jc-setting-grid">
            <div class="jc-field">
                <asp:Label ID="lblRateLimitSeconds"
                           runat="server"
                           AssociatedControlID="txtRateLimitSeconds"
                           Text="Minimum seconds between posts" />
                <asp:TextBox ID="txtRateLimitSeconds"
                             runat="server"
                             CssClass="jc-input"
                             MaxLength="4" />
            </div>

            <div class="jc-field">
                <asp:Label ID="lblRateLimitMaxPosts"
                           runat="server"
                           AssociatedControlID="txtRateLimitMaxPosts"
                           Text="Maximum posts per window" />
                <asp:TextBox ID="txtRateLimitMaxPosts"
                             runat="server"
                             CssClass="jc-input"
                             MaxLength="3" />
            </div>

            <div class="jc-field">
                <asp:Label ID="lblRateLimitWindowMinutes"
                           runat="server"
                           AssociatedControlID="txtRateLimitWindowMinutes"
                           Text="Window length in minutes" />
                <asp:TextBox ID="txtRateLimitWindowMinutes"
                             runat="server"
                             CssClass="jc-input"
                             MaxLength="4" />
            </div>
        </div>

        <p class="jc-setting-help">
            Default: 1 minute between posts and 5 posts per 15 minutes. Moderators are not rate-limited.
        </p>
    </fieldset>

    <fieldset class="jc-settings-section">
        <legend>CAPTCHA</legend>

        <div class="jc-setting-row">
            <asp:CheckBox ID="chkEnableCaptcha"
                          runat="server"
                          Text="Enable the built-in anti-spam math CAPTCHA for non-editor posters" />
            <p class="jc-setting-help">
                This avoids third-party scripts and keys. It applies to registered non-editors and to guests when guest commenting is enabled.
            </p>
        </div>
    </fieldset>

    <fieldset class="jc-settings-section">
        <legend>Email notifications</legend>

        <div class="jc-setting-row">
            <asp:CheckBox ID="chkEnableNotifications"
                          runat="server"
                          Text="Email moderators when a new comment or reply is submitted" />
        </div>

        <div class="jc-field">
            <asp:Label ID="lblNotificationEmailAddresses"
                       runat="server"
                       AssociatedControlID="txtNotificationEmailAddresses"
                       Text="Notification email address(es)" />
            <asp:TextBox ID="txtNotificationEmailAddresses"
                         runat="server"
                         TextMode="MultiLine"
                         Rows="3"
                         CssClass="jc-textarea" />
            <p class="jc-setting-help">
                Separate multiple addresses with commas or semicolons. Leave blank to use the portal email address.
            </p>
        </div>

        <div class="jc-setting-row">
            <asp:CheckBox ID="chkIncludeCommentTextInNotifications"
                          runat="server"
                          Text="Include the submitted comment text in notification emails" />
        </div>
    </fieldset>

    <p class="jc-note">
        Settings are stored as DNN module settings, so each instance can independently allow or block guest posting and use its own comment length, moderation, notification, and anti-spam behaviour.
    </p>
</div>
