#! /bin/sh

OPENSHIFT_CLUSTER_NAME="openshift-cluster"
OPENSHIFT_CREDENTIALS_NAME="openshift-credentials"
OPENSHIFT_CONTEXT="openshift-context"

if ! command -v kubectl  > /dev/null 2>&1
then
    echo "Please install Kubectl"
    exit
fi

echo 'What is the OpenShift cluster URL?'
read OPENSHIFT_CLUSTER_URL

echo 'What is the OpenShift token?'
read OPENSHIFT_TOKEN

echo 'What is your OpenShift username?'
read OPENSHIFT_USERNAME

echo 'Creating Kubectl context...'

kubectl config set-cluster ${OPENSHIFT_CLUSTER_NAME} --server=${OPENSHIFT_CLUSTER_URL} > /dev/null 2>&1
kubectl config set-credentials ${OPENSHIFT_CREDENTIALS_NAME} --token=${OPENSHIFT_TOKEN} > /dev/null 2>&1
kubectl config set-context ${OPENSHIFT_CONTEXT} --cluster=${OPENSHIFT_CLUSTER_NAME} --user=${OPENSHIFT_CREDENTIALS_NAME} --namespace=${OPENSHIFT_USERNAME}-dev > /dev/null 2>&1
kubectl config use openshift-context > /dev/null 2>&1

echo 'Context created successfully'