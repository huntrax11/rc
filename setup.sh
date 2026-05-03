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
xargs -I {} uv tool install {} < uv_tool_requirements
uv pip install --system -r pip_requirements

# Vim / Neovim
ln -sf $CWD/vimrc $HOME/.vimrc
mkdir -p $HOME/.config
if [ -L "$HOME/.vim" ] || [ -d "$HOME/.vim" ]; then
    rm -rf $HOME/.vim
fi
ln -sf $CWD/vim $HOME/.vim
if [ -L "$HOME/.config/nvim" ] || [ -d "$HOME/.config/nvim" ]; then
    rm -rf $HOME/.config/nvim
fi
ln -sf $CWD/vim $HOME/.config/nvim
nvim +PlugUpgrade +qall
nvim +PlugInstall +PlugUpdate +PlugClean! +qall

# Ruby
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -sSL https://get.rvm.io | bash -s stable
source "$HOME/.rvm/scripts/rvm"
rvm install ruby
gem install $(cat gem_requirements)
ln -sf $CWD/pryrc $HOME/.pryrc
ln -sf $CWD/rubocop.yml $HOME/.rubocop.yml

# Claude Code
mkdir -p $HOME/.claude/hooks
ln -sf $CWD/claude/CLAUDE.md $HOME/.claude/CLAUDE.md
ln -sf $CWD/claude/settings.json $HOME/.claude/settings.json
ln -sf $CWD/claude/hooks/block-terraform-destroy.sh $HOME/.claude/hooks/block-terraform-destroy.sh
ln -sf $CWD/claude/statusline-command.sh $HOME/.claude/statusline-command.sh
ln -sfn $CWD/claude/lang $HOME/.claude/lang
ln -sfn $CWD/claude/stack $HOME/.claude/stack
