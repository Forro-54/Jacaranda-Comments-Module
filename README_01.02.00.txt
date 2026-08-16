Jacaranda Comments Advanced 01.02.00

Purpose
-------
This is the Advanced release line of Jacaranda Comments. It begins from the stable
01.01.03 code base and adds portal-scoped central administration while preserving
the page-specific nature of each comments module instance.

Repository branch
-----------------
- Stable Simple edition: main branch, version 01.01.03.
- Advanced edition: advanced-settings branch, version 01.02.00.
- This is an alternative upgrade line, not a second side-by-side DNN module.
- It keeps the existing DNN package identity, folder and database tables so an
  Advanced installation upgrades an existing Jacaranda Comments installation.
- Do not install the Simple and Advanced packages alternately on a production site
  without first testing the change on staging and taking a full backup.

Safe upgrade behaviour
----------------------
Existing module instances continue using their current local settings after the
upgrade. No module begins inheriting portal defaults until an administrator
deliberately enables the inheritance option for that instance.

Access
------
- Site-wide settings are available only to DNN superusers and members of the
  current portal's built-in Administrators role.
- No new DNN security role is created.
- The central panel repeats the server-side permission check even when its
  navigation link is hidden.
- Every save requires the module's anti-CSRF security token and validated POST values.

Emergency controls
------------------
- Allow new comments and replies anywhere on this portal.
- Allow guest posting anywhere on this portal.
- Emergency switches apply to every Jacaranda Comments instance in the current portal.
- Disabling all posting leaves existing comments visible and keeps moderation actions available.
- Disabling guest posting does not disable registered-user posting.

Portal defaults
---------------
Administrators can define portal defaults for:
- Guest commenting
- Moderation
- Private language filtering and terms
- Maximum comment length
- Rate limiting
- CAPTCHA
- Email notifications and recipients
- Inclusion of comment text in notification emails

Per-module inheritance
----------------------
- A new “Use site-wide Jacaranda Comments defaults for this module” setting is off by default.
- Existing modules keep their local settings after upgrade.
- When inheritance is enabled, local values remain stored but are ignored.
- Switching inheritance off restores the module's previously saved local settings.
- Emergency portal switches always take priority.

Audit and portal isolation
--------------------------
- Central settings are keyed by PortalId.
- Portal administrators can affect only their own portal; superusers retain host-level access.
- The central panel records the UTC modification date and DNN user ID.
- Each module settings page shows the current emergency-control state and whether it is inherited or local.

Database changes
----------------
The 01.02.00 upgrade creates the portal-scoped JacarandaCommentsPortalSettings table.
Existing comments and module settings are not altered.

Installation
------------
1. Back up the DNN database and website files.
2. Confirm the currently installed Jacaranda Comments version is 01.01.03 or earlier.
3. Upload Jacaranda_Comments_Advanced_01.02.00_Install.zip through DNN Extensions.
4. Confirm existing modules still use their local settings.
5. Sign in as a portal administrator or superuser and open Site-wide Comments Settings from a module instance.
6. Save conservative portal defaults.
7. Enable inheritance on one test module only.
8. Test registered and guest posting, replies, editing, moderation, language filtering, CAPTCHA, rate limiting and email.
9. Test both emergency switches and restore them afterward.
10. Confirm ordinary module editors and registered users cannot open the central panel.
11. Check the DNN Event Viewer.
