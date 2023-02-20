choco upgrade -y kubernetes-cli
choco upgrade -y kubernetes-helm
# Because I work with AKS a lot
choco upgrade -y azure-kubelogin


@(
    "ms-kubernetes-tools.vscode-kubernetes-tools"
) | InstallCodeExtension