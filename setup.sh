echo "updating apt package index...."
sudo apt-get update -y

echo "Installing git..."
sudo apt-get install -y git

echo "installing docker and docker-compose..."
sudo apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "adding user to docker group..."
sudo usermod -aG docker azureuser

echo "creating app directory and cloning repo..."
APP_DIR="/home/azureuser/Project1"
REPO_URL="https://github.com/DELONE-de/Project1.git"
BRANCH="main"
ADMIN_USERNAME="azureuser"

sudo mkdir -p "/home/$ADMIN_USERNAME" || { echo "Error: Failed to ensure /home/$ADMIN_USERNAME exists."; exit 1; }
sudo chown "$ADMIN_USERNAME":"$ADMIN_USERNAME" "/home/$ADMIN_USERNAME" || { echo "Error: Failed to set ownership for /home/$ADMIN_USERNAME."; exit 1; }

# --- 3. Change to the user's home directory (a common base for operations) ---
cd "/home/$ADMIN_USERNAME" || { echo "Error: Failed to change to user's home directory."; exit 1; }

# --- 4. Conditional Git Clone/Pull Logic ---
if [ -d "$APP_DIR/.git" ]; then
  echo "Repository already cloned at $APP_DIR. Pulling latest changes..."
  cd "$APP_DIR" || { echo "Error: Failed to change to existing app directory $APP_DIR."; exit 1; }
  git pull origin "$BRANCH" || { echo "Error: Git pull failed."; exit 1; }
else
  echo "Cloning new repository into $APP_DIR..."
  git clone -b "$BRANCH" "$REPO_URL" "$APP_DIR" || { echo "Error: Git clone failed."; exit 1; }
  cd "$APP_DIR" || { echo "Error: Failed to change to newly cloned app directory $APP_DIR."; exit 1; }
fi

echo "--- Repository operations complete. Current directory: $(pwd) ---"

echo "navigating to app directory..."
cd /home/azureuser/Project1

echo "pulling latest docker images..."
docker compose pull

echo "starting docker compose..."
docker compose down
docker compose build
docker compose up -d

echo "listing running containers..."
docker ps -