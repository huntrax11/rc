#!/bin/bash
cd "$(dirname $0)"
CWD="$(pwd)"

function install_coreutils() {
    VERSION="8.13"
    mkdir -p $HOME/.env/build && cd $HOME/.env/build
    curl -O http://ftp.gnu.org/gnu/coreutils/coreutils-${VERSION}.tar.gz
    tar -xzf coreutils-${VERSION}.tar.gz
    cd coreutils-${VERSION}
    ./configure --prefix=$HOME/.env/coreutils-${VERSION}
    make && make install
    rm -rf $HOME/.enn/build/coreutils-*
}

if [[ $(uname -a) =~ "Darwin" ]] && ! [[ $(which ln) =~ "/.env/coreutils" ]]; then
    install_coreutils
    ln -sf $HOME/.profile $CWD/profile
else
    ln -sf $CWD/profile $HOME/.profile
    sudo ln -sf $CWD/limits.conf /etc/security/limits.conf
fi
#echo '[[ -s "$HOME/.profile" ]] && source "$HOME/.profile" # Load the default .profile' >> ~/.bash_profile
source $HOME/.profile

ln -sf $CWD/vimrc $HOME/.vimrc
ln -sf $CWD/gitconfig $HOME/.gitconfig
ln -sf $CWD/pryrc $HOME/.pryrc
ln -sf $CWD/rubocop.yml $HOME/.rubocop.yml

git submodule update --init
ln -sfT $CWD/vim $HOME/.vim
vim +PluginInstall +qall
vim +PluginClean! +qall

# golang
vim +GoInstallBinaries +qall

curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash

sudo easy_install pip
sudo pip install virtualenv flake8 pygments
