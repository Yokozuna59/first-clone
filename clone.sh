#!/bin/bash

# exit command exits with a non-zero status.
set -e

# chack what OS is running
function check_operating_system() {
    if [[ "$(uname)" == "Linux" ]]; then
        OS="Linux"
    elif [[ "$(uname)" == "Darwin" ]]; then
        OS="Mac"
    elif [[ "$(uname)" == "MINGW32_NT" || "$(uname)" == "MINGW64_NT" ]]; then
        wsl
        OS="Linux"
    else
        echo "Unknown system"
        exit 1
    fi
}

# check if git installed on the system
function check_git_installation() {
    if [ ! git --version >/dev/null 2>&1 ]; then
        check_operating_system
    else
        update_git
    fi
}

# install git on linux
function linux_insallation() {
    declare -Ag osInfo;
	osInfo[/etc/alpine-release]=apk
	osInfo[/etc/debian_version]=apt-get
	osInfo[/etc/gentoo-release]=emerge
	osInfo[/etc/arch-release]=pacman
	osInfo[/etc/redhat-release]=yum
	osInfo[/etc/SuSE-release]=zypp
	for f in ${!osInfo[@]}; do
		if [[ -f $f ]];then
			sudo "${osInfo[$f]}" update
			sudo "${osInfo[$f]}" install git -y
		fi
	done
}

# install git on mac
function mac_installation() {
	which -s brew
	if [[ $? != 0 ]] ; then
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" -y && brew install git -y
	else
		brew update -y
	fi
}

function update_git() {
    if [[ "$OS" == "Linux" ]]; then
        linux_insallation
    elif [[ "$OS" == "Mac" ]]; then
        mac_installation
    fi
}

# check if git config is set
function check_git_config() {
    if [ -z "$(git config --global user.name)" ]; then
        read -p "Enter your name: " name
        git config --global user.name "$name"
    fi

    if [ -z "$(git config --global user.email)" ]; then
        read -p "Enter your email: " email
        git config --global user.email "$email"
    fi
}

function do_git_commands() {
    read -p "Enter your git repository: " github_repo
    read -p "Enter your github token: " github_token

    IFS='/'
    read -ra ADDR <<< ${github_repo%.*}

    git clone "https://$github_token@github.com/${ADDR[3]}/${ADDR[4]}.git"

    cd ${ADDR[4]}

    git init
    echo "<!-- this line was added by the CLONE.sh script to be able to commit and push the changes to the remote repository -->" >> README.md
    git add README.md
    git commit -m "Initial commit"
    git branch -M master
    git push origin master
}

function main() {
    check_operating_system
    check_git_installation
    check_git_config
    do_git_commands
}

main
