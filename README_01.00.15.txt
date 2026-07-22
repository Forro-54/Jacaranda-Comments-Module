Jacaranda Comments 01.00.15

Purpose
-------
This release adds a configurable maximum length for comments and replies.

Changes
-------
- Adds a Maximum characters per comment or reply setting to the DNN module settings screen.
- Uses a default of 4,000 characters.
- Allows authorised module editors to set a value from 250 to 10,000 characters.
- Stores the value per module instance, allowing different pages to use different limits.
- Displays the current maximum and a live remaining-character counter beneath the comment box.
- Enforces the saved value again on the server before database insertion or email notification.
- Displays a dynamic error message using the current saved limit.
- Keeps the entered comment in the form when it is over the limit so the user can shorten it.
- No database schema change is required because CommentText already uses NVARCHAR(MAX).

Installation
------------
Upload Jacaranda_Comments_01.00.15_Install.zip through DNN Extensions.
Do not upload the source ZIP or repository update ZIP as the extension package.

Testing notes
-------------
Install on a staging page or one low-risk live page first.

Confirm:
1. The module settings screen displays the new maximum-length field.
2. The default value is 4,000 for a module without a saved value.
3. Values below 250, above 10,000, blank, or non-numeric are rejected by the settings form.
4. A valid changed value is retained after saving and reopening settings.
5. The form guidance, live counter, browser maximum, and over-length message all use the saved value.
6. The same limit applies to new comments and threaded replies.
7. Over-length text remains in the comment box after validation.
8. Comments at or below the configured limit can still be posted, moderated, approved, deleted, and emailed normally.
9. The DNN Event Viewer shows no module compile or runtime errors.
