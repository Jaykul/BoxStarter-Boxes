# I don't quite understand why you would install conda and _not_ put it in your path
choco upgrade -y miniconda3 --params="'/AddToPath:1 /RegisterPython:1'"

@(
    "ms-python.python"
) | InstallCodeExtension