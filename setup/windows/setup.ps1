$USERNAME=(echo $env:username)

$MINIKUBE_DIR=($HOME) + "\.minikube"
$CERT_DIRECTORY="$MINIKUBE_DIR\redhat-certs"
$SCRIPTPATH=(Split-Path -parent $MyInvocation.MyCommand.Path)
$MINIKUBE_CONTEXT=${USERNAME}+"-context"
$NAMESPACE_DEV=${USERNAME}+"-dev"
$NAMESPACE_STAGE=${USERNAME}+"-stage" 

function create_certificates {
    echo "Creating certificates ..."
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
    echo "Deleting certificates ..."
    $keyPath=(Test-Path -Path ${MINIKUBE_DIR}\$USERNAME.key)
    $crtPath=(Test-Path -Path ${MINIKUBE_DIR}\$USERNAME.crt)
    
    if ($keyPath -eq $True)
    {
        rm ${MINIKUBE_DIR}\$USERNAME.key
        if ($? -eq $False) 
        {
        echo "Error deleting key file ${MINIKUBE_DIR}\$USERNAME.key"
        exit
        } 
    }
    if ($crtPath -eq $True)
    {
        rm ${MINIKUBE_DIR}\$USERNAME.crt
        if ($? -eq $False) 
        {
        echo "Error deleting key file ${MINIKUBE_DIR}\$USERNAME.crt"
        exit
        }
    } 
    elseif ($keyPath -eq $False)
    {
    echo "${MINIKUBE_DIR}\$USERNAME.key not found."
    }
    elseif ($crtPath -eq $False) 
    {
    echo "${MINIKUBE_DIR}\$USERNAME.crt not found."
    }
}

function create_namespace(${1}){
    kubectl get namespace ${1} > $null 2>&1
    if ($? -eq $False) 
    {
        echo "Creating namespace '${1}' ..."
        kubectl create namespace ${1} > $null
       
        if ($? -eq $False)
        {
        echo "Error while creating namespace ${1}."
        exit
        } else {
        echo "Namespace ${1} created."
        }
    }
    elseif ($? -eq $True) 
    {
    echo "Namespace ${1} already exists" 
    } else {  
    echo "Error while creating namespace ${1}"
    exit
    }    
}

function delete_namespace(${1}) {
    kubectl get namespace ${1} > $null 2>&1
    if ($? -eq $True)
    { 
        echo "Deleting namespace '${1}' ..."
        kubectl delete namespace ${1} > $null 2>&1
        if ($? -eq $False)
        {
        echo "Error while deleting namespace ${1}"
        exit
        } 
    }
    elseif ($? -eq $False)
    {
    echo "Namespace ${1} not found"
    exit
    }
}

function configure_kubectl_credentials {
    echo "Creating Kubectl credentials for '${USERNAME}' ..."
    kubectl config set-credentials $USERNAME --client-certificate=$CERT_DIRECTORY\$USERNAME.crt --client-key=$CERT_DIRECTORY\$USERNAME.key  > $null 2>&1
    if ($? -eq $False) {
        echo "Error while creating config credentials"
        exit
    } else { echo "Credentials created"
    } 
}

function create_kubectl_context {
    echo "Creating Kubectl context '$MINIKUBE_CONTEXT' for user '${USERNAME}' ..."
    kubectl config set-context $MINIKUBE_CONTEXT --cluster=minikube --user=$USERNAME --namespace=${1}  > $null 2>&1
    if ($? -eq $False) {
        echo "Error while creating config context"
        exit
    } 
}

function delete_kubectl_context {
    echo "Deleting Kubectl context '${MINIKUBE_CONTEXT}' ..."
    kubectl config delete-context $MINIKUBE_CONTEXT  > $null 2>&1
    if ($? -eq $False) { 
        echo "Error while deleting config context"
        exit
    } else { 
    echo "Context ${MINIKUBE_CONTEXT} deleted."
    }
}

function apply_role_resources(${1}) {
    $OLDYML= Get-Content -Path $SCRIPTPATH\files\role-binding.yml -Raw
    $NEWYML= $OLDYML -replace '{username}',${USERNAME} -replace '{namespace}', ${1}     
    
    if (($NEWYML | Set-Content -Path $SCRIPTPATH\files\role-binding.yml > $null 2>&1) -eq $False) {
        echo "Could not apply security resources."
        exit
    } else {
    echo "Creating role resources for user '${USERNAME}' in namespace '${1}' ..."
    $NEWYML | Set-Content -Path $SCRIPTPATH\files\role-binding.yml
    $OLDYML | kubectl apply -f - --validate=false
    }
}

function use_kubectl_context(${1}) {
    kubectl config use-context ${1} > $null 2>&1
    if ($? -eq $False) {
        echo "Context ${1} is not available"
        exit}
    elseif ($? -eq $True) { 
    echo "Context ${1} has been set."
     }
}

function use_kubectl_namespace(${1}) {
    echo "Switching to namespace '${1}' ..."
    kubectl config set-context --current --namespace=${1}  > $null 2>&1
    if ($? -eq $False) {
        echo "Namespace ${1} is not available"
        exit
    } else {
    echo "Switched to namesapce ${1}"
    }
}

function openssl_status {
    return [bool](Get-Command -Name openssl -ErrorAction SilentlyContinue)
}

function kubectl_status {
    return [bool](Get-Command -Name kubectl -ErrorAction SilentlyContinue)
} 

if ((openssl_status) -eq $False) {
    echo "Please install OpenSSL and add the OpenSSL bin directory to the system environment variable, Path. If already installed, add the OpenSSL bin directory to Path." 
    exit }

if ((kubectl_status) -eq $False) {
    echo "Please install Kubectl" 
    exit }

if (! (Test-Path -Path $MINIKUBE_DIR )) {
    echo "Minikube directory not found"
    exit }

if ((kubectl config current-context) -ne "minikube" > $null 2>&1) {
    echo "Minikube context is not available"
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

echo "OK!"