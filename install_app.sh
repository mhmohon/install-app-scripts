#!/bin/bash
# This script helps in installing the essential installation packages
#
##################################################################################################################
# Written to be used on 64 bits computers
# Author 	: 	Mosharrf Hossain
# Email 	: 	mhmosharrf@gmail.com
##################################################################################################################
#
# Running the script:
# chmod +x install_app.sh
# sudo ./install_app.sh


# Check the root accesss
if [ $UID -ne 0 ]; then
    print_colored "Root access required" "danger"
    exit 1
fi

# Create a log file to store the installation status
LOG_FILE="installation_report.log"
echo "Installation Report" > "$LOG_FILE"
echo "-------------------" >> "$LOG_FILE"
echo >> "$LOG_FILE"

# ***************
# Utils 
# ***************
print_colored() {
    COLOR_PREFIX="\033[0;"
    GREEN="32m"
    RED="31m"
    GREY="37m"
    INFO="96m"
    NO_COLOR="\033[0m"
    if [ "$2" == "danger" ]; then
        COLOR="${COLOR_PREFIX}${RED}"
    elif [ "$2" == "success" ]; then
        COLOR="${COLOR_PREFIX}${GREEN}"
    elif [ "$2" == "debug" ]; then
        COLOR="${COLOR_PREFIX}${GREY}"
    elif [ "$2" == "info" ]; then
        COLOR="${COLOR_PREFIX}${INFO}"
    else
        COLOR="${NO_COLOR}"
    fi
    printf "${COLOR}%b${NO_COLOR}\n" "$1"
}

if [ $UID -ne 0 ]; then
    print_colored "Root access required" "danger"
    exit 1
fi

# Function to check if a package is installed
is_package_installed_by_apt() {
    dpkg -s "$1" &> /dev/null
}

# Function to check if a package is installed via Flatpak
is_package_installed_by_flatpak() {
    flatpak info "$1" &> /dev/null
}

# Function to check if Flatpak is installed
is_flatpak_installed() {
    flatpak --version &> /dev/null
}

write_the_log_file() {
    app_name=$1

    if [ $? -eq 0 ]; then
        echo "$app_name: installed successfully" >> "$LOG_FILE"
        print_colored "$app_name installed successfully." "success"

    else
        echo "$app_name: installation failed" >> "$LOG_FILE"
        print_colored "$app_name installed successfully." "danger"
    fi
}

install_package_by_curl() {
    app_name=$1
    download_url=$2

    if is_package_installed_by_apt "$app_name"; then
        echo "$app_name (apk) is already installed." "info" >> "$LOG_FILE"
    else
        # Download the package
        echo "Downloading $app_name..."
        curl -o "$app_name.deb" -L "$download_url"

        # Install the package
        echo "Installing $app_name..."
        sudo dpkg -i "$app_name.deb"

        # Install dependencies if needed
        echo "Installing dependencies..."
        sudo apt install -fy
        write_the_log_file "$app_name"
    fi
}

# Add package repository
sudo add-apt-repository ppa:plushuang-tw/uget-stable -y


# Install common applications
apt_packages=(
    curl
    htop
    git
    vlc
    gimp
    build-essential
    nodejs
    npm
    python3
    python3-pip
    php
    php-cli
    unzip
    uget
    pavucontrol
)
flatpak_packages=(
    org.chromium.Chromium
    com.getpostman.Postman
    org.qbittorrent.qBittorrent
    com.github.hluk.copyq
    com.github.tenderowl.frog
    com.slack.Slack
)

# Update packages and Upgrade system
print_colored "Updating all package..." "info"
sudo apt-get update && sudo apt-get upgrade -y
print_colored "Updated all package successfully" "success"

# Install Flatpak if not already installed
if ! is_flatpak_installed; then
    print_colored "Flatpak is not installed. Installing Flatpak..." "info"
    sudo apt install -y flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
else
    echo "Flatpak is already installed." "info" >> "$LOG_FILE"
fi

# Install web development applications via apt
for package in "${apt_packages[@]}"; do
    if is_package_installed_by_apt "$package"; then
        echo "$package (apk) is already installed." "info" >> "$LOG_FILE"
    else
        echo "Installing $package..."
        sudo apt install -y "$package"
        write_the_log_file "$package"
    fi
done
# Install web development applications via Flatpak
for package in "${flatpak_packages[@]}"; do
    if is_package_installed_by_flatpak "$package"; then
        echo "$package (flatpak) is already installed." >> "$LOG_FILE"
    else
        echo "Installing $package..."
        flatpak install -y flathub "$package"
        write_the_log_file "$package"
    fi
done



# Install Visual Studio Code
#install_package_by_curl "vscode" "https://go.microsoft.com/fwlink/?LinkID=760868"

# Install Zoom
#install_package_by_curl "zoom" "https://zoom.us/client/latest/zoom_amd64.deb"

# Install Docker steps
# Check if Docker is already installed
if command -v docker &>/dev/null; then
    echo "Docker is already installed."
else
    # Remove any docker file
    sudo apt-get remove docker docker-engine docker.io
    sudo apt-get update
    # Install required packages for Docker installation
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    # Add Docker repository
    echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$UBUNTU_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    # Install Docker
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker "$USER"
    write_the_log_file "Docker"
fi

# Install composer steps
# Check if composer is already installed
if command -v composer &>/dev/null; then
    echo "composer is already installed." >> "$LOG_FILE"
else
    # Install required packages for composer installation
    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
    print_colored "Composer installed successfully." "success"
fi

# Cleanup unused packages
sudo apt autoremove -y
if [ $? -eq 0 ]; then
    echo "Cleanup complete" >> "$LOG_FILE"
else
    echo "Failed to cleanup packages" >> "$LOG_FILE"
fi

# Generate the summary report
cat "$LOG_FILE"
print_colored "All packages installation complete!" "success"

################################################################
####################    T H E   E N D    #######################
################################################################