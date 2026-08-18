Jacaranda Comments Advanced 01.03.00

Purpose
-------
This Advanced feature release simplifies administration by moving all
Jacaranda-specific configuration to one portal-wide Comments Administration
panel. Comments remain page-specific, but the Advanced edition's behaviour is
configured once for the whole DNN portal.

Repository branch
-----------------
- Stable Simple edition: main branch, version 01.01.03.
- Advanced edition: advanced-settings branch, version 01.03.00.
- Advanced retains the existing DNN package identity and upgrades the existing
  Jacaranda Comments module rather than installing side by side.

Central-only configuration
--------------------------
After activation, every Jacaranda Comments Advanced instance in the current
portal uses Comments Administration for:
- guest commenting;
- moderation;
- private language filtering and blocked terms;
- maximum comment/reply length;
- rate limiting;
- CAPTCHA;
- moderator email notifications and recipients;
- inclusion of comment text in moderator notifications.

The page-level Jacaranda Settings control no longer edits these values. It now
explains the central model and, for DNN Administrators/Superusers, links to
Comments Administration. DNN's own module title, container, visibility and
permission settings remain unchanged.

Safe 01.02.x migration
----------------------
01.03.00 adds CentralSettingsActive to the portal settings table.

The upgrade does NOT automatically switch existing Advanced sites to central
configuration. Existing local Jacaranda module settings continue to operate
until a DNN portal Administrator or Superuser:
1. opens Comments Administration;
2. reviews and optionally saves the portal settings;
3. deliberately selects "Activate central settings for this portal";
4. confirms the site-wide change.

The activation is one-way from the module interface. Existing local values are
left in DNN's ModuleSettings table for migration/recovery safety, but the
Advanced runtime ignores them after activation.

Emergency controls
------------------
The existing portal emergency controls continue to take priority before and
after central activation:
- Allow new comments and replies anywhere on this portal.
- Allow guest posting anywhere on this portal.

Permissions and security
------------------------
Comments Administration remains limited to DNN Superusers and members of the
current portal's built-in Administrators role.

Central activation and saves require the existing anti-CSRF security token.
Portal identity comes from the server-side DNN context. Database writes remain
parameterised. No browser-supplied PortalId is trusted.

Features retained
-----------------
The release keeps:
- portal-wide pending moderation;
- one-at-a-time Approve and Reject/Delete;
- page/module identification and View Page links;
- five-minute guest correction while pending;
- registered-user 15-minute editing;
- guest moderation and encrypted private guest email;
- language filtering;
- CAPTCHA and rate limiting;
- page-aware moderator notification subjects;
- accessible module-aware notifications;
- parameterised SQL and output encoding.

Database change
---------------
01.03.00 adds one column to JacarandaCommentsPortalSettings:

    CentralSettingsActive BIT NOT NULL DEFAULT 0

Existing comments, replies, approvals, guest-edit tokens, and local module
settings are not modified.

Recommended test
----------------
1. Back up the DNN database and website files.
2. Upgrade an Advanced 01.02.02 test site with the 01.03.00 Install ZIP.
3. Before activation, confirm existing modules still behave according to their
   previous local settings.
4. Confirm the portal emergency posting switches still work before activation.
5. Open a module's Jacaranda Settings control and confirm it no longer exposes
   page-level Jacaranda configuration.
6. Open Comments Administration as a portal Administrator/Superuser.
7. Review guest access, moderation, language filter, comment length, rate limits,
   CAPTCHA and notification settings.
8. Save the settings for review and confirm local behaviour has not yet changed.
9. Activate central settings and confirm the warning/confirmation appears.
10. Confirm every Advanced module now follows the central values.
11. Confirm changing a central value affects modules on multiple pages.
12. Recheck central moderation, guest correction, registered editing, approval,
    deletion, email notification and the DNN Event Viewer.
