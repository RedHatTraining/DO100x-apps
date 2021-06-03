$OPENSHIFT_CLUSTER_NAME="openshift-cluster"
$OPENSHIFT_CREDENTIALS_NAME="openshift-credentials"
$OPENSHIFT_CONTEXT="openshift-context"

function kubectl_status {
    return [bool](Get-Command -Name kubectl -ErrorAction SilentlyContinue)
}

if ((kubectl_status) -eq $False) {
    Write-Host "Please install Kubectl" 
    exit }

$OPENSHIFT_CLUSTER_URL = Read-Host -Prompt 'What is the OpenShift cluster URL?' 
if ($OPENSHIFT_CLUSTER_URL) {
    Write-Host "[$OPENSHIFT_CLUSTER_URL] added."
} else {
    Write-Warning -Message "No URL input."
}
$OPENSHIFT_TOKEN = Read-Host -Prompt 'What is the OpenShift token?'
if ($OPENSHIFT_TOKEN) {
    Write-Host "[$OPENSHIFT_TOKEN] added."
} else {
    Write-Warning -Message "No token input."
}

$OPENSHIFT_USERNAME = Read-Host -Prompt 'What is your OpenShift username?'
if ($OPENSHIFT_USERNAME) {
    Write-Host "[$OPENSHIFT_USERNAME] added."
} else {
    Write-Warning -Message "No username input."
}

Write-Host 'Creating Kubectl context...'

kubectl config set-cluster ${OPENSHIFT_CLUSTER_NAME} --server=${OPENSHIFT_CLUSTER_URL} > $null 2>&1
kubectl config set-credentials ${OPENSHIFT_CREDENTIALS_NAME} --token=${OPENSHIFT_TOKEN} > $null 2>&1
kubectl config set-context ${OPENSHIFT_CONTEXT} --cluster=${OPENSHIFT_CLUSTER_NAME} --user=${OPENSHIFT_CREDENTIALS_NAME} --namespace=${OPENSHIFT_USERNAME}-dev > $null 2>&1
kubectl config use openshift-context > $null 2>&1

Write-Host 'Context created successfully' 