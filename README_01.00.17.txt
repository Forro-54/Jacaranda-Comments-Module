Jacaranda Comments 01.00.17

Purpose
-------
This maintenance release improves the position and visibility of comment-form validation errors.

Changes
-------
- Length, CAPTCHA, and rate-limit errors now return the browser to the comment form instead of repeatedly scrolling to the message panel at the top of the module.
- The comment box receives keyboard focus so the user can correct the submission immediately.
- A fixed, dismissible error notification shows the validation reason wherever the user is positioned in a long thread.
- Success and error notifications are positioned at the middle-right of the viewport to reduce eye movement, with a centred full-width mobile layout.
- The existing inline error remains available as a non-popup fallback.
- Over-limit text remains intact and is not inserted into the database or included in notification email.
- There are no database schema changes.

Installation
------------
Upload Jacaranda_Comments_01.00.17_Install.zip through DNN Extensions. Test on one staging or low-risk live page first, then review the DNN Event Viewer.

Suggested tests
---------------
1. Set the module limit to 500 characters.
2. Paste more than 500 characters and submit.
3. Confirm the full text remains in the box.
4. Confirm the page returns to the comment form and the error notification remains visible.
5. Confirm no comment is saved and no notification email is sent.
6. Correct the text and submit successfully.
7. Test CAPTCHA and rate-limit errors with the same form-position behaviour.
