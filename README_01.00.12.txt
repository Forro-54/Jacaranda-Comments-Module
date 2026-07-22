Jacaranda Comments 01.00.12

Purpose
-------
This is a focused post-completion navigation and message-state maintenance release.

Changes
-------
- Treats the post-completion query string as valid only while the matching one-time
  session message still exists.
- Prevents an old success message from reappearing after refresh, logout, or reuse
  of the redirected URL.
- Removes the completion query parameters from the browser address bar after the
  first successful redirected load while preserving the comments-module anchor.
- Places the redirect anchor on the comments module container itself.
- Defers the focus/scroll action until page load has completed, improving return
  positioning on DNN pages with skin, PersonaBar, or other late layout changes.
- No database schema change is required.

Installation
------------
Upload Jacaranda_Comments_01.00.12_Install.zip through DNN Extensions.
Do not upload the source ZIP or repository update ZIP as the extension package.

Testing notes
-------------
Install on a staging page or one low-risk live page first.

Confirm:
1. A normal registered user can submit a comment and a threaded reply.
2. After posting, the page returns to the comments module and the completion
   message is visible.
3. Refreshing the page does not show the old completion message again.
4. Logging out and returning to the page does not restore the old message.
5. Pending moderation, approval, deletion, email notifications, CAPTCHA, and
   rate limiting still work normally.
6. DNN Event Viewer shows no module compile or runtime errors.
