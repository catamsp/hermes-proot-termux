# Hermes Agent on Termux (proot-distro)

Run [Hermes Agent](https://github.com/NousResearch/hermes-agent) — a full AI agent with shell access, file editing, web browsing, and 40+ tools — right on your Android phone using Termux and proot-distro Ubuntu.

## What is Hermes?

Hermes is an open-source AI agent built by [Nous Research](https://nousresearch.com). Unlike a simple chatbot, Hermes can:

- Execute shell commands and edit files
- Browse the web and scrape content
- Search academic papers (arXiv), manage GitHub repos
- Send emails, create documents, manage Notion/Linear
- Schedule cron jobs and delegate tasks to subagents
- Learn from experience — it builds reusable skills and remembers your preferences across sessions
- Connect to Telegram, Discord, WhatsApp, Slack, and more

It runs inside a proot-distro Ubuntu container on Termux, giving it a full Linux environment without root access.

## One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/catamsp/hermes-proot-termux/refs/heads/main/install-hermes-proot.sh | bash
```

## What the Script Does

1. Installs Termux dependencies (proot-distro, git, curl)
2. Sets up Ubuntu inside proot-distro
3. Installs system packages (Python, Node.js, build tools)
4. Runs the official Hermes installer
5. Creates a `hermes` launcher command
6. Launches the setup wizard to configure your API provider

## Requirements

- [Termux](https://f-droid.org/en/packages/com.termux/) (F-Droid version, NOT Play Store)
- Android 7.0+
- ~2GB free storage
- Internet connection
- An API key from one of the supported providers (OpenRouter, OpenAI, Anthropic, etc.)

## After Installation

Just type:

```bash
hermes
```

Or run the setup wizard to change your provider/model:

```bash
hermes setup
```

## Android Shared Storage Access

Hermes runs inside the proot-distro Ubuntu container, but you can access your phone's shared storage (Downloads, DCIM, Pictures, etc.) through Termux storage bindings.

### Setup

First, grant Termux storage access:

```bash
termux-setup-storage
```

This creates symlinks inside the proot container at:

```
~/storage/
├── downloads    -> /storage/emulated/0/Download
├── dcim         -> /storage/emulated/0/DCIM
├── pictures     -> /storage/emulated/0/Pictures
├── movies       -> /storage/emulated/0/Movies
├── music        -> /storage/emulated/0/Music
└── shared       -> /storage/emulated/0
```

### From Inside Hermes (proot Ubuntu)

Access your phone's Downloads:

```bash
cat /data/data/com.termux/files/home/storage/downloads/myfile.txt
```

Copy a file from Hermes to your phone's Downloads:

```bash
cp output.pdf /data/data/com.termux/files/home/storage/downloads/
```

List photos from DCIM:

```bash
ls /data/data/com.termux/files/home/storage/dcim/
```

### From Termux Directly

```bash
# List Downloads
ls ~/storage/downloads/

# Copy a file to Downloads
cp myfile.txt ~/storage/downloads/

# Read a file from your phone
cat ~/storage/shared/Documents/notes.txt
```

### Inside Hermes Chat

You can ask Hermes to work with your phone's storage directly:

```
"Read the file at /data/data/com.termux/files/home/storage/downloads/data.csv"
"Save the report to /data/data/com.termux/files/home/storage/shared/Documents/"
"List all photos in /data/data/com.termux/files/home/storage/dcim/"
```

## Useful Commands

```bash
hermes                  # Start interactive chat
hermes setup            # Configure provider and API key
hermes model            # Change model
hermes doctor           # Check for issues
hermes update           # Update to latest version
hermes status           # Show component status
```

## Troubleshooting

**Storage access not working?**
```bash
termux-setup-storage
```
Make sure to grant the permission when prompted. Then restart Termux.

**Hermes command not found?**
```bash
source ~/.bashrc
```
Or enter the proot manually:
```bash
proot-distro login ubuntu
hermes
```

**Out of memory?**
Close other apps. Hermes with large models needs RAM. Try a smaller model with `hermes model`.

**Permission denied errors?**
Make sure you installed Termux from F-Droid, not Play Store. The Play Store version is outdated and broken.

## Credits

- [Hermes Agent](https://github.com/NousResearch/hermes-agent) by Nous Research
- [Termux](https://termux.dev/)
- [proot-distro](https://github.com/nicehash/proot-distributed)

## License

This installer script is provided as-is. Hermes Agent is licensed under [MIT](https://github.com/NousResearch/hermes-agent/blob/main/LICENSE).
