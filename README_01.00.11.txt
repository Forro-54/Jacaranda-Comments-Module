Jacaranda Comments 01.00.11

Purpose
-------
This is a focused security maintenance release for the custom postback token check.

Changes
-------
- The hidden security token is now initialised only on the first page request.
- On postback, the value submitted by the browser is preserved so it can be compared
  with the token held in the user session.
- The correction applies to comment submission, replies, approval, and deletion.
- Existing moderation, rate limiting, CAPTCHA, notifications, and clean redirect
  behaviour are unchanged.
- No database schema change is required.

Installation
------------
Upload Jacaranda_Comments_01.00.11_Install.zip through DNN Extensions.
Do not upload the source ZIP or an outer repository/distribution ZIP as the extension package.

Testing notes
-------------
Install on a staging page or one low-risk live page first, then recycle the app pool
or clear DNN cache if the previous View.ascx remains compiled.

Confirm:
1. A logged-in user can submit a comment and a threaded reply.
2. Pending comments still require approval when moderation is enabled.
3. An editor can approve and delete comments.
4. A successful post still redirects cleanly, clears the form, reloads comments,
   and displays the completion message.
5. DNN Event Viewer shows no module compile or runtime errors.
