# Gmail authentication

Authentication is handled by `gog`, not by this skill.

## Diagnose first

```bash
../scripts/gog.sh auth list --check --json --no-input
../scripts/gog.sh auth doctor --check --json --no-input
```

Paths above are relative to this `references/` directory. From the skill root, use `./scripts/gog.sh`.

## Initial Google setup

The user must:

1. Create or select a Google Cloud project.
2. Enable the Gmail API in that project.
3. Configure the Google OAuth consent screen.
4. Create a Desktop OAuth client.
5. Download its client JSON.

Register that client and authorize the Gmail account:

```bash
./scripts/gog.sh auth credentials ~/Downloads/client_secret.json
./scripts/gog.sh auth add user@example.com --services gmail
```

The user completes browser consent. Then verify:

```bash
./scripts/gog.sh auth doctor --check --json --no-input
```

For a personal External OAuth app, Google's Testing status can cause refresh tokens for user-data scopes to expire after seven days. Follow the current `gog` documentation before changing publishing status or reauthorizing.

## Security

- Do not print or read client-secret contents into the conversation.
- Do not expose access tokens, refresh tokens, or keyring passwords.
- Do not commit OAuth files or gog state into the skills repository.
- In headless environments, configure the encrypted file keyring according to upstream gog documentation and ensure the agent process receives the required environment without logging secrets.
