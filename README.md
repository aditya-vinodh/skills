# Aditya's Agent Skills

## Install

```bash
git clone https://github.com/aditya-vinodh/skills.git
cd skills
./install.sh
```

Skills are copied to `~/.agents/skills/`, where compatible clients can share them.

```bash
./install.sh --list          # list available skills
./install.sh gmail           # install one skill
./install.sh --link gmail    # symlink for local development
./install.sh --dry-run       # preview
```

The installer does not use `sudo` or overwrite unowned skill directories unless `--force` is supplied.

## Skills

- **gmail** — Search and read Gmail, download attachments, create drafts, and send only after explicit confirmation. Powered by [`gog`](https://github.com/openclaw/gogcli).

## Uninstall

```bash
./uninstall.sh gmail
./uninstall.sh --all
```
