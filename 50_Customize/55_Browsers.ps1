## I pin the browsers because they self-update anyway, so I want choco to ignore them
## These are the two that I'm willing to use
if (!$Release) {
    choco upgrade -y microsoft-edge-insider-dev --pin
}
choco upgrade -y firefox --pin
## I won't use chrome because of their EULA, but if you need it, uncomment this one:
# choco upgrade -y googlechrome --pin
