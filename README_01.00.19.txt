Jacaranda Comments 01.00.19

Purpose
-------
This maintenance release makes exact return-to-item positioning more reliable for immediately published threaded replies in DNN/WebForms pages.

Changes
-------
- Binds the comment repeater before registering the post-completion target.
- Retries locating the new rendered comment or reply for up to approximately six seconds.
- Repeats settling scrolls after the target appears so later DNN layout changes do not move the user away.
- Keeps keyboard focus on the newly published item when it is visible.
- Pending comments and replies still return to the confirmation area because they are not rendered for ordinary users.
- Notification placement and dismissal behaviour from 01.00.18 are unchanged.

Database changes
----------------
None. The 01.00.19 SqlDataProvider script is a required no-op upgrade marker.

Installation
------------
Upload Jacaranda_Comments_01.00.19_Install.zip through DNN Extensions. Test on one staging or low-risk page first, then check the DNN Event Viewer.

Suggested tests
---------------
1. Submit an immediately published top-level comment and confirm the page returns to it.
2. Submit an immediately published reply and confirm the page returns to that exact nested reply.
3. Test a reply several levels deep in a long thread.
4. Submit a reply awaiting moderation and confirm the page returns to the confirmation area rather than an unavailable target.
5. Re-test notification closing, character-limit errors, approval, deletion, CAPTCHA, rate limiting, email, and refresh behaviour.
