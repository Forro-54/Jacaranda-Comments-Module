Jacaranda Comments 01.01.03

Purpose
-------
This maintenance release makes moderator notification emails identify the DNN page immediately. It does not change comment posting, moderation, permissions, database storage, guest commenting, editing, or the language filter.

Licence
-------
- Jacaranda Comments is distributed under the MIT License.
- DNN displays the complete License.txt during extension installation.
- Copyright (c) 2026 Trevor Forrester and Forrest It Services.

Email subject behaviour
-----------------------
- A comment or reply waiting for moderation uses:
  Comment awaiting approval — [Page title]
- An immediately approved new comment or reply uses:
  New comment — [Page title]
- An approved edit uses:
  Comment edited — [Page title]
- The current DNN page name is used.
- If DNN cannot provide the page name, the safe fallback “DNN page” is used.
- The existing email-header cleaning removes carriage returns and line feeds and limits the final subject length.

Email body behaviour
--------------------
Notification bodies now contain separate lines for:
- Portal
- Page title
- Page link
- Module title
- Comment ID
- Author and author type
- Private guest email when applicable
- Approval status
- Private language-filter status when applicable
- Submission or edit time
- Comment text when enabled in module settings

CAPTCHA accessibility
---------------------
- The CAPTCHA answer field now has a three-pixel high-contrast border.
- The answer text is larger and bold.
- The input has a larger minimum height and padding, making it easier to locate and use.
- Keyboard focus uses a strong blue outline and focus ring.
- CAPTCHA generation, validation, permissions, and anti-spam behaviour are unchanged.

Database changes
----------------
There are no database schema changes. The included 01.01.03 SqlDataProvider is a no-op version-tracking script.

Installation
------------
1. Back up the DNN database and website files.
2. Upload Jacaranda_Comments_01.01.03_Install.zip through DNN Extensions.
3. Submit a pending guest or moderated registered comment.
4. Confirm the subject follows “Comment awaiting approval — [Page title]”.
5. Confirm the body contains the correct Page title and Page link.
6. Test a reply and a registered-author edit.
7. Confirm approval, deletion, notifications, guest posting, language filtering and exact return positioning still work.
8. Confirm the CAPTCHA answer field is clearly visible and its keyboard focus outline is easy to follow.
9. Check the DNN Event Viewer.

Suggested tests
---------------
1. Use a page named “Understanding Grace” and confirm the pending subject is exactly “Comment awaiting approval — Understanding Grace”.
2. Test a page title containing an apostrophe, ampersand, dash, or non-English characters.
3. Confirm a reply uses the same pending subject wording and is identified as a reply in the body.
4. Confirm an auto-approved post uses “New comment — [Page title]”.
5. Confirm an approved edit uses “Comment edited — [Page title]”.
6. Confirm the Page link opens the correct page and module instance.
7. Confirm no guest email or private language-filter information appears publicly.
