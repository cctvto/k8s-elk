#!/bin/bash
#
# This Script based on  https://jeremievallee.com/2018/05/28/kubernetes-rbac-namespace-user.html
# K8s'RBAC doc:         https://kubernetes.io/docs/reference/access-authn-authz/rbac
# Gitlab'CI/CD doc:     hhttps://docs.gitlab.com/ee/user/permissions.html#running-pipelines-on-protected-branches
#
# In honor of the remarkable Windson

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

if ! kubectl get ns|awk 'NR!=1{print $1}'|grep -w "$namespace";then kubectl create ns "$namespace";else echo "namespace: $namespace was exist." ;fi

echo "---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $namespace-user
  namespace: $namespace
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: $namespace-user-full-access
  namespace: $namespace
rules:
- apiGroups: ['', 'extensions', 'apps', 'metrics.k8s.io']
  resources: ['*']
  verbs: ['*']
- apiGroups: ['batch']
  resources:
  - jobs
  - cronjobs
  verbs: ['*']
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: $namespace-user-view
  namespace: $namespace
subjects:
- kind: ServiceAccount
  name: $namespace-user
  namespace: $namespace
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: $namespace-user-full-access
---
# https://kubernetes.io/zh/docs/concepts/policy/resource-quotas/
apiVersion: v1
kind: ResourceQuota
metadata:
  name: $namespace-compute-resources
  namespace: $namespace
spec:
  hard:
    pods: "10"
    services: "10"
    persistentvolumeclaims: "5"
    requests.cpu: "1"
    requests.memory: 2Gi
    limits.cpu: "2"
    limits.memory: 4Gi" | kubectl apply -f -
kubectl -n $namespace describe quota $namespace-compute-resources
mkdir -p $folder
tokenName=$(kubectl get sa $namespace-user -n $namespace -o "jsonpath={.secrets[0].name}")
token=$(kubectl get secret $tokenName -n $namespace -o "jsonpath={.data.token}" | base64 --decode)
certificate=$(kubectl get secret $tokenName -n $namespace -o "jsonpath={.data['ca\.crt']}")

echo "apiVersion: v1
kind: Config
preferences: {}
clusters:
- cluster:
    certificate-authority-data: $certificate
    server: https://$endpoint
  name: $namespace-cluster
users:
- name: $namespace-user
  user:
    as-user-extra: {}
    client-key-data: $certificate
    token: $token
contexts:
- context:
    cluster: $namespace-cluster
    namespace: $namespace
    user: $namespace-user
  name: $namespace
current-context: $namespace" > $folder/$namespace.kube.conf