sudo apt update
sudo apt-get install -y iputils-ping

# Create mfouadi user
sudo useradd -m -s /bin/bash mfouadi
echo "mfouadi:mfouadi" | sudo chpasswd
sudo usermod -aG sudo mfouadi

# Copy vagrant's SSH configuration to mfouadi user
sudo mkdir -p /home/mfouadi/.ssh
sudo cp /home/vagrant/.ssh/authorized_keys /home/mfouadi/.ssh/ 2>/dev/null || true
sudo chown -R mfouadi:mfouadi /home/mfouadi/.ssh
sudo chmod 700 /home/mfouadi/.ssh
sudo chmod 600 /home/mfouadi/.ssh/authorized_keys 2>/dev/null || true

# Allow mfouadi to use sudo without password (for convenience)
echo "mfouadi ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/mfouadi