# 🤖 Hermes Agent for Termux (proot-distro)

Run [Hermes Agent](https://github.com/NousResearch/hermes-agent) — a powerful AI agent with shell access, file editing, web browsing, and 40+ tools — directly on your Android device using Termux and proot-distro Ubuntu.

---

## ⚡ Quick Start (One-Line Install)

If you are a new user or already have `proot-distro` installed, this script will automatically handle the environment setup and Hermes installation for you.

1.  **Update Termux Packages:**
    ```bash
    pkg update && pkg upgrade -y
    ```
2.  **Run the Installer:**
    ```bash
    curl -fsSL https://raw.githubusercontent.com/catamsp/hermes-proot-termux/refs/heads/main/install-hermes-proot.sh | bash
    ```
    **installer for proot-Debian:**
    ```bash
    curl -sL https://raw.githubusercontent.com/catamsp/hermes-proot-termux/refs/heads/main/Hermes-debian.sh | bash
    ```
    **Error-testing**
     ```bash
    curl -fsSL https://raw.githubusercontent.com/catamsp/hermes-proot-termux/refs/heads/main/Error-handler.sh | bash
    ```
> **Note:** The installation takes approximately **15-20 minutes** depending on your network speed and hardware resources. Please ensure you have a stable connection.

---

## 🛠️ Key Features

-   **Full System Access:** Execute shell commands and edit files within the isolated Ubuntu environment.
-   **Messaging Integration:** Seamlessly connect with **Telegram**, **Signal**, **WhatsApp**, **Discord**, and **Slack**.
-   **Smart Installation:** The script automatically detects if `proot-distro` is already installed and configures the environment without data loss.
-   **Web & Research:** Browse the web, scrape content, and search academic papers (arXiv).
-   **Learning:** Hermes builds reusable skills and remembers your preferences across sessions.

---

## 📁 Android Storage Access

To allow Hermes to read or save files to your phone's internal storage (Downloads, DCIM, etc.), follow these steps:

1.  **Grant Permission in Termux:**
    ```bash
    termux-setup-storage
    ```
2.  **Access Paths:**
    Inside the Hermes (Ubuntu) environment, your shared storage is mapped to:
    `/data/data/com.termux/files/home/storage/`

*Example: Accessing a file in your Downloads folder:*
`cat /data/data/com.termux/files/home/storage/downloads/my_file.txt`

---

## 🚀 Usage & Configuration

Once installed, start the agent with:
```bash
hermes
```

### 💰 Free Usage & Model Setup
To use Hermes for free, you can configure it with **Kilo API**:
1.  Run `hermes setup`.
2.  Add your **Kilo API** key.
3.  Select a **Hermes model** to enjoy powerful agentic capabilities at no cost.

### ⚙️ Useful Commands
-   `hermes setup` - Configure API providers and keys.
-   `hermes model` - Switch between different AI models.
-   `hermes update` - Keep your agent updated with the latest tools.
-   `hermes doctor` - Troubleshoot environment issues.

---

## ⚠️ Requirements
-   **Termux:** Must be the version from [F-Droid](https://f-droid.org/en/packages/com.termux/) (Google Play version is outdated).
-   **Android:** 7.0 or higher.
-   **Storage:** Approximately 2GB of free space.

---

## 🤝 Credits & Resources
-   **Original Repo:** [catamsp/hermes-proot-termux](https://github.com/catamsp/hermes-proot-termux)
-   **Core Project:** [Nous Research Hermes Agent](https://github.com/NousResearch/hermes-agent)

*This documentation is refined for clarity and ease of use.*
