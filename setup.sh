#!/bin/bash
cd "$(dirname $0)"
CWD="$(pwd)"

gpg --keyserver hkp://keys.gnupg.net \
    --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -sSL https://get.rvm.io | bash -s stable
if [[ $(uname -a) =~ "Darwin" ]] && ! [[ $(which ln) =~ "/.env/coreutils" ]]; then
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    brew install $(cat brew_requirements)
    brew cask install $(cat brew_cask_requirements)
    mkdir -p $HOME/.env/coreutils
    ln -sf /usr/local/opt/coreutils/libexec/gnubin $HOME/.env/coreutils/bin
    ln -sf /usr/local/opt/coreutils/libexec/gnuman $HOME/.env/coreutils/man
else
    sudo apt-get install -y git vim python-pip
    sudo ln -sf $CWD/limits.conf /etc/security/limits.conf
fi
ln -sf $CWD/profile $HOME/.profile
source $HOME/.profile

ln -sf $CWD/vimrc $HOME/.vimrc
ln -sf $CWD/gitconfig $HOME/.gitconfig
ln -sf $CWD/gitignore_global $HOME/.gitignore_global
ln -sf $CWD/pryrc $HOME/.pryrc
ln -sf $CWD/rubocop.yml $HOME/.rubocop.yml

git submodule update --init
ln -sfT $CWD/vim $HOME/.vim
vim +PluginInstall +qall
vim +PluginClean! +qall

# golang
vim +GoInstallBinaries +qall

curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash

sudo pip install -r pip_requirements
