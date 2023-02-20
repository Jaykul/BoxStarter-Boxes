# There are other ways to install Python, but I like conda
# There's no point in installing it, if you're not going to put it on your path
choco upgrade -y miniconda3 --params="'/AddToPath:1 /RegisterPython:1'"

@(
    "ms-python.python"
) | InstallCodeExtension