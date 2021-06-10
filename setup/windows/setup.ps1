$USERNAME=(Write-Output $env:username)

$MINIKUBE_DIR=($HOME) + "\.minikube"
$CERT_DIRECTORY="$MINIKUBE_DIR\redhat-certs"
$SCRIPTPATH=((Split-Path -parent $MyInvocation.MyCommand.Path) | Split-Path -Parent)
$MINIKUBE_CONTEXT=${USERNAME}+"-context"
$NAMESPACE_DEV=${USERNAME}+"-dev"
$NAMESPACE_STAGE=${USERNAME}+"-stage" 

function create_certificates {
    Write-Host "Creating certificates ..."
    if (! (test-path -Path $CERT_DIRECTORY)) {
        mkdir $CERT_DIRECTORY}
   
    Set-Location "$CERT_DIRECTORY"
    openssl genrsa -out $CERT_DIRECTORY\$USERNAME.key 2048  > $null 2>&1
    openssl req -new -key $CERT_DIRECTORY\$USERNAME.key -out $CERT_DIRECTORY\$USERNAME.csr -subj "/CN=$USERNAME/O=group1"  > $null 2>&1
    openssl x509 -req -in $CERT_DIRECTORY\$USERNAME.csr -CA $MINIKUBE_DIR\ca.crt -CAkey $MINIKUBE_DIR\ca.key -CAcreateserial -out $CERT_DIRECTORY\$USERNAME.crt -days 500  > $null 2>&1

    cp $CERT_DIRECTORY\$USERNAME.key $MINIKUBE_DIR\$USERNAME.key
    cp $CERT_DIRECTORY\$USERNAME.crt $MINIKUBE_DIR\$USERNAME.crt
    Set-Location $HOME
}

function delete_certificates {
    Write-Host "Deleting certificates ..."
    $keyPath=(Test-Path -Path ${MINIKUBE_DIR}\$USERNAME.key)
    $crtPath=(Test-Path -Path ${MINIKUBE_DIR}\$USERNAME.crt)
    
    if ($keyPath -eq $True)
    {
        rm ${MINIKUBE_DIR}\$USERNAME.key
        if ($? -eq $False) 
        {
        Write-Host "Error deleting key file ${MINIKUBE_DIR}\$USERNAME.key"
        exit
        } 
    }
    if ($crtPath -eq $True)
    {
        rm ${MINIKUBE_DIR}\$USERNAME.crt
        if ($? -eq $False) 
        {
        Write-Host "Error deleting key file ${MINIKUBE_DIR}\$USERNAME.crt"
        exit
        }
    } 
    elseif ($keyPath -eq $False)
    {
    Write-Host "${MINIKUBE_DIR}\$USERNAME.key not found."
    }
    elseif ($crtPath -eq $False) 
    {
    Write-Host "${MINIKUBE_DIR}\$USERNAME.crt not found."
    }
}

function create_namespace(${1}){
    kubectl get namespace ${1} > $null 2>&1
    if ($? -eq $False) 
    {
        Write-Host "Creating namespace '${1}' ..."
        kubectl create namespace ${1} > $null
       
        if ($? -eq $False)
        {
        Write-Host "Error while creating namespace ${1}."
        exit
        } else {
        Write-Host "Namespace ${1} created."
        }
    }
    elseif ($? -eq $True) 
    {
    Write-Host "Namespace ${1} already exists" 
    } else {  
    Write-Host "Error while creating namespace ${1}"
    exit
    }    
}

function delete_namespace(${1}) {
    kubectl get namespace ${1} > $null 2>&1
    if ($? -eq $True)
    { 
        Write-Host "Deleting namespace '${1}' ..."
        kubectl delete namespace ${1} > $null 2>&1
        if ($? -eq $False)
        {
        Write-Host "Error while deleting namespace ${1}"
        exit
        } 
    }
    elseif ($? -eq $False)
    {
    Write-Host "Namespace ${1} not found"
    exit
    }
}

