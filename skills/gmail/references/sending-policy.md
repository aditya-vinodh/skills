# Confirmation-required sending policy

## Prohibited direct-send workflow

Do not use these for normal agent email work because they send immediately:

```text
gog gmail send
gog gmail reply
gog gmail reply-all
gog gmail forward
```

Create a Gmail draft instead.

## Required workflow

1. Create or update the draft while passing `--gmail-no-send`.
2. Fetch the draft with sending still blocked:

   ```bash
   ./scripts/gog.sh --account user@example.com --gmail-no-send --no-input \
     --wrap-untrusted gmail drafts get DRAFT_ID --json
   ```

3. Present a review containing:
   - authenticated sending account
   - From address
   - To, CC, and BCC recipients
   - subject
   - complete body, unless the user explicitly accepts a clearly marked preview
   - attachment filenames and byte sizes
4. Ask: **“Send this exact draft now?”**
5. Wait for an explicit affirmative response to that question. Approval to compose, edit, or attach files is not send approval. Do not infer approval from earlier or vague statements.
6. Fetch the same draft again immediately before sending and compare all reviewed fields. If anything changed, display the new draft and ask again.
7. Send once:

   ```bash
   ./scripts/gog.sh --account user@example.com --no-input \
     gmail drafts send DRAFT_ID --json
   ```

8. Report the returned message/thread identifiers. Do not retry an ambiguous send failure until checking whether Gmail accepted it, to avoid duplicates.

Only the final `drafts send` command may omit `--gmail-no-send`. Confirmation is valid for one exact draft and one send only.

## Limits of this control

This is a behavioral safety policy. An agent with unrestricted Bash access can technically bypass it. Strong cryptographic proof of human approval would require a separate approval-token wrapper or an external confirmation service.
