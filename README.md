# Jacaranda-Comments-Module
DNN 10 and Bootstrap 5 Standalone Comments Module
Jacaranda Comments is a lightweight DNN 10 comments module built for the Bootstrap 5 skin family. It provides page-level comments and threaded replies, moderation controls, rate limiting, optional CAPTCHA, email notifications, and a settings screen for managing posting behaviour. The module is designed to be simple, secure, DNN-friendly, and suitable for ministry or content-focused websites.

## Release packages

Jacaranda Comments for DNN 10: Simple and Advanced Editions

Jacaranda Comments has now developed into two distinct versions, each designed for a different type of DNN website.

Both editions share the same core purpose: providing a secure, accessible, page-specific commenting system for DNN Platform 10.

The difference is primarily how the module is administered.

The Simple edition is designed for sites where each comments module should be configured individually.

The Advanced edition is designed for sites running Jacaranda Comments on multiple pages, where administrators want one central location for configuration and moderation.

Jacaranda Comments Simple

The current Simple edition is:

Jacaranda Comments 01.01.03

The Simple edition remains on the project's main branch.

Its philosophy is straightforward:

Each Jacaranda Comments module manages its own settings.

This makes it particularly suitable for smaller websites, sites with only a few comment-enabled pages, or sites where different pages need significantly different commenting rules.

Page-level configuration

Each instance of Jacaranda Comments can have its own settings.

Administrators can individually configure features such as:

guest commenting;
moderation;
CAPTCHA;
rate limiting;
maximum comment length;
email notifications;
private language filtering.

For example, one page could permit guest comments while another could require visitors to sign in.

This flexibility is one of the main reasons the Simple edition continues to be maintained separately.

Registered and guest comments

Registered DNN users can post comments and threaded replies using their normal DNN account.

Administrators can also enable guest commenting.

When guests are permitted:

a display name is required;
a private email address is required;
the email address is never publicly displayed;
guest submissions are always held for moderation.

Guest commenting can be disabled whenever the site administrator chooses.

Registered-user editing

Registered users can correct their own comments and replies for up to 15 minutes after posting.

The edit permission is checked on the server against the authenticated DNN user account.

This means another registered user cannot simply alter browser values to edit somebody else's comment.

Private language filtering

The Simple edition includes an optional language filter.

Administrators can maintain a private list of terms or phrases that should trigger moderation.

When a match occurs:

the submitted text is not automatically censored;
the comment is not deleted;
it is held for moderator review;
visitors are not shown the private blocked-word list.

This allows human moderators to make the final decision rather than relying entirely on automatic censorship.

Moderator notifications

Moderator email messages identify the page where a submission was made.

For example:

Comment awaiting approval — Understanding Grace

The notification can include:

page title;
page link;
module title;
Comment ID;
author details;
moderation status;
private guest contact information where appropriate;
language-filter information for moderators.

This makes it much easier to find the relevant discussion.

Accessibility

Jacaranda Comments has also received several accessibility improvements.

Success and warning notifications include:

strong contrasting borders;
clearly distinguishable status icons;
prominent headings;
visible close controls;
automatic dismissal.

Notifications remain within the boundaries of the comments module rather than appearing over unrelated page content.

This is especially useful on layouts where a long article appears beside the comments column.

The CAPTCHA answer field also uses:

a stronger border;
larger text;
increased padding;
a prominent keyboard-focus indicator.

These changes make the controls easier to locate for visitors with limited vision.

Jacaranda Comments Advanced

The current Advanced edition is:

Jacaranda Comments Advanced 01.03.00

The Advanced edition is maintained separately on the advanced-settings development branch.

Its philosophy is different:

Comments remain page-specific, but configuration and administration are portal-wide.

This makes the Advanced edition particularly useful for larger sites that may have Jacaranda Comments installed on many different pages.

One central administration panel

The Advanced edition provides a central:

Comments Administration

panel.

Instead of changing comment settings individually on every page, DNN Administrators and Superusers configure the behaviour for the entire portal from one location.

The Advanced edition therefore has one source of configuration for:

guest commenting;
moderation;
language filtering;
comment-length limits;
rate limiting;
CAPTCHA;
moderator email notifications.

This avoids having to remember whether a particular page is using local settings or inherited settings.

Portal-wide moderation

One of the major advantages of the Advanced edition is its central moderation queue.

Pending comments and replies from Jacaranda Comments modules throughout the portal can be reviewed from the one administration panel.

Administrators can see information such as:

page title;
module title;
comment or reply status;
author or guest name;
submission date;
comment text;
private language-filter indication.

From the central queue they can:

Approve the submission;
Reject / Delete it;
View Page to open the page where the submission originated.

Moderation remains deliberately one comment at a time.

There is currently no dangerous “Approve All” or “Delete All” control.

Emergency portal-wide switches

The Advanced edition provides two particularly useful safety controls.

Disable all new posting

An administrator can temporarily prevent new comments and replies across the entire portal while leaving existing discussions visible.

This can be useful during maintenance, a spam attack, or another situation requiring immediate control.

Disable guest posting

