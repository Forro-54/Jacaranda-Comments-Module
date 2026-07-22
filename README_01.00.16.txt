Jacaranda Comments 01.00.16

Purpose
-------
This release improves over-length comment handling and makes successful posting
confirmation visible anywhere in a long comments thread.

Changes
-------
- Removes the browser maxlength restriction that could silently crop pasted text.
- Keeps the full pasted text in the comment box.
- Continues showing the configured remaining-character counter, including the
  number of characters over the limit.
- Rejects over-limit comments and replies on the server before database insertion
  or email notification.
- Preserves the entered text after an over-limit validation error.
- Adds a fixed success notification that remains visible regardless of the
  user's current scroll position.
- Keeps the existing inline success message as an accessible fallback.
- The popup can be closed manually and otherwise dismisses automatically.
- No database schema changes are required.

Installation
------------
Upload Jacaranda_Comments_01.00.16_Install.zip through DNN Extensions.
Do not upload the source ZIP or repository update ZIP as the extension package.

Testing notes
-------------
Install on a staging page or one low-risk live page first.

Confirm:
1. Set a low maximum such as 250 or 500 characters.
2. Paste text longer than the configured limit.
3. Confirm the full pasted text remains visible and is not silently cut off.
4. Confirm the counter reports how many characters are over the limit.
5. Submit the over-limit text and confirm the dynamic server message appears.
6. Confirm the full text remains available so it can be shortened.
7. Submit a valid comment and reply from near the bottom of a long thread.
8. Confirm the fixed success notification is visible without scrolling to the
   top of the comments module.
9. Confirm the notification can be closed and dismisses automatically.
10. Confirm the inline completion message remains available.
11. Confirm moderation, approval, deletion, rate limiting, CAPTCHA, email
    notifications, and page positioning still work.
12. Check the DNN Event Viewer for compile or runtime errors.
