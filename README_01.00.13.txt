Jacaranda Comments 01.00.13

Purpose
-------
This is a focused moderation Post/Redirect/Get maintenance release.

Changes
-------
- Redirects successful approval and deletion commands to a clean GET response.
- Prevents the browser from offering to resend the moderation form when the page
  is refreshed after an approval or deletion.
- Shows the approval or deletion confirmation once after the redirect.
- Retains the 01.00.12 one-time posting message and comments-module focus fixes.
- No database schema change is required.

Installation
------------
Upload Jacaranda_Comments_01.00.13_Install.zip through DNN Extensions.
Do not upload the source ZIP or repository update ZIP as the extension package.

Testing notes
-------------
Install on a staging page or one low-risk live page first.

Confirm:
1. A normal registered user can submit a comment and threaded reply.
2. Posting returns to the comments module and the completion message appears once.
3. A moderator can approve a pending comment.
4. Refreshing after approval does not offer to resend the form.
5. A moderator can delete a comment, and refreshing afterwards is also safe.
6. Email notifications, CAPTCHA, rate limiting, and permission checks still work.
7. DNN Event Viewer shows no module compile or runtime errors.
