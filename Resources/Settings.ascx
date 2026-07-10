<%@ Control Language="C#" AutoEventWireup="true" Inherits="DotNetNuke.Entities.Modules.ModuleSettingsBase" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="DotNetNuke.Entities.Modules" %>

<script runat="server">
    private const string SettingPrefix = "JacarandaComments_";

    public override void LoadSettings()
    {
        base.LoadSettings();

        if (Page.IsPostBack)
        {
            return;
        }

        chkRequireApproval.Checked = GetSettingBool("RequireApprovalForNonEditors", true);

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

        controller.UpdateModuleSetting(ModuleId, Key("RequireApprovalForNonEditors"), chkRequireApproval.Checked.ToString());

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
</script>

<div class="jacaranda-comments jc-settings">
    <h2>Jacaranda Comments Settings</h2>

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
                This avoids third-party scripts and keys. It is intentionally lightweight because posting already requires a DNN login.
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
        Settings are stored as DNN module settings, so each instance of the comments module can have its own moderation and anti-spam behaviour.
    </p>
</div>
