#!/bin/bash
set -e

# step 1
sudo apt update -qq
sudo apt install -y sudo python3 python3-venv python3-pip curl wget screen git lsof nano unzip iproute2 build-essential gcc g++

# step 2
rm -f cuda.sh
curl -s -o cuda.sh https://raw.githubusercontent.com/zunxbt/gensyn-testnet/main/cuda.sh
chmod +x cuda.sh
bash ./cuda.sh

# step 3 node + yarn
sudo apt-get update -qq
sudo apt-get install -y -qq ca-certificates curl gnupg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo 'deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main' | sudo tee /etc/apt/sources.list.d/nodesource.list
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/yarnkey.gpg
echo 'deb [signed-by=/etc/apt/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian/ stable main' | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update -qq
sudo apt-get install -y -qq nodejs yarn

# step 4 clone project
if [ -d "rl-swarm" ]; then
  (cd rl-swarm && git pull)
else
  git clone https://github.com/gensyn-ai/rl-swarm.git
fi

# step 5 python env + frontend
cd rl-swarm
python3 -m venv .venv
source .venv/bin/activate
cd modal-login
yarn install
yarn upgrade
yarn add next@latest viem@latest
cd ..
git reset --hard
git pull origin main
git checkout tags/v0.6.0

echo "✅ Setup complete"
