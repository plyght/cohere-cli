#!/usr/bin/env bash
#
# cohere.sh
#
# Single-mode Chat with Command R+:
#   - Normal user messages => multi-turn chat
#   - :w <query>           => single-turn web search
#   - :u <file>            => upload .pdf or .txt (<= 20MB)
#   - :c                   => clear the screen
#   - :q                   => quit
#
# Styled with Cohere-inspired border colors for user (pink) and AI (purple).
# Optionally injects location and current time/date into the system message.
# Settings and API key are stored in ~/.config/cohere-tools.env
# Conversation memory in ~/.config/cohere-chat-memory.json
#
# Sources (factual references):
#   - https://docs.cohere.com/ (Cohere API documentation)
#   - https://ipinfo.io (Location fetch)
#   - https://github.com/charmbracelet/gum (gum utility usage)
#   - https://poppler.freedesktop.org/ (pdftotext utility)
#   - https://linux.die.net/man/1/sed (sed usage)
#

set -euo pipefail

# CLI Version
CLI_VERSION="1.0.0"

###############################################################################
# 0) Basic paths and config
###############################################################################
CONFIG_DIR="$HOME/.config/cohere-cli"
CONFIG_FILE="$CONFIG_DIR/config.env"
MEMORY_FILE="$CONFIG_DIR/chat-memory.json"
DEBUG_DIR="$CONFIG_DIR/debug"

# Create config directories with correct permissions
mkdir -p "$CONFIG_DIR" "$DEBUG_DIR"
chmod 700 "$CONFIG_DIR" "$DEBUG_DIR" || true

###############################################################################
# 1) Onboarding: Load/ask for config
###############################################################################
# [analysis] This function writes or replaces a given var=value in CONFIG_FILE.
set_config_var() {
  local var="$1"
  local val="$2"
  # If var already in config, replace it; else append
  if grep -q "^export $var=" "$CONFIG_FILE" 2>/dev/null; then
    sed -i "s|^export $var=.*|export $var=\"$val\"|g" "$CONFIG_FILE"
  else
    echo "export $var=\"$val\"" >> "$CONFIG_FILE"
  fi
}

# 1a) Load existing config if it exists
if [ -f "$CONFIG_FILE" ]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

# 1b) Check for Cohere API Key
if [ -z "${COHERE_API_KEY:-}" ]; then
  # Ask user for the key
  COHERE_API_KEY="$(gum input --placeholder "Enter your Cohere API key" --password)"
  mkdir -p "$CONFIG_DIR"
  echo "# Stored by cohere.sh" > "$CONFIG_FILE"
  echo "export COHERE_API_KEY=\"$COHERE_API_KEY\"" >> "$CONFIG_FILE"
  chmod 600 "$CONFIG_FILE"
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

# 1c) Ask for location injection preference if not set
if [ -z "${COHERE_INJECT_LOCATION:-}" ]; then
  gum style --foreground "#FFA500" "Would you like to enable location injection?"
  if gum confirm; then
    set_config_var "COHERE_INJECT_LOCATION" "true"
  else
    set_config_var "COHERE_INJECT_LOCATION" "false"
  fi
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

# 1d) Ask for time/date injection preference if not set
if [ -z "${COHERE_INJECT_TIME:-}" ]; then
  gum style --foreground "#FFA500" "Would you like to enable time/date injection?"
  if gum confirm; then
    set_config_var "COHERE_INJECT_TIME" "true"
  else
    set_config_var "COHERE_INJECT_TIME" "false"
  fi
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

# 1e) Ask for debug mode preference if not set
if [ -z "${COHERE_DEBUG_MODE:-}" ]; then
  gum style --foreground "#FFA500" "Would you like to enable debug output?"
  if gum confirm; then
    set_config_var "COHERE_DEBUG_MODE" "true"
  else
    set_config_var "COHERE_DEBUG_MODE" "false"
  fi
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

###############################################################################
# 2) Basic definitions and color styling
###############################################################################
MODEL="command-r-plus"

