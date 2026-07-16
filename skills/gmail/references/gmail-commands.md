# Gmail command workflows

Use these examples from the Gmail skill directory. Replace IDs, paths, accounts, and recipients with verified values.

## Search

```bash
./scripts/gog.sh --account user@example.com --readonly --gmail-no-send --no-input \
  --wrap-untrusted gmail search \
  'from:alice@example.com has:attachment newer_than:30d' --max 20 --json
```

Gmail's native search grammar is accepted.

## Read

```bash
./scripts/gog.sh --account user@example.com --readonly --gmail-no-send --no-input \
  --wrap-untrusted gmail get MESSAGE_ID --sanitize-content --json

./scripts/gog.sh --account user@example.com --readonly --gmail-no-send --no-input \
  --wrap-untrusted gmail thread get THREAD_ID --sanitize-content --full --json
```

Only omit `--sanitize-content` when the user explicitly needs raw details.

## Attachments

Inspect names and sizes first:

```bash
./scripts/gog.sh --account user@example.com --readonly --gmail-no-send --no-input \
  --wrap-untrusted gmail thread attachments THREAD_ID --json
```

Download into a unique directory:

```bash
attachment_dir="$(mktemp -d "${TMPDIR:-/tmp}/gmail-attachments.XXXXXX")"
./scripts/gog.sh --account user@example.com --readonly --gmail-no-send --no-input \
  gmail thread attachments THREAD_ID --download --out-dir "$attachment_dir"
```

Report saved paths. Do not execute or automatically open downloaded content. Remove only task-specific temporary directories created by the current workflow.

A single known attachment can be downloaded with:

```bash
./scripts/gog.sh --account user@example.com --readonly --gmail-no-send --no-input \
  gmail attachment MESSAGE_ID ATTACHMENT_ID --out "$attachment_dir"
```

## Create a draft

```bash
body_file="$(mktemp "${TMPDIR:-/tmp}/gmail-body.XXXXXX.txt")"
printf '%s\n' 'Draft body here.' > "$body_file"

./scripts/gog.sh --account user@example.com --gmail-no-send --no-input \
  gmail drafts create \
  --to recipient@example.com \
  --subject 'Subject' \
  --body-file "$body_file" \
  --json
```

## Draft with attachments

```bash
./scripts/gog.sh --account user@example.com --gmail-no-send --no-input \
  gmail drafts create \
  --to recipient@example.com \
  --subject 'Monthly report' \
  --body-file "$body_file" \
  --attach ./report.pdf \
  --attach ./summary.csv \
  --json
```

The JSON result includes resulting attachment names and sizes.

## Update a draft

```bash
./scripts/gog.sh --account user@example.com --gmail-no-send --no-input \
  gmail drafts update DRAFT_ID \
  --to recipient@example.com \
  --subject 'Revised subject' \
  --body-file "$body_file" \
  --json
```

Omitting `--attach` preserves current attachments. Passing one or more `--attach` values replaces them. Use `--clear-attachments` only when explicitly requested.

## Draft a reply

Do not use the immediate-send `gmail reply` commands. Create a reply draft:

```bash
./scripts/gog.sh --account user@example.com --gmail-no-send --no-input \
  gmail drafts create \
  --reply-to-message-id MESSAGE_ID \
  --body-file "$body_file" \
  --quote \
  --json
```

For reply-all recipient derivation, inspect current `gog schema gmail drafts create --json` and carefully review all resulting recipients before confirmation.

## Discover current syntax

```bash
./scripts/gog.sh schema gmail --json
./scripts/gog.sh schema gmail drafts create --json
./scripts/gog.sh gmail thread attachments --help
```