function configure_kubectl_credentials {
    Write-Host "Creating Kubectl credentials for '${USERNAME}' ..."
    kubectl config set-credentials $USERNAME --client-certificate=$CERT_DIRECTORY\$USERNAME.crt --client-key=$CERT_DIRECTORY\$USERNAME.key  > $null 2>&1
    if ($? -eq $False) {
        Write-Host "Error while creating config credentials"
        exit
    } else { Write-Host "Credentials created"
    } 
}

function create_kubectl_context {
    Write-Host "Creating Kubectl context '$MINIKUBE_CONTEXT' for user '${USERNAME}' ..."
    kubectl config set-context $MINIKUBE_CONTEXT --cluster=minikube --user=$USERNAME --namespace=${1}  > $null 2>&1
    if ($? -eq $False) {
        Write-Host "Error while creating config context"
        exit
    } 
}

function delete_kubectl_context {
    Write-Host "Deleting Kubectl context '${MINIKUBE_CONTEXT}' ..."
    kubectl config delete-context $MINIKUBE_CONTEXT  > $null 2>&1
    if ($? -eq $False) { 
        Write-Host "Error while deleting config context"
        exit
    } else { 
    Write-Host "Context ${MINIKUBE_CONTEXT} deleted."
    }
}

function apply_role_resources(${1}) {
    $OLDYML= Get-Content -Path $SCRIPTPATH\files\role-binding.yml -Raw
    $NEWYML= $OLDYML -replace '{username}',"${USERNAME}" -replace '{namespace}', ${1}     
    
    if (($NEWYML | Set-Content -Path $SCRIPTPATH\files\role-binding.yml > $null 2>&1) -eq $False) {
        Write-Host "Could not apply security resources."
        exit
    } else {
    Write-Host "Creating role resources for user '${USERNAME}' in namespace '${1}' ..."
    $NEWYML | Set-Content -Path $SCRIPTPATH\files\role-binding.yml
    kubectl apply -f $SCRIPTPATH\files\role-binding.yml --validate=false
    }
}

function use_kubectl_context(${1}) {
    kubectl config use-context ${1} > $null 2>&1
    if ($? -eq $False) {
        Write-Host "Context ${1} is not available"
        exit}
    elseif ($? -eq $True) { 
    Write-Host "Context ${1} has been set."
     }
}

function use_kubectl_namespace(${1}) {
    Write-Host "Switching to namespace '${1}' ..."
    kubectl config set-context --current --namespace=${1}  > $null 2>&1
    if ($? -eq $False) {
        Write-Host "Namespace ${1} is not available"
        exit
    } else {
    Write-Host "Switched to namesapce ${1}"
    }
}

function openssl_status {
    return [bool](Get-Command -Name openssl -ErrorAction SilentlyContinue)
}

function kubectl_status {
    return [bool](Get-Command -Name kubectl -ErrorAction SilentlyContinue)
} 

if ((openssl_status) -eq $False) {
    Write-Host "Please install OpenSSL and add the OpenSSL bin directory to the system environment variable, Path. If already installed, add the OpenSSL bin directory to Path." 
    exit }

if ((kubectl_status) -eq $False) {
    Write-Host "Please install Kubectl" 
    exit }

if (! (Test-Path -Path $MINIKUBE_DIR )) {
    Write-Host "Minikube directory not found"
    exit }

if ((kubectl config current-context) -ne "minikube" > $null 2>&1) {
    Write-Host "Minikube context is not available"
    exit } 

if ( (${1} -eq "--delete" ) -or ( ${1} -eq "-d" )) {

    # Use the default context that relates to admin credentials
    use_kubectl_context "minikube"

    # Move to default namespace
    use_kubectl_namespace "default"

    delete_namespace "${NAMESPACE_DEV}"
    delete_namespace "${NAMESPACE_STAGE}"

    delete_kubectl_context

    delete_certificates
    }

else
    {
    create_namespace "${NAMESPACE_DEV}"
    create_namespace "${NAMESPACE_STAGE}"

    create_certificates
    configure_kubectl_credentials

    create_kubectl_context "${NAMESPACE_DEV}"

    apply_role_resources "${NAMESPACE_DEV}"
    apply_role_resources "${NAMESPACE_STAGE}"

    use_kubectl_context $MINIKUBE_CONTEXT
    use_kubectl_namespace "${NAMESPACE_DEV}"
}

Write-Host "OK!"