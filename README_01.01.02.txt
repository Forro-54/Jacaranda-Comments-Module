Jacaranda Comments 01.01.02

Purpose
-------
This test release adds a conservative, administrator-controlled language filter. It is a moderation aid: matched submissions are preserved unchanged and held for review rather than censored, rejected, or deleted.

Configuration
-------------
- Open the Jacaranda Comments module settings.
- Under “Language filter”, enable the private language filter.
- Enter one unwanted term or phrase per line.
- The setting is stored separately for each module instance and remains off by default.
- The list is available only on the authorised DNN settings control and is not sent to the public comment form.

Matching behaviour
------------------
- Matching is case-insensitive.
- Unicode text is normalised and punctuation is treated as a separator.
- Entries are matched as whole words or whole phrases to reduce accidental substring matches.
- Up to 250 unique entries are retained, with a maximum of 100 characters per entry.
- Administrator entries are treated only as data; they are not inserted into SQL or compiled as regular expressions.

Moderation behaviour
--------------------
- A match never changes or removes the original comment text.
- The submission is forced to pending approval, including posts from users who would normally be auto-approved.
- Guest comments remain pending as before and receive the same private flag.
- Registered-author edits are checked again; a match returns the edited item to pending approval.
- Visitors see only the normal “waiting for approval” message. They are not told which term matched and cannot see the configured list.
- Authorised moderators see a “Language filter” marker and notification emails state privately that the filter was triggered.

Database changes
----------------
The 01.01.02 upgrade script adds the non-null IsLanguageFlagged BIT field with a default of 0. Existing comments are not changed or re-scanned.

Installation
------------
1. Back up the DNN database and website files.
2. Upload Jacaranda_Comments_01.01.02_Install.zip through DNN Extensions.
3. Confirm existing comments, replies, guest posting, editing, moderation, email and notifications still work with the filter disabled.
4. Enable the filter on one staging or low-risk module instance and enter a harmless test phrase.
5. Check the DNN Event Viewer after the test.

Suggested tests
---------------
1. Confirm the filter is off after upgrade.
2. Add a harmless phrase such as “hold for review” and enable the filter.
3. Post the phrase with different letter case and punctuation; confirm the item is pending.
4. Confirm the public author receives only the normal pending message and cannot see the private term list.
5. Sign in as an editor and confirm the moderator-only marker is visible.
6. Confirm notification email states that the private filter triggered but does not reveal a configured term.
7. Approve the flagged comment and confirm its text is unchanged and safely encoded.
8. Post an innocent longer word containing part of a configured short term; confirm whole-word matching avoids the false substring match.
9. Edit a registered comment within 15 minutes to add a configured phrase; confirm it returns to pending.
10. Disable the filter and confirm normal configured moderation behaviour resumes.
