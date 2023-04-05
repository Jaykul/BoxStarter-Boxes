# NOTE: Currently, I consider VS Code almost a requirement for DevOps
if (!$Release) {
    choco upgrade -y vscode-insiders
} else {
    choco upgrade -y vscode
}

@(
    "eamodio.gitlens"
    "ms-vsliveshare.vsliveshare"
    "esbenp.prettier-vscode" # Code formatting for most languages

    # # User Experience (spotting problems in your code, and communicating them)
    "aaron-bond.better-comments"
    "gruntfuggly.todo-tree"
    "usernamehw.errorlens"
    "wengerk.highlight-bad-chars"
    "oderwat.indent-rainbow"

    # # DevOps Stuff
    "redhat.vscode-yaml" # Basic YAML support
    "bmuskalla.vscode-tldr" # simple examples/help for common shell commands (like pip)
    "redhat.vscode-xml"
    "jinliming2.vscode-go-template"
    # "DotJoshJohnson.xml"
    # "tsandall.opa" # Open Policy Agent
    # # Containers
    "ms-vscode-remote.remote-containers"
    "ms-vscode-remote.remote-wsl"
    # # PowerShell
    "ms-vscode.PowerShell"
    "pspester.pester-test"
    "TylerLeonhardt.vscode-inline-values-powershell"
    # # Jupyter:
    "ms-python.python" # REQUIRED BY Jupyter
    "ms-toolsai.jupyter" # REQUIRED BY Polyglot notebooks
    "ms-dotnettools.dotnet-interactive-vscode" # Polyglot Notebooks

    # # Good extensions that I never actually use...
    # "tanhakabir.rest-book" # Like postman for Polyglot Notebooks
    # "humao.rest-client" # Like postman for vscode
    # "ms-toolsai.vscode-jupyter-cell-tags"
    # "ms-toolsai.jupyter-keymap"
    # "ms-toolsai.jupyter-renderers"
    # "ms-toolsai.vscode-jupyter-slideshow"
    # "editorconfig.editorconfig"
    # "ms-vscode.azurecli" # .azcli files?
    # "hashicorp.terraform"
    # "4ops.terraform"
) | InstallCodeExtension
