#!/bin/bash

set -e

echo "Secondary web server started"

sudo apt update -y
sudo apt upgrade -y

sudo apt install -y curl git 

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
\. "$HOME/.nvm/nvm.sh"
nvm install 24
node -v 
npm -v


npm install -g pm2

