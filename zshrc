#
# Sets Oh My Zsh options.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Set the key mapping style to 'emacs' or 'vi'.
zstyle ':omz:module:editor' keymap 'vi'

# Auto convert .... to ../..
zstyle ':omz:module:editor' dot-expansion 'no'

# Set case-sensitivity for completion, history lookup, etc.
zstyle ':omz:*:*' case-sensitive 'no'

# Color output (auto set to 'no' on dumb terminals).
zstyle ':omz:*:*' color 'yes'

# Auto set the tab and window titles.
zstyle ':omz:module:terminal' auto-title 'no'

# Set the Zsh modules to load (man zshmodules).
# zstyle ':omz:load' zmodule 'attr' 'stat'

# Set the Zsh functions to load (man zshcontrib).
# zstyle ':omz:load' zfunction 'zargs' 'zmv'

# Set the Oh My Zsh modules to load (browse modules).
# The order matters.
zstyle ':omz:load' omodule \
  'environment' \
  'terminal' \
  'editor' \
  'history' \
  'directory' \
  'spectrum' \
  'utility' \
  'completion' \
  'prompt' \
  'git' \
  'history-substring-search'

# Set the prompt theme to load.
# Setting it to 'random' loads a random theme.
# Auto set to 'off' on dumb terminals.
zstyle ':omz:module:prompt' theme 'tangledhelix'

# This will make you shout: OH MY ZSHELL!
source "$OMZ/init.zsh"

# Customize to your needs...

# after ssh, set the title back to local host's name
ssh() {
  if [[ -x /usr/local/bin/ssh ]]; then
    /usr/local/bin/ssh $@
  else
    /usr/bin/ssh $@
  fi
  printf "\x1b]2;$(uname -n)\x07\x1b]1;$(uname -n)\x07"
}

# always unicode in tmux
test -n "$(command -v tmux)" && alias tmux="tmux -u"

alias c='clear'
alias ppv='puppet parser validate'

# print the directory structure from the current directory in tree format
alias dirf="find . -type d|sed -e 's/[^-][^\/]*\//  |/g' -e 's/|\([^ ]\)/|-\1/'"

# Show me time in GMT / UTC
alias utc="TZ=UTC date"
alias gmt="TZ=GMT date"
# Time in Tokyo
alias jst="TZ=Asia/Tokyo date"

# show me platform info
alias os="uname -srm"

hw() {
  if [[ "$(uname -s)" != "SunOS" ]]; then
    echo "'hw' only works on Solaris"
    return
  fi
  /usr/platform/`uname -m`/sbin/prtdiag | head -1 | \
    sed "s/^System Configuration: *Sun Microsystems *//" | \
    sed "s/^`uname -m` *//"
}

# translate AS/RR numbers
astr() {
  echo "$1" | tr "[A-J0-9]" "[0-9A-J]"
}

# show me installed version of a perl module
perlmodver() {
  local __module="$1"
  test -n "$__module" || { echo "missing argument"; return; }
  perl -M$__module -e "print \$$__module::VERSION,\"\\n\";"
}

# sleep this long, then beep
beep() {
  local __timer=$1
  until [[ $__timer = 0 ]]; do
    printf "  T minus $__timer     \r"
    __timer=$((__timer - 1))
    sleep 1
  done
  echo '- BEEP! -    \a\r'
}

# fabricate a puppet module directory set
mkpuppetmodule() {
  test -d "$1" && { echo "'$1' already exists"; return }
  mkdir -p $1/{files,templates,manifests}
  cd $1/manifests
  printf "\nclass $1 {\n\n}\n\n" > init.pp
}

# fix ssh variables inside tmux
function fixssh() {
  local __new
  if [[ -n "$TMUX" ]]; then
    __new=$(tmux showenv | grep ^SSH_CLIENT | cut -d = -f 2)
    [[ -n "$__new" ]] && export SSH_CLIENT="$__new"
    __new=$(tmux showenv | grep ^SSH_TTY | cut -d = -f 2)
    [[ -n "$__new" ]] && export SSH_TTY="$__new"
    __new=$(tmux showenv | grep ^SSH_CONNECTION | cut -d = -f 2)
    [[ -n "$__new" ]] && export SSH_CONNECTION="$__new"
    __new=$(tmux showenv | grep ^SSH_AUTH_SOCK | cut -d = -f 2)
    [[ -n "$__new" && -S "$__new" ]] && export SSH_AUTH_SOCK="$__new"
  fi
}

# count something fed in on stdin
alias count="sort | uniq -c | sort -n"

# Strip comment / blank lines from an output
alias stripcomments="egrep -v '^([\ \t]*#|$)'"

alias ack="ack --smart-case"

# Give me a list of the RPM package groups
alias rpmgroups="cat /usr/share/doc/rpm-*/GROUPS"

# Watch Puppet logs
alias tailpa="tail -F /var/log/daemon/debug | grep puppet-agent"
alias tailpm="tail -F /var/log/daemon/debug | grep puppet-master"

if [[ $UID -eq 0 ]]; then

  ### Things to do only if I am root

  # Messes with rdist
  unset SSH_AUTH_SOCK

else

  ### Things to do only if I am not root

  # set title to hostname
  printf "\x1b]2;$(uname -n)\x07\x1b]1;$(uname -n)\x07"

  test -f ~/.rbenv/bin/rbenv && eval "$(rbenv init -)"

  # Check for broken services on SMF-based systems
  test -x /bin/svcs && svcs -xv

  # Create some Vim cache directories if they don't exist.
  mkdir -p ~/.vim/tmp/{undo,backup,swap}

  # fix yankring permissions
  __yankring="$HOME/.vim/yankring_history_v2.txt"
  if [[ -f $__yankring ]]; then
    if [[ ! -O $__yankring ]]; then
      echo "WARNING: yankring history file is not writeable"
    else
      chmod 0600 $__yankring
    fi
  else
    touch $__yankring
    chmod 0600 $__yankring
  fi

  # List tmux sessions
  if [[ -n "$(command -v tmux)" && -z "$TMUX" ]]; then
    tmux ls 2>/dev/null
  fi

fi

# local settings override global ones
test -s $HOME/.zshrc.local && source $HOME/.zshrc.local
