<%@ Control Language="C#" AutoEventWireup="true" Inherits="DotNetNuke.Entities.Modules.ModuleSettingsBase" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="DotNetNuke.Common.Utilities" %>
<%@ Import Namespace="DotNetNuke.Data" %>

<script runat="server">
    public override void LoadSettings()
    {
        base.LoadSettings();

        if (Page.IsPostBack)
        {
            return;
        }

        var centralActive = IsCentralSettingsActive();
        litCentralStatus.Text = centralActive
            ? "Central configuration is active. Every Jacaranda Comments Advanced instance in this portal now uses the settings in Comments Administration."
            : "Central configuration is not yet active. Existing 01.02.x local module settings continue to control each module until a portal administrator reviews and activates central management.";

        var canManage = CanManagePortalSettings();
        pnlPortalSettingsLink.Visible = canManage;
        pnlAdministratorNotice.Visible = !canManage;

        if (canManage)
        {
            lnkPortalSettings.NavigateUrl = EditUrl("PortalSettings");
        }
    }

    public override void UpdateSettings()
    {
        // Advanced 01.03.00 centralises Jacaranda-specific configuration.
        // Existing local DNN module settings are intentionally retained for safe migration
        // but are no longer edited from this control.
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

    private bool IsCentralSettingsActive()
    {
        try
        {
            using (var connection = new SqlConnection(Config.GetConnectionString()))
            using (var command = connection.CreateCommand())
            {
                command.CommandText = @"
SELECT CentralSettingsActive
FROM " + PortalSettingsTable + @"
WHERE PortalId = @PortalId;";
                command.Parameters.Add("@PortalId", SqlDbType.Int).Value = PortalId;
                connection.Open();

                var value = command.ExecuteScalar();
                return value != null && value != DBNull.Value && Convert.ToBoolean(value);
            }
        }
        catch
        {
            return false;
        }
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

    private string CleanSqlIdentifierPart(string value, string defaultValue)
    {
        value = (value ?? String.Empty).Trim();

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
</script>

<div class="jacaranda-comments jc-settings">
    <h2>Jacaranda Comments Advanced Settings</h2>

    <fieldset class="jc-settings-section jc-inheritance-settings">
        <legend>Central administration</legend>

        <p class="jc-setting-help">
            Jacaranda Comments Advanced 01.03.00 manages its commenting configuration in one place for the whole DNN portal. Page-level Jacaranda settings are no longer edited here.
        </p>

        <p class="jc-inheritance-status"><asp:Literal ID="litCentralStatus" runat="server" /></p>

        <p class="jc-setting-help">
            Existing local Jacaranda module settings are retained in DNN for migration safety, but after central configuration is activated they are ignored by the Advanced edition. DNN's normal module title, container, visibility and permission settings remain managed by DNN itself.
        </p>

        <asp:Panel ID="pnlPortalSettingsLink" runat="server" Visible="false" CssClass="jc-central-settings-link">
            <asp:HyperLink ID="lnkPortalSettings"
                           runat="server"
                           CssClass="jc-secondary-button"
                           Text="Open Comments Administration" />
            <p class="jc-setting-help">
                Review portal-wide settings, activate central configuration, moderate pending comments, and manage emergency posting controls here.
            </p>
        </asp:Panel>

        <asp:Panel ID="pnlAdministratorNotice" runat="server" Visible="false">
            <p class="jc-setting-warning">
                Jacaranda Comments Advanced configuration can be changed only by a DNN portal Administrator or Superuser through Comments Administration.
            </p>
        </asp:Panel>
    </fieldset>
</div>
