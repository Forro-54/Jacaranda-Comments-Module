Jacaranda Comments 01.00.18

Purpose
-------
This maintenance release improves notification reliability and returns immediately published comments and replies to their exact position in the rendered thread.

Changes
-------
- Success and posting-error notifications now close reliably from the close button.
- Notifications automatically close after 12 seconds without indefinite hover cancellation.
- Notifications appear at the middle-right of the viewport and adapt to smaller screens.
- Each rendered comment/reply has a unique module-scoped target.
- Immediately approved new comments and replies redirect to and focus their exact rendered item.
- Pending comments/replies continue to return to the confirmation area because they are not publicly rendered.
- Redirect targets are verified against the current portal, page, module, approval state, and deletion state.

Database changes
----------------
None. The 01.00.18 SqlDataProvider script is a required no-op upgrade marker.

Installation
------------
Upload Jacaranda_Comments_01.00.18_Install.zip through DNN Extensions. Test on one staging or low-risk page first, then check the DNN Event Viewer.

Suggested tests
---------------
1. Submit an immediately published top-level comment and confirm the page returns to that exact comment.
2. Submit an immediately published reply and confirm the page returns to that exact reply.
3. Submit a pending comment/reply and confirm the page returns to the confirmation area.
4. Confirm success and over-limit error notifications appear at middle-right.
5. Confirm the close button always dismisses the notification.
6. Confirm notifications close automatically after approximately 12 seconds.
7. Re-test approval, deletion, rate limiting, CAPTCHA, emails, and refresh behaviour.
