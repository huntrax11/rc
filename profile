# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

if [ -f ~/.git-completion.bash ]; then
    . ~/.git-completion.bash
fi

# add ~/.env to PATH
if [ -d "$HOME/.env" ] ; then
    export PATH="`find ~/.env -maxdepth 2 -type d -name bin | tr '\n' ':'`${PATH}"
    export MANPATH="`find ~/.env -maxdepth 4 -type d -name man | tr '\n' ':'`${MANPATH}"
    export INFOPATH="`find ~/.env -maxdepth 4 -type d -name info | tr '\n' ':'`${INFOPATH}"
fi

# RVM
export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

# aliases
alias rm="rm -i"
alias ls="ls --color=auto"
alias ll="ls -l"

# jcurl, require Pygments(sudo pip install Pygments)
function jcurl {
    curl "$@" | python -mjson.tool | pygmentize -l json
}

# Auto Env
function cd {
    builtin cd $@
    if [ -n "$AUTO_ENV" ] && [ "$(expr `pwd` : $AUTO_ENV)" -eq "0"  ]; then
        deactivate
        unset AUTO_ENV
    else
        if [ -f ./bin/activate ]; then
            export AUTO_ENV=`pwd`
            source ./bin/activate
        fi
    fi
}