Guest posting can also be disabled throughout the portal without preventing registered users from commenting.

This provides an immediate response if anonymous submissions begin causing moderation or spam problems.

Five-minute guest correction window

The Advanced edition adds an additional convenience for guest contributors.

A guest can correct the text of their own pending comment or reply for up to five minutes after the original submission.

This is intended for simple mistakes such as spelling errors or wording that the visitor notices immediately after posting.

There are strict limitations.

Guests can change only:

the comment or reply text.

They cannot change:

their display name;
their private email address.

The five-minute clock does not restart after an edit.

Guest editing immediately ends if:

five minutes expire;
a moderator approves the submission;
the submission is deleted;
guest posting is disabled centrally;
all posting is disabled centrally.

Most importantly, guests cannot modify an already approved public comment.

Secure guest editing

Guest editing does not rely on weak identity information such as:

name;
email address;
IP address;
browser type;
Comment ID.

Instead, the module creates a cryptographically random temporary edit credential.

Only a SHA-256 hash of that credential is stored with the comment.

The original credential is not placed in:

URLs;
query strings;
hidden form values;
comment HTML;
moderator email messages;
the database itself.

The server also verifies the portal, page, module, comment, moderation state and five-minute time limit before accepting a guest correction.

Central-only configuration

Beginning with Advanced 01.03.00, Jacaranda-specific configuration is handled entirely through Comments Administration.

Page-level module settings no longer duplicate those options.

DNN's normal module controls remain available for:

module title;
container;
visibility;
DNN permissions;
other normal DNN module properties.

This gives the Advanced edition a much clearer administration model.

Features shared by both editions

Despite their different administration models, both Jacaranda Comments editions share the same underlying commenting system.

Features include:

page-specific comments;
threaded replies;
registered-user posting;
optional guest posting;
moderation;
configurable comment-length limits;
rate limiting;
CAPTCHA;
honeypot protection;
email notifications;
private language filtering;
moderator approval and deletion;
accessible notification panels;
page-aware moderator emails;
clean post-submission redirects;
exact return positioning after published comments and replies;
parameterised SQL;
output encoding;
server-side permission checking;
anti-CSRF protection.

Both editions are intended for traditional DNN WebForms environments.

Which edition should I choose?
Choose Jacaranda Comments Simple if:
you have only a small number of comment-enabled pages;
different pages need different settings;
different pages may have different guest-comment policies;
you prefer each module to be administered independently;
you want the least complicated administration model for a small site.

The Simple edition is essentially:

Page-managed commenting.

Choose Jacaranda Comments Advanced if:
comments appear on many pages;
you want one administration location;
you want to moderate pending comments from across the portal;
you want emergency portal-wide posting controls;
you want consistent CAPTCHA, moderation and guest policies;
you do not want administrators managing separate comment settings on every page.

The Advanced edition is essentially:

Portal-managed commenting with page-specific discussions.

Why maintain two editions?

It became clear during development that adding more central administration to the original module risked making a straightforward comments module unnecessarily complicated for people who did not need those features.

Maintaining two development paths provides a cleaner solution.

The Simple edition can remain focused and easy to understand.

The Advanced edition can continue developing features for larger multi-page installations without forcing that complexity onto every Jacaranda Comments user.

This also gives administrators a genuine choice rather than assuming that every DNN website has the same requirements.

Security remains central to both versions

Allowing public and guest submissions requires careful server-side security.

Jacaranda Comments continues to use:

parameterised database operations;
output encoding to reduce stored cross-site scripting risks;
server-side permission checks;
anti-CSRF validation;
page, portal and module scope validation;
server-side moderation decisions;
posting-rate controls;
character limits;
CAPTCHA and honeypot protection.

Guest submissions cannot promote themselves to approved status by modifying browser values.

Administrative controls are also protected on the server rather than relying merely on hiding buttons from unauthorised users.

Open source under the MIT License

Jacaranda Comments is released under the MIT License.

The licence is included with the DNN installation package and displayed as part of the extension installation process.

The project is intended to remain open for use, examination, modification and community feedback.

Testing and feedback

Jacaranda Comments has been developed through incremental releases and practical testing on DNN 10 installations.

The Advanced central administration model has now also been successfully trialled following its move to central-only configuration.

As always, DNN administrators should back up both the database and website files before installing or upgrading an extension, and new releases should preferably be evaluated on a staging site or low-risk page before wider production deployment.

Feedback is particularly welcome regarding:

installation and upgrades;
different DNN 10 versions;
guest commenting;
central moderation;
the five-minute guest correction feature;
accessibility;
CAPTCHA;
spam prevention;
language filtering;
email delivery;
different DNN skins and containers;
security concerns;
feature suggestions.

Jacaranda Comments Simple 01.01.03 provides an approachable page-managed comments system.

Jacaranda Comments Advanced 01.03.00 builds on that foundation with portal-wide administration and moderation for sites that need a more centralised solution.

Both versions share the same goal: providing DNN site owners with a practical, secure and accessible way to add meaningful discussion to individual pages.

Project website: https://forrestitservices.org
