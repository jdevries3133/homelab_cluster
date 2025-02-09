#!/bin/bash

ssh $SSH_TARGET '
    set -ex

    curl \
        https://raw.githubusercontent.com/jdevries3133/vim_config/main/common.vim \
        --output $HOME/.vimrc

    sed -i "s/^#force_color_prompt/force_color_prompt/g" $HOME/.bashrc

    echo "alias n=\"vim\"" > ~/.bash_aliases
'

exec ssh $SSH_TARGET
