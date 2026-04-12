#!/bin/bash
cd "$(dirname $0)"
CWD="$(pwd)"

read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
echo "";
if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi;

if [[ $(uname -a) =~ "Darwin" ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew install $(cat brew_requirements)
    brew install --cask $(cat brew_cask_requirements)
    for tool in coreutils findutils gawk gnu-sed gnu-tar; do
        if [ -d "/opt/homebrew/opt/$tool/libexec" ]; then
            mkdir -p $HOME/.local/opt/$tool
            ln -sf /opt/homebrew/opt/$tool/libexec/gnubin $HOME/.local/opt/$tool/bin
            ln -sf /opt/homebrew/opt/$tool/libexec/gnuman $HOME/.local/opt/$tool/man
        fi
    done
else
    sudo add-apt-repository -y ppa:neovim-ppa/stable
    sudo apt-get update
    sudo apt-get install -y $(cat apt_requirements)
    sudo ln -sf $CWD/limits.conf /etc/security/limits.conf
fi

# shell
ln -sf $CWD/profile $HOME/.profile
[ -f $CWD/profile.local ] && ln -sf $CWD/profile.local $HOME/.profile.local
ln -sf $CWD/curlrc $HOME/.curlrc
source $HOME/.profile

# git
ln -sf $CWD/gitconfig $HOME/.gitconfig
[ -f $CWD/gitconfig.local ] && ln -sf $CWD/gitconfig.local $HOME/.gitconfig.local
ln -sf $CWD/gitignore_global $HOME/.gitignore_global
curl -s https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash

# tmux
ln -sf $CWD/tmux.conf $HOME/.tmux.conf

# Terraform
ln -sf $CWD/terraformrc $HOME/.terraformrc

# python
if [[ "$(which pip3)" != "" ]]; then
    pip3 freeze | xargs pip3 uninstall -y
    pip3 install --upgrade -r pip_requirements
fi

# Vim
ln -sf $CWD/vimrc $HOME/.vimrc
if [ -d "$HOME/.vim" ]; then
    rm -rf $HOME/.vim
fi
ln -sfT $CWD/vim $HOME/.vim
mkdir -p ~/.config
if [ -d "$HOME/.config/nvim" ]; then
    rm -rf $HOME/.config/nvim
fi
ln -sfT $CWD/vim $HOME/.config/nvim
vim +PlugUpgrade +qall
vim +PlugInstall +PlugUpdate +PlugClean! +qall

# Ruby
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -sSL https://get.rvm.io | bash -s stable
source "$HOME/.rvm/scripts/rvm"
rvm install ruby
gem install $(cat gem_requirements)
ln -sf $CWD/pryrc $HOME/.pryrc
ln -sf $CWD/rubocop.yml $HOME/.rubocop.yml
