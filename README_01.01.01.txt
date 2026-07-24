Jacaranda Comments 01.01.01

Purpose
-------
This feature release adds opt-in guest commenting and a conservative 15-minute editing window for registered authors. Guest commenting remains switched off by default for every module instance.

Guest commenting
----------------
- Enable “Allow signed-out visitors to submit guest comments and replies” in the module settings.
- Guests must provide a display name, private email address, comment/reply text, and CAPTCHA answer when CAPTCHA is enabled.
- Every guest submission is held for approval, even when registered-user comments are configured for immediate publication.
- Guest email is encrypted before database storage, excluded from public queries/rendering, and included only in private moderator notification emails.
- Guests cannot edit after submission. The form tells visitors to register or sign in before posting if they need the 15-minute edit window.
- Guest posting remains protected by the existing security token, honeypot, server-side validation, parameterised SQL, output encoding, rate limiting, moderation permissions, and parent-comment scope checks.

Registered-author editing
-------------------------
- Registered authors can edit their own comment or reply for 15 minutes from its original UTC creation time.
- The server verifies DNN UserId ownership, portal, page, module, deletion status, and the time window on both edit selection and save.
- Guest comments cannot enter the edit workflow.
- When moderation is required, an edit by a non-editor returns the comment/reply to pending approval.
- Dedicated edit audit fields record when and by whom the text was edited.

Database changes
----------------
The 01.01.01 upgrade script adds nullable GuestEmailEncrypted, GuestRateLimitKey, EditedOnDate, and EditedByUserId columns and a guest rate-limit index. Existing comments are not modified.

Installation
------------
1. Back up the DNN database and website files.
2. Upload Jacaranda_Comments_01.01.01_Install.zip through DNN Extensions.
3. Test the existing registered-user workflow before enabling guest commenting.
4. Enable guest commenting on one staging or low-risk page first.
5. Keep CAPTCHA and rate limiting enabled for public guest posting.
6. Check the DNN Event Viewer and moderator email delivery.

Suggested tests
---------------
1. Confirm guest commenting is off after upgrade and registered posting remains unchanged.
2. Enable guest posting and submit a guest top-level comment and reply.
3. Confirm both remain pending and the private email is never visible on the page.
4. Confirm moderator notification email identifies a guest and includes the private email.
5. Approve and delete guest submissions as an editor/superuser.
6. Test invalid email, empty name, character over-limit, CAPTCHA, honeypot, rate limiting, and forged parent IDs.
7. Post as a registered user, select Edit, save within 15 minutes, and confirm the correct item is targeted.
8. Confirm another user cannot edit the comment and that saving after 15 minutes is rejected server-side.
9. With moderation enabled, confirm a non-editor edit becomes pending.
10. Re-test module-aware notifications, comments, replies, moderation, email, mobile layout, and DNN Edit Mode.
