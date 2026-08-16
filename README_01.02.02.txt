Jacaranda Comments Advanced 01.02.02

Purpose
-------
This Advanced maintenance release gives guest authors a short correction window
without weakening the existing registered-user or moderation security model.

Repository branch
-----------------
- Stable Simple edition: main branch, version 01.01.03.
- Advanced edition: advanced-settings branch, version 01.02.02.
- Advanced retains the existing DNN package identity and upgrades the existing
  Jacaranda Comments module rather than installing side by side.

Five-minute guest correction window
-----------------------------------
A guest who submits a comment or reply may correct only the submitted text for
up to five minutes from the original CreatedOnDate, provided the submission is
still awaiting moderation.

Guest name and private email cannot be changed through the correction workflow.
The five-minute period never restarts after an edit. Moderator approval, deletion,
expiry of the original five minutes, disabling guest posting, or disabling all
posting immediately prevents further guest correction. Approval and deletion also
clear the stored token hash.

Guest ownership security
------------------------
- A cryptographically strong random guest-edit credential is created server-side
  in the ASP.NET session for the current portal/page/module context.
- Only a SHA-256 hash of that credential is stored with a new guest submission.
- The raw credential is never written to the database, URL, hidden form fields,
  rendered HTML, email notifications, or public output.
- Guest ownership is never inferred from display name, email address, IP address,
  user-agent text, CommentId alone, or the guest rate-limit key.
- Edit permission is checked before loading the edit form and is repeated in the
  parameterised SQL UPDATE itself.
- The UPDATE requires UserId IS NULL, the current portal/page/module scope, the
  matching token hash, IsDeleted = 0, IsApproved = 0, and the original five-minute
  CreatedOnDate window.

Guest visibility during correction
----------------------------------
While the credential is valid, a guest can see their own still-pending recent
submission on the originating module and receives an Edit action. Reply is not
offered on a still-pending submission. This limited visibility ends when the
five-minute window expires or the submission is approved. Approved comments remain
publicly visible under the normal module rules.

Moderation and notifications
----------------------------
Guest corrections always remain pending. A guest can never turn a pending comment
into an approved one. The private language filter is re-evaluated against the
corrected text, edit audit time is recorded, and moderator notification email can
report the corrected guest submission using the existing private guest email
protection/decryption path.

Database change
---------------
01.02.02 adds one nullable column to JacarandaComments:

    GuestEditTokenHash NVARCHAR(64) NULL

Existing comments are not modified. Existing guest submissions have no edit token
hash and therefore do not become retrospectively editable.

Recommended test
----------------
1. Back up the DNN database and website files.
2. Upgrade an Advanced 01.02.01 test site using the 01.02.02 Install ZIP.
3. Enable guest posting on one test module.
4. Submit a guest comment and confirm it remains pending but is visible to the
   same guest browser with an Edit action.
5. Edit only the comment text within five minutes and confirm the correction saves.
6. Confirm the guest display name and email are not editable during correction.
7. Confirm the corrected item remains pending and the moderator notification is sent.
8. Approve a fresh guest submission within five minutes and confirm its Edit action
   disappears immediately for the guest.
9. Submit another guest comment, wait more than five minutes, and confirm editing is
   no longer available.
10. Confirm editing at minute four does not create a new five-minute window.
11. Confirm another browser/session cannot edit the guest submission.
12. Recheck registered-user 15-minute editing, central moderation, CAPTCHA, language
    filtering, rate limiting, approval, deletion, and the DNN Event Viewer.
