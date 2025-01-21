# 💬🤖 Cohere CLI: Seamlessly interact with Cohere's AI directly from your terminal! 🚀✨

**Cohere CLI** is a powerful and user-friendly command-line interface that allows seamless interaction with Cohere's AI models directly from your terminal. Whether you're looking to engage in multi-turn conversations, perform single-turn web searches, or utilize dynamic content injection based on your preferences, **Cohere CLI** has you covered.

## 🚀 Features

- **Multi-Turn Chat:** Engage in extended conversations with Cohere's AI assistant, maintaining context across multiple interactions.
- **Single-Turn Web Search:** Utilize the `/web <query>` command to perform quick web searches directly from the terminal.
- **Clear Screen:** Use the `/clear` command to refresh your terminal display without losing your conversation history.
- **Persistent Memory:** Conversations are saved locally, allowing the chat to "remember" context across different sessions.
- **Content Injection:** Optionally inject real-time context such as your current location and local time/date into the AI's responses.
- **Onboarding Process:** An interactive setup that guides you through configuring preferences like location and time/date injection.
- **Customizable Configuration:** All settings, including API keys and preferences, are stored in a single config file for easy management.
- **Dynamic Terminal Resizing:** Automatically adjusts the chat interface based on your terminal's size to ensure a consistent and glitch-free experience.

## 📦 Installation

### Prerequisites

Before installing **Cohere CLI**, ensure that the following dependencies are installed on your system:

- [`curl`](https://curl.se/)
- [`jq`](https://stedolan.github.io/jq/)
- [`gum`](https://github.com/charmbracelet/gum) (for interactive prompts)

### Installation Steps

1. **Download and Run the Installation Script**

   You can install **Cohere CLI** by running the following command in your terminal:

   ```bash
   curl -sL https://www.peril.lol/cohere/install.sh | bash
