Jacaranda Comments 01.00.20

Purpose
-------
This maintenance release makes success and validation notifications easier to see and keeps them visually attached to the Jacaranda Comments module on multi-column DNN pages.

Changes
-------
- Positions each notification within the visible area of the module instance that generated it.
- Keeps notifications within the comments column instead of allowing them to cover a neighbouring article column.
- Recalculates the notification position during scrolling and browser resizing.
- Adds a strong four-pixel success/error border, stronger shadow, status icon, and larger accessible close button.
- Retains the 12-second automatic dismissal and the inline message fallback.
- Keeps exact return-to-comment/reply positioning from 01.00.19 unchanged.

Database changes
----------------
None. The 01.00.20 SqlDataProvider script is a required no-op upgrade marker.

Installation
------------
Upload Jacaranda_Comments_01.00.20_Install.zip through DNN Extensions. Test on one staging or low-risk page first, then check the DNN Event Viewer.

Suggested tests
---------------
1. Test success and over-limit error notifications in a normal full-width page.
2. Test with the comments module in a left column and a long article in a neighbouring right column.
3. Scroll through a long comments column and confirm the notification remains within the visible module area.
4. Resize the browser and test a stacked mobile layout.
5. Confirm the stronger border, icon, close button, and 12-second automatic dismissal remain clear and reliable.
6. Re-test comments, replies, moderation, approval, deletion, character limits, CAPTCHA, rate limiting, email, and exact return-to-item positioning.
