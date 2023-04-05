choco upgrade -y kubernetes-cli
choco upgrade -y kubernetes-helm
# Because I work with AKS a lot
choco upgrade -y azure-kubelogin


@(
    "ms-kubernetes-tools.vscode-kubernetes-tools"
    "mindaro.mindaro" # Bridge to Kubernetes
    "ms-azuretools.vscode-docker"
    "kennylong.kubernetes-yaml-formatter"
    # "weaveworks.vscode-gitops-tools"
) | InstallCodeExtension