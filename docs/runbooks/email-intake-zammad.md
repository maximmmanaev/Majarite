# Runbook — Zammad Email Intake

## Purpose

Настроить прием email в Zammad для Majarite MVP.

## Result

Письмо должно создавать или обновлять ticket в Zammad.

## Required data

- support mailbox address
- IMAP host
- IMAP port
- SMTP host
- SMTP port
- mailbox login
- mailbox password or app password

## Security rule

Real mailbox credentials must not be committed to Git.

## Setup steps

1. Open Zammad admin UI.
2. Go to Channels.
3. Open Email.
4. Add support mailbox.
5. Configure inbound email.
6. Configure outbound email if needed.
7. Send test email.
8. Confirm ticket created in Zammad.
9. Configure webhook according to docs/runbooks/zammad-email-webhook.md.

## Acceptance

- test email creates Zammad ticket
- ticket has sender
- ticket has subject
- ticket has article body
- attachments are preserved by Zammad