# Cohere-inspired colors
COHERE_PINK="#FFC8DD"     # Used for user message borders
COHERE_PURPLE="#D8B4FE"   # Used for assistant message borders
COHERE_ACCENT="#A78BFA"   # Used for border colors in other styled boxes

###############################################################################
# 3) Prepare conversation memory
###############################################################################
# Init or validate conversation memory
init_conversation() {
  # Initial conversation history - empty at start
  CONVERSATION='[]'
  
  # Write fresh conversation to memory file
  echo "$CONVERSATION" > "$MEMORY_FILE"
  chmod 600 "$MEMORY_FILE" || true
  
  # Set the system message separately
  SYSTEM_MESSAGE="You are an AI assistant powered by Command R+."
}

# Initialize the system message
SYSTEM_MESSAGE="You are an AI assistant powered by Command R+."

# For this version, let's always start with a clean conversation
# to ensure we're using the right role format
if [ "${COHERE_DEBUG_MODE:-}" = "true" ]; then
  gum style --foreground "#FFA500" "Starting with fresh conversation history."
fi
rm -f "$MEMORY_FILE" 2>/dev/null || true
init_conversation

###############################################################################
# 4) Helpers
###############################################################################
# 4a) get_location
# [analysis] This attempts to fetch city from ipinfo; fallback if offline.
get_location() {
  local city
  city="$(curl -s ipinfo.io/city || echo "Unknown")"
  city="$(echo "$city" | tr -d '\r' | tr -d '\n')"
  [ -z "$city" ] && city="Unknown"
  echo "$city"
}

# 4b) update_system_message: includes location/time if user allowed
update_system_message() {
  local city="(location disabled)"
  local now="(time/date disabled)"

  if [ "${COHERE_INJECT_LOCATION:-}" = "true" ]; then
    city="$(get_location)"
  fi

  if [ "${COHERE_INJECT_TIME:-}" = "true" ]; then
    now="$(date)"  # e.g. "Mon Jan  1 12:34:56 PM EST 2025"
  fi

  # Update the system message
  SYSTEM_MESSAGE="You are an AI assistant powered by Command R+."
  SYSTEM_MESSAGE+="\n\nLocation: $city"
  SYSTEM_MESSAGE+="\nLocal time/date: $now"
  SYSTEM_MESSAGE+="\nUse this context as needed to inform your answers."
}

# 4c) get_box_width
# [analysis] Tries to keep the display nicely at ~80 columns or the terminal width.
get_box_width() {
  local cols max_box_width
  cols=$(tput cols)

  max_box_width=80
  if [ "$cols" -lt "$max_box_width" ]; then
    max_box_width=$cols
  fi

  if [ "$max_box_width" -lt 60 ]; then
    gum style \
      --border normal --padding "1 2" \
      --border-foreground "$COHERE_ACCENT" \
      --background "#FFCCCC" \
      "Warning: Your terminal window is too small. Please resize to at least 60 columns for optimal display."
    exit 1
  fi

  echo "$max_box_width"
}

# 4d) format_citations
# [analysis] For any citations in the JSON response, format them nicely at the end.
format_citations() {
  local json="$1"
  local formatted=""
  
  # Check if json is empty or invalid
  if [ -z "$json" ] || ! echo "$json" | jq -e '.' >/dev/null 2>&1; then
    return
  fi
  
  # Try to extract citations using different possible formats
  local has_citations=false
  local CITATIONS=""
  
  # Try modern v2 format
  if echo "$json" | jq -e 'has("message") and (.message | has("citations"))' >/dev/null 2>&1; then
    CITATIONS="$(echo "$json" | jq -c '.message.citations // []')"
    has_citations=true
  # Try v1 format
  elif echo "$json" | jq -e 'has("citations")' >/dev/null 2>&1; then
    CITATIONS="$(echo "$json" | jq -c '.citations // []')"
    has_citations=true
  # Try other known formats
  elif echo "$json" | jq -e 'has("documents") or has("web_search")' >/dev/null 2>&1; then
    CITATIONS="$(echo "$json" | jq -c '.documents // .web_search // []')"
    has_citations=true
  fi
  
  if [ "$has_citations" = "true" ] && [ -n "$CITATIONS" ]; then
    local NUM
    NUM="$(echo "$CITATIONS" | jq 'length' 2>/dev/null || echo 0)"
    
    if [ "$NUM" -gt 0 ]; then
      formatted+="\n--\nCitations:"
      for i in $(seq 0 $((NUM-1))); do
        local source_text source_url title
        
        # Try different citation formats
        source_text="$(echo "$CITATIONS" | jq -r ".[$i].text // .[$i].snippet // .[$i].title // \"(no text)\"" 2>/dev/null)"
        source_url="$(echo "$CITATIONS" | jq -r ".[$i].url // .[$i].link // .[$i].source // \"\"" 2>/dev/null)"
        title="$(echo "$CITATIONS" | jq -r ".[$i].title // \"\"" 2>/dev/null)"
        
        if [ -n "$source_url" ] && [ "$source_url" != "null" ]; then
          if [ -n "$title" ] && [ "$title" != "null" ]; then
            formatted+="\n[$((i+1))] '$title': $source_url"
          else
            formatted+="\n[$((i+1))] $source_text → $source_url"
          fi
        else
          formatted+="\n[$((i+1))] $source_text"
        fi
      done
    fi
  fi

  echo -e "$formatted"
}

# 4e) parse_cohere_response_blocks
# [analysis] Some replies come as multiple blocks: text, code, system, etc.
parse_cohere_response_blocks() {
  local json="$1"
  
  # First check if this is an error response
  if echo "$json" | jq -e 'has("message") and (.message | type == "string")' >/dev/null 2>&1; then
    echo "API Error: $(echo "$json" | jq -r '.message')"
    return
  fi
  
  # Then try to parse the content
  local result
  result=$(jq -r '
    if has("message") and (.message | has("content")) then
      .message.content | 
      if type == "array" then
        map(
          if .type == "code" then
            "```" + (.text // "") + "\n```"
          elif .type == "thinking" then
            "[thinking block] " + (.text // "")
          elif .type == "system" then
            "[system block] " + (.text // "")
          else
            (.text // "")
          end
        ) | join("\n\n")
      else
        .
      end
    elif has("text") then
      .text
    elif has("reply") then
      .reply
    elif has("response") then
      .response
    else
      "Unable to parse API response"
    end
  ' <<< "$json" 2>/dev/null || echo "Error parsing JSON response")
  
  echo "$result"
}

# 4f) handle_upload
# [analysis] For the :u <filename> command, check if PDF or TXT, up to 20 MB, then store snippet in memory.
handle_upload() {
  local filepath="$1"
  if [ ! -f "$filepath" ]; then
    gum style --foreground "#FF0000" "File not found: $filepath"
    return
  fi

  local ext="${filepath##*.}"
  if [[ "$ext" != "pdf" && "$ext" != "txt" ]]; then
    gum style --foreground "#FF0000" "Only .pdf or .txt files are allowed."
    return
  fi

  local size
  size=$(wc -c < "$filepath")
  if [ "$size" -gt $((20 * 1024 * 1024)) ]; then
    gum style --foreground "#FF0000" "File exceeds 20 MB limit."
    return
  fi

  local file_text=""
  if [ "$ext" = "pdf" ]; then
    if ! command -v pdftotext >/dev/null 2>&1; then
      gum style --foreground "#FF0000" "Error: pdftotext not installed. Install poppler or equivalent."
      return
    fi
    file_text="$(pdftotext "$filepath" - 2>/dev/null || true)"
  else
    file_text="$(cat "$filepath" 2>/dev/null || true)"
  fi

  if [ -z "$file_text" ]; then
    gum style --foreground "#FFA500" "Warning: No text extracted from $filepath."
  fi

  # We store only a snippet (first ~2000 chars) to avoid massive memory usage.
  local snippet
  snippet="$(echo "$file_text" | head -c 2000)"
  if [ "${#file_text}" -gt 2000 ]; then
    snippet+="\n[...truncated due to size...]"
  fi

  # We append this to the system message instead
  FILE_CONTEXT="\n\nFile Uploaded: $filepath\nSnippet:\n$snippet"
  SYSTEM_MESSAGE+="$FILE_CONTEXT"
  
  # Also add a message to the conversation history
  CONVERSATION="$(
    echo "$CONVERSATION" \
    | jq --arg content "I've uploaded the file: $filepath" '. + [{"role":"User","content": $content}]'
  )"
  echo "$CONVERSATION" > "$MEMORY_FILE"

  gum style \
    --border normal --padding "0 1" \
    --border-foreground "$COHERE_ACCENT" \
    "File $filepath uploaded. Snippet stored in conversation memory."
}

###############################################################################
# 5) Display welcome box
###############################################################################
box_width=$(get_box_width)
gum style \
  --border normal --padding "1 2" \
  --border-foreground "$COHERE_ACCENT" \
  --width "$box_width" \
  "Welcome to Command R+ Chat! (v$CLI_VERSION)

Commands:
- :w <query>   => single-turn web search
- :u <file>    => upload .pdf or .txt (<= 20MB)
- :c           => clear the screen
- :d           => toggle debug mode
- :q           => quit

Type anything else for normal multi-turn conversation."

###############################################################################
# 6) Main loop
###############################################################################
while true; do
  # update system context before each user input
  update_system_message
  box_width=$(get_box_width)

  USER_INPUT="$(gum input --placeholder "Your message (or :w <query>, :u <file>, :c, :d, :q)..." --width "$box_width")"

  # Handle empty input or quit
  if [ -z "$USER_INPUT" ] || [ "$USER_INPUT" = ":q" ]; then
    gum style \
      --foreground "#FF0000" \
      --width "$box_width" \
      "Goodbye!"
    exit 0
  fi

  # Handle :c command (clear the screen)
  if [ "$USER_INPUT" = ":c" ]; then
    clear
    continue
  fi
  
  # Handle :d command (toggle debug mode)
  if [ "$USER_INPUT" = ":d" ]; then
    if [ "${COHERE_DEBUG_MODE:-}" = "true" ]; then
      set_config_var "COHERE_DEBUG_MODE" "false"
      gum style --foreground "#FFA500" "Debug mode turned OFF"
    else
      set_config_var "COHERE_DEBUG_MODE" "true"
      gum style --foreground "#FFA500" "Debug mode turned ON"
    fi
    # Re-source the config to get the updated value
    source "$CONFIG_FILE"
    continue
  fi

  # Print user input
  gum style \
    --border normal --padding "0 1" \
    --border-foreground "$COHERE_PINK" \
    --width "$box_width" \
    "You: $USER_INPUT"

  # Single-turn web search with :w
  if [[ "$USER_INPUT" =~ ^:w[[:space:]]+(.*) ]]; then
    SEARCH_QUERY="${BASH_REMATCH[1]}"
    RESPONSE="$(
      gum spin --spinner dot --title "$MODEL is thinking (web search)..." -- \
        curl -s -X POST "https://api.cohere.ai/v1/chat" \
          -H "Authorization: Bearer $COHERE_API_KEY" \
          -H "Content-Type: application/json" \
          -d "{
            \"model\": \"$MODEL\",
            \"message\": \"$SEARCH_QUERY\",
            \"preamble\": \"$SYSTEM_MESSAGE\",
            \"connectors\": [{\"id\": \"web-search\"}]
          }"
    )"
    
    ASSISTANT_CONTENT="$(parse_cohere_response_blocks "$RESPONSE")"
    
    if [ -z "$ASSISTANT_CONTENT" ]; then
      gum style \
        --border normal --padding "0 1" \
        --border-foreground "$COHERE_ACCENT" \
        --width "$box_width" \
        "Assistant (web): No text returned.\nRaw response: $(echo "$RESPONSE" | jq -c '.')"
    else
      FULL_RESPONSE="Assistant (web): $ASSISTANT_CONTENT$(format_citations "$RESPONSE")"
      gum style \
        --border normal --padding "0 1" \
        --border-foreground "$COHERE_PURPLE" \
        --width "$box_width" \
        "$FULL_RESPONSE"
    fi

  # Upload file with :u
  elif [[ "$USER_INPUT" =~ ^:u[[:space:]]+(.+) ]]; then
    FILE_PATH="${BASH_REMATCH[1]}"
    handle_upload "$FILE_PATH"

  else
    # Multi-turn chat with Command R+
    # Add user message to conversation history
    CONVERSATION="$(
      echo "$CONVERSATION" \
      | jq --arg content "$USER_INPUT" '. + [{"role":"User","content": $content}]'
    )"
    
    # Save conversation to file
    echo "$CONVERSATION" > "$MEMORY_FILE"
    
    # Create a clean chat history (skip the current user message)
    CHAT_HISTORY=$(echo "$CONVERSATION" | jq 'map(select(.content != "'"$USER_INPUT"'"))')
    
    # Prepare the request
    REQUEST="{
        \"model\": \"$MODEL\",
        \"message\": \"$USER_INPUT\",
        \"chat_history\": $CHAT_HISTORY,
        \"preamble\": \"$SYSTEM_MESSAGE\"
    }"
    
    # Debug info if enabled
    if [ "${COHERE_DEBUG_MODE:-}" = "true" ]; then
      NUM_MESSAGES=$(echo "$CONVERSATION" | jq '. | length')
      HISTORY_SAMPLE=$(echo "$CONVERSATION" | jq -c '.')
      gum style --foreground "#FFA500" "Sending request with $NUM_MESSAGES message(s) in history"
      gum style --foreground "#FFA500" "Sample: $HISTORY_SAMPLE"
      
      # Write the request to a debug file
      echo "$REQUEST" > "$DEBUG_DIR/last-request.json"
      gum style --foreground "#FFA500" "Request saved to $DEBUG_DIR/last-request.json"
    fi
    
    # Make the API call using v1 endpoint with chat_history
    RESPONSE="$(
      gum spin --spinner dot --title "$MODEL is thinking..." -- \
        curl -s "https://api.cohere.ai/v1/chat" \
          -H "Authorization: Bearer $COHERE_API_KEY" \
          -H "Content-Type: application/json" \
          -d "$REQUEST"
    )"

    ASSISTANT_CONTENT="$(parse_cohere_response_blocks "$RESPONSE")"

    if [ -n "$ASSISTANT_CONTENT" ]; then
      FULL_RESPONSE="Assistant (Command R+): $ASSISTANT_CONTENT$(format_citations "$RESPONSE")"

      gum style \
        --border normal --padding "0 1" \
        --border-foreground "$COHERE_PURPLE" \
        --width "$box_width" \
        "$FULL_RESPONSE"

      # Add to conversation memory
      CONVERSATION="$(
        echo "$CONVERSATION" \
        | jq --arg c "$ASSISTANT_CONTENT" '. + [{"role":"Chatbot","content": $c}]'
      )"
      echo "$CONVERSATION" > "$MEMORY_FILE"
    else
      # Display raw response for debugging
      RAW_RESPONSE=$(echo "$RESPONSE" | jq -c '.')
      ERROR_MESSAGE="No content found from assistant"
      
      if [ "${COHERE_DEBUG_MODE:-}" = "true" ]; then
        ERROR_MESSAGE="$ERROR_MESSAGE. Raw response: $RAW_RESPONSE"
        
        # Write the raw response to a debug file
        echo "$RAW_RESPONSE" > "$DEBUG_DIR/last-error.json"
        gum style --foreground "#FFA500" "Debug info saved to $DEBUG_DIR/last-error.json"
      fi
      
      gum style \
        --border normal --padding "0 1" \
        --border-foreground "$COHERE_ACCENT" \
        --width "$box_width" \
        "$ERROR_MESSAGE"
    fi
  fi
done
