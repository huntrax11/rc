export PATH="$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
    if [ -f ~/.git-completion.bash ]; then
        . ~/.git-completion.bash
    fi
fi

# add ~/.local/opt tools to PATH
if [ -d "$HOME/.local/opt" ] ; then
    export PATH="`find -L ~/.local/opt -maxdepth 2 -type d -name bin | tr '\n' ':'`${PATH}"
    export MANPATH="`find -L ~/.local/opt -maxdepth 4 -type d -name man | tr '\n' ':'`${MANPATH}"
fi

# Bash - Vim mode
if [ -n "$BASH_VERSION" ] ; then
    set -o vi
fi
# zsh - Vim mode
if [ -n "$ZSH_VERSION" ] ; then
    bindkey -v
fi

# aliases
alias rm="rm -i"
alias ls="ls --color=auto"
alias ll="ls -l"
alias vim="nvim"

function topk {
    sort | uniq -c | sort -k 1nr | head -$1
}

# Auto Env
function cd {
    builtin cd "$@"
    if [ -n "$AUTO_ENV" ] && [ "$(expr `pwd` : $AUTO_ENV)" -eq "0"  ]; then
        deactivate
        unset AUTO_ENV
    else
        ENV="$(find . -type f -path '*/bin/activate' -maxdepth 3 2> /dev/null | head -n 1)"
        if [ -f "$ENV" ]; then
            export AUTO_ENV=`pwd`
            source "$ENV"
        fi
    fi
}

# Go
export GOPATH=~/.local/opt/go
export PATH=$GOPATH/bin:$PATH

# Android
export ANDROID_HOME=$HOME/Library/Android/sdk

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

_kube_ctx() { kubectl config current-context 2>/dev/null; }
if [ -n "$ZSH_VERSION" ]; then
    PS1='%{$fg[blue]%}[$(_kube_ctx)]%{$reset_color%} '$PS1
elif [ -n "$BASH_VERSION" ]; then
    PS1='\[\033[34m\][$(_kube_ctx)]\[\033[0m\] '$PS1
else
    PS1='[$(_kube_ctx)] '$PS1
fi

# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
export PATH="$PATH:$HOME/.rvm/bin"

# Machine-specific overrides (not tracked in git)
[ -f "$HOME/.profile.local" ] && . "$HOME/.profile.local"
