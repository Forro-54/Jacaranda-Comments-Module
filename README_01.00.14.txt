Jacaranda Comments 01.00.14

Purpose
-------
This is a focused comment-form positioning and accessibility maintenance release.

Changes
-------
- Returns the page to the comment form when a user selects Reply.
- Places keyboard focus in the comment text box after reply selection.
- Repeats the module-scoped scroll restoration after page load so later DNN
  layout changes do not return the browser to the top of the page.
- Scrolls posting errors and safety messages into view.
- Retains the 01.00.11 security-token fix, the 01.00.12 one-time completion
  messages, and the 01.00.13 moderation Post/Redirect/Get fix.
- No database schema change is required.

Installation
------------
Upload Jacaranda_Comments_01.00.14_Install.zip through DNN Extensions.
Do not upload the source ZIP or repository update ZIP as the extension package.

Testing notes
-------------
Install on a staging page or one low-risk live page first.

Confirm:
1. Selecting Reply returns to the form and places the cursor in the comment box.
2. A normal registered user can submit a new comment and threaded reply.
3. Posting returns to the comments module and displays its completion message.
4. A deliberately rate-limited post displays its message without leaving the
   browser at the top of the page.
5. Approval and deletion still refresh safely without form-resubmission prompts.
6. Email notifications, CAPTCHA, permissions, and moderation still work.
7. DNN Event Viewer shows no module compile or runtime errors.
