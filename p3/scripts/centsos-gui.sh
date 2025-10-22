yum install -y gnome-session gdm
sudo systemctl enable gdm
sudo systemctl start gdm
sudo systemctl set-default graphical.target