#!/bin/bash
set -e

# === Main progress bar ===
print_main_progress() {
    local step=$1
    local total_steps=6
    local progress=$(( (step * 100) / total_steps ))
    local filled=$(( progress / 5 ))
    local empty=$(( 20 - filled ))
    local bar=$(printf "%${filled}s" | tr ' ' '█')$(printf "%${empty}s" | tr ' ' '-')
    echo "Overall Progress: [${bar}] ${progress}%"
}

# === Reusable Step Executor with Loader and Error Handling ===
# This function is the core of the improved script.
# It handles backgrounding, loading animation, waiting, and error checking.
# Usage: run_step <step_number> "Description of step" "command_to_run"
run_step() {
    local step_num=$1
    local message=$2
    local command=$3
    local earth_spin=("🌍" "🌎" "🌏")
    local i=0

    print_banner
    print_main_progress "$step_num"
    echo "$message"

    # Execute command in the background, redirecting output
    eval "$command" > /tmp/gensyn_setup.log 2>&1 &
    local pid=$!

    # Spinner loop - uses kill -0 which is more portable than /proc
    while kill -0 $pid 2>/dev/null; do
        printf "\r[%s] %s" "${earth_spin[$i]}" "Running..."
        i=$(( (i + 1) % ${#earth_spin[@]} ))
        sleep 0.2
    done

    # CRITICAL: Wait for the process and get its actual exit code
    wait $pid
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        printf "\r[%s] ${GREEN}Done${NC}      \n" "🌍"
        sleep 1
    else
        print_banner
        print_main_progress "$step_num"
        echo -e "$message"
        printf "\r[✖] ${BOLD}Failed${NC}\n"
        echo "-----------------------------------------------------"
        echo "Error executing step. See log for details:"
        echo "-----------------------------------------------------"
        # Show last 10 lines of the log
        tail -n 10 /tmp/gensyn_setup.log
        echo "-----------------------------------------------------"
        echo "Log file location: /tmp/gensyn_setup.log"
        echo "Exiting setup. Please fix the issue and retry."
        exit 1
    fi
}

# === Main Script Execution ===

# Initial setup
clear
print_banner
print_main_progress 0
echo "Starting Gensyn setup in 3 seconds..."
sleep 3

# --- Step 1: System Update & Dependencies ---
run_step 1 "[1/6] Updating system and installing base packages..." \
  "sudo apt update -qq && sudo apt install -y -qq \
  sudo python3 python3-venv python3-pip \
  curl wget screen git lsof nano unzip iproute2 \
  build-essential gcc g++"

# --- Step 2: CUDA Setup ---
run_step 2 "[2/6] Downloading and running CUDA setup..." \
  "rm -f cuda.sh && \
  curl -s -o cuda.sh https://raw.githubusercontent.com/zunxbt/gensyn-testnet/main/cuda.sh && \
  chmod +x cuda.sh && \
  bash ./cuda.sh"

# --- Step 3: Node.js and Yarn (using modern, non-deprecated method) ---
run_step 3 "[3/6] Setting up Node.js and Yarn..." \
  "sudo apt-get update -qq && sudo apt-get install -y -qq ca-certificates curl gnupg && \
  sudo mkdir -p /etc/apt/keyrings && \
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
  echo 'deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main' | sudo tee /etc/apt/sources.list.d/nodesource.list && \
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/yarnkey.gpg && \
  echo 'deb [signed-by=/etc/apt/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian/ stable main' | sudo tee /etc/apt/sources.list.d/yarn.list && \
  sudo apt-get update -qq && sudo apt-get install -y -qq nodejs yarn"

# --- Step 4: Version Check ---
print_banner
print_main_progress 4
echo "[4/6] Verifying installed versions..."
if ! (node -v && npm -v && yarn -v && python3 --version) >/dev/null 2>&1; then
    echo "Version check failed. One or more components are not installed correctly."
    exit 1
fi
echo "Versions:"
printf "┌──────────┬──────────┐\n"
printf "│ Node.js  │ %-8s │\n" "$(node -v 2>/dev/null || echo "N/A")"
printf "│ npm      │ %-8s │\n" "$(npm -v 2>/dev/null || echo "N/A")"
printf "│ Yarn     │ %-8s │\n" "$(yarn -v 2>/dev/null || echo "N/A")"
printf "│ Python   │ %-8s │\n" "$(python3 --version 2>/dev/null | cut -d' ' -f2 || echo "N/A")"
printf "└──────────┴──────────┘\n"
sleep 2

# --- Step 5: Clone Gensyn Project (Idempotent) ---
# This step is now separate from the loader as it's quick and needs conditional logic.
print_banner
print_main_progress 5
echo "[5/6] Getting Gensyn AI repository..."
if [ -d "rl-swarm" ]; then
    echo "-> Directory 'rl-swarm' already exists. Updating from git..."
    (cd rl-swarm && git pull)
else
    echo "-> Cloning repository..."
    git clone https://github.com/gensyn-ai/rl-swarm.git
fi
echo "[✔] Repository is ready."
sleep 1

# --- Step 6: Python Virtual Environment & Frontend Setup ---
# This command is now structured to work correctly without a broken `source`
# It CDe into the correct directories to perform the actions.
run_step 6 "[6/6] Setting up Python environment and frontend..." \
  "cd rl-swarm && \
  python3 -m venv .venv && \
  cd modal-login && \
  yarn install --silent && \
  yarn upgrade --silent && \
  yarn add next@latest viem@latest --silent \
  yarn add @fontsource/inter \
  yarn add @fontsource/inter encoding pino-pretty"
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm install 20.18.0
nvm use 20.18.0
node -v

# === Final Output ===
print_banner
print_main_progress 6
echo
echo "${BOLD}✅ GENSYN SETUP COMPLETE${NC}"
echo "${BOLD}🛡️ DEVIL KO THANKS BOLO${NC}"
echo
echo "To get started, navigate to the project directory:"
echo "${GREEN}cd rl-swarm${NC}"
