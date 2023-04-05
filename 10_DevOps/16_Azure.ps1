# Install or update to the latest Az
UpdateModule Az

choco upgrade -y azure-cli
choco upgrade -y bicep
# choco upgrade -y microsoftazurestorageexplorer

# There are _a lot_ of azure extensions for VS Code.
# I don't want to install very many everywhere.

@(
    "ms-vscode.azure-account"
    # Azure DevOps
    "ms-azure-devops.azure-pipelines"
    "ms-vscode.azure-repos"
    "ms-azuretools.vscode-bicep"
    "ms-azuretools.vscode-azureresourcegroups"
) | InstallCodeExtension
