#!/bin/bash


BASEDIR="$(dirname "$0")"
folder="$BASEDIR/kube_config"

echo -e "All namespaces is here: \n$(kubectl get ns|awk 'NR!=1{print $1}')"
echo "endpoint server if local network you can use $(kubectl cluster-info |awk '/Kubernetes/{print $NF}')"

namespace=$1
endpoint=$(echo "$2" | sed -e 's,https\?://,,g')

if [[ -z "$endpoint" || -z "$namespace" ]]; then
    echo "Use "$(basename "$0")" NAMESPACE ENDPOINT";
    exit 1;
fi


echo "---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $namespace-user-readonly
  namespace: $namespace
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: $namespace-user-readonly-access
  namespace: $namespace
rules:
- apiGroups: ['', 'extensions', 'apps', 'metrics.k8s.io']
  resources: ['pods', 'pods/log']
  verbs: ['get', 'list', 'watch']
- apiGroups: ['batch']
  resources: ['jobs', 'cronjobs']
  verbs: ['get', 'list', 'watch']
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: $namespace-user-view-readonly
  namespace: $namespace
subjects:
- kind: ServiceAccount
  name: $namespace-user-readonly
  namespace: $namespace
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: $namespace-user-readonly-access" | kubectl apply -f -

mkdir -p $folder
tokenName=$(kubectl get sa $namespace-user-readonly -n $namespace -o "jsonpath={.secrets[0].name}")
token=$(kubectl get secret $tokenName -n $namespace -o "jsonpath={.data.token}" | base64 --decode)
certificate=$(kubectl get secret $tokenName -n $namespace -o "jsonpath={.data['ca\.crt']}")

echo "apiVersion: v1
kind: Config
preferences: {}
clusters:
- cluster:
    certificate-authority-data: $certificate
    server: https://$endpoint
  name: $namespace-cluster-readonly
users:
- name: $namespace-user-readonly
  user:
    as-user-extra: {}
    client-key-data: $certificate
    token: $token
contexts:
- context:
    cluster: $namespace-cluster-readonly
    namespace: $namespace
    user: $namespace-user-readonly
  name: $namespace
current-context: $namespace" > $folder/$namespace-readonly.kube.conf
