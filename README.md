# 💬🌸 Cohere CLI: Seamlessly interact with Cohere's AI directly from your terminal!
![ascii-art-6_upscayl_4x_upscayl-standard-4x](https://github.com/user-attachments/assets/b848c8dd-0a15-478b-baed-036a3aae2e7d)

**Cohere CLI** is a powerful and user-friendly command-line interface that allows seamless interaction with Cohere's AI models directly from your terminal. Whether you're looking to engage in multi-turn conversations, perform single-turn web searches, or upload files for analysis, **Cohere CLI** has you covered.

## 🚀 Features

- **Multi-Turn Chat:** Engage in extended conversations with Cohere's Command R+ model, maintaining context across multiple interactions.
- **Single-Turn Web Search:** Use the `:w <query>` command to perform quick web searches directly from the terminal.
- **File Upload:** Upload PDF or TXT files (up to 20MB) with the `:u <file>` command for the AI to analyze.
- **Clear Screen:** Use the `:c` command to refresh your terminal display without losing your conversation history.
- **Debug Mode:** Toggle debug mode with `:d` to see detailed information about API requests and responses.
- **Persistent Memory:** Conversations are saved locally, allowing the chat to "remember" context across different sessions.
- **Context Injection:** Optionally inject real-time context such as your current location and local time/date into the AI's system message.
- **Onboarding Process:** An interactive setup that guides you through configuring preferences and API key.
- **Citation Support:** Automatically formats and displays citations from web search results.
- **Dynamic Terminal Resizing:** Automatically adjusts the chat interface based on your terminal's size for a consistent experience.

## 📦 Installation

### Prerequisites

Before installing **Cohere CLI**, ensure that the following dependencies are installed on your system:

- [`curl`](https://curl.se/) - For making API requests and downloading the installer
- [`jq`](https://stedolan.github.io/jq/) - For parsing JSON responses
- [`gum`](https://github.com/charmbracelet/gum) - For interactive prompts and UI elements
- [`pdftotext`](https://poppler.freedesktop.org/) - Optional, required only for PDF file uploads

The installation script will attempt to install these dependencies if they're missing.

### Installation Steps

1. **Download and Run the Installation Script**

   You can install **Cohere CLI** by running the following command in your terminal:

   ```bash
   curl -sL https://raw.githubusercontent.com/plyght/cohere-cli/main/install.sh | bash
   ```

   This will install the script to `/usr/local/bin/cohere`, making it available as a system-wide command.

2. **Manual Installation (Alternative)**

   If you prefer, you can manually download the script and make it executable:

   ```bash
   curl -sL https://raw.githubusercontent.com/plyght/cohere-cli/main/cohere.sh -o cohere.sh
   chmod +x cohere.sh
   sudo mv cohere.sh /usr/local/bin/cohere
   ```

## 🔧 Usage

Once installed, simply type `cohere` in your terminal to start a conversation. The following commands are available:

- **Regular input:** Type any message to engage in a multi-turn conversation with Command R+
- **`:w <query>`:** Perform a single-turn web search (e.g., `:w what is the capital of France?`)
- **`:u <file>`:** Upload a PDF or TXT file (up to 20MB) for analysis (e.g., `:u ~/Documents/report.pdf`)
- **`:c`:** Clear the screen without losing conversation history
- **`:d`:** Toggle debug mode to see detailed information about API requests/responses
- **`:q`:** Quit the CLI

## ⚙️ Configuration

Upon first run, the CLI will guide you through an onboarding process to:

1. Enter your Cohere API key
2. Choose whether to enable location injection
3. Choose whether to enable time/date injection
4. Choose whether to enable debug mode

These settings are stored in `~/.config/cohere-cli/config.env` and can be edited manually if needed.

Conversation history is stored in `~/.config/cohere-cli/chat-memory.json` and is maintained between sessions.

## 🔒 Security

- Your Cohere API key is stored locally in `~/.config/cohere-cli/config.env` with appropriate file permissions (600)
- Configuration directory permissions are set to 700 for enhanced security
- No data is sent to third parties other than to Cohere's API and ipinfo.io (if location injection is enabled)
- File uploads are processed locally and only a snippet (first 2000 characters) is sent to Cohere's API

## 🧩 Technical Details

- Uses Cohere's Command R+ model
- Conversations are maintained using the chat history API
- Web searches utilize Cohere's built-in web connector
- Terminal UI is built with [gum](https://github.com/charmbracelet/gum) for a clean, interactive experience
- JSON processing is handled by [jq](https://stedolan.github.io/jq/)
- PDF extraction is done with [pdftotext](https://poppler.freedesktop.org/) (part of Poppler utilities)

## 📜 License

See LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.