#!/bin/bash
# Usage: ssh-agent-pipe [ -k | -r ]
# Options:
#    -k    Kill the current process (if exists) and do not restart it.
#    -r    Kill the current process (if exists) and restart it.
# Default operation is to start a process only if it does not exist.

export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock

sshpid=$(ss -ap | grep "$SSH_AUTH_SOCK")
if [ "$1" = "-k" ] || [ "$1" = "-r" ]; then
    sshpid=${sshpid//*pid=/}
    sshpid=${sshpid%%,*}
    if [ -n "${sshpid}" ]; then
        kill "${sshpid}"
    else
        echo "socat not found or PID not found"
    fi
    if [ "$1" = "-k" ]; then
        exit
    fi
    unset sshpid
fi

if [ -z "${sshpid}" ]; then
    rm -f $SSH_AUTH_SOCK
    ( setsid socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork & ) >/dev/null 2>&1
fi
