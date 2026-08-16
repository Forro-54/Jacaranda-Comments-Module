# Jacaranda-Comments-Module
DNN 10 and Bootstrap 5 Standalone Comments Module
Jacaranda Comments is a lightweight DNN 10 comments module built for the Bootstrap 5 skin family. It provides page-level comments and threaded replies, moderation controls, rate limiting, optional CAPTCHA, email notifications, and a settings screen for managing posting behaviour. The module is designed to be simple, secure, DNN-friendly, and suitable for ministry or content-focused websites.

## Release packages

Install the versioned `Jacaranda_Comments_XX.XX.XX_Install.zip` file through DNN Extensions. The source ZIP is for review and development and is not the DNN installation package.

Current package version: **01.00.19**. Test the install package before committing the repository update.

Add a secure five-minute correction window for guest comments and replies while they are still awaiting moderation.

Changes:

Allow guests to edit the text of their own pending comment or reply for up to five minutes after the original submission
Keep the five-minute window tied to the original posting time so editing does not restart the timer
End guest editing immediately when a submission is approved, deleted, guest posting is disabled, or all posting is disabled
Restrict guest editing to comment/reply text only; guest display name and private email remain unchanged
Generate a cryptographically random guest-edit credential and store only its SHA-256 hash with the comment
Keep the raw guest-edit credential out of the database, URLs, query strings, hidden fields, rendered HTML, and moderator emails
Do not use guest name, email, IP address, user-agent, rate-limit key, or Comment ID alone as proof of ownership
Revalidate PortalId, TabId, ModuleId, guest ownership, moderation status, deletion status, token hash, and five-minute expiry during the database update
Keep corrected guest submissions pending moderation
Re-run the private language filter after a guest correction
Preserve the existing 15-minute editing window for registered users
Preserve portal-wide moderation, emergency switches, CAPTCHA, rate limiting, language filtering, email notifications, approval, deletion, and security-token validation
Add GuestEditTokenHash to support secure guest correction
Add and register the 01.02.02 SqlDataProvider upgrade script
Update the manifest, release notes, documentation, resources, and package files

Existing guest comments are not made editable by this upgrade. Only new guest submissions created after 01.02.02 receive the secure correction capability.

This release is part of the Jacaranda Comments Advanced branch. The stable Simple edition remains separate on the main branch.
