#!/bin/bash
cd "$(dirname $0)"
CWD="$(pwd)"

read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
echo "";
if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi;

if [[ $(uname -a) =~ "Darwin" ]]; then
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    brew install $(cat brew_requirements)
    brew cask install $(cat brew_cask_requirements)
    if [ -d "$HOME/.env/coreutils" ]; then
        rm -rf $HOME/.env/coreutils
    fi
    mkdir -p $HOME/.env/coreutils
    ln -sf /usr/local/opt/coreutils/libexec/gnubin $HOME/.env/coreutils/bin
    ln -sf /usr/local/opt/coreutils/libexec/gnuman $HOME/.env/coreutils/man
else
    sudo apt-get install -y git vim python-pip
    sudo ln -sf $CWD/limits.conf /etc/security/limits.conf
fi
ln -sf $CWD/profile $HOME/.profile
source $HOME/.profile

if ! [[ -f "$CWD/vim/bundle/Vundle.vim/README.md" ]]; then
    git submodule update --init
fi

# git
ln -sf $CWD/gitconfig $HOME/.gitconfig
ln -sf $CWD/gitignore_global $HOME/.gitignore_global
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash

# Vim
ln -sf $CWD/vimrc $HOME/.vimrc
if [ -d "$HOME/.vim" ]; then
    rm -rf $HOME/.vim
fi
ln -sfT $CWD/vim $HOME/.vim
vim +PluginInstall +qall
vim +PluginClean! +qall
vim +GoInstallBinaries +qall

# Ruby
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -sSL https://get.rvm.io | bash -s stable
ln -sf $CWD/pryrc $HOME/.pryrc
ln -sf $CWD/rubocop.yml $HOME/.rubocop.yml

sudo pip install -r pip_requirements

if [[ $(uname -a) =~ "Darwin" ]]; then
    read -p "Initialize Vagrant VM? (y/n) " -n 1;
    echo "";
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        vagrant up
    fi;
fi
