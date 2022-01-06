#!/bin/bash
# describe: create k8s cluster all namespaces resources with readonly clusterrole, no exec 、delete ...

# look system default to study:
# kubectl describe clusterrole view

# restore all change:
#kubectl -n kube-system delete sa all-readonly-${clustername}
#kubectl delete clusterrolebinding all-readonly-${clustername}
#kubectl delete clusterrole all-readonly-${clustername}


clustername=$1

Help(){
    echo "Use "$(basename "$0")" ClusterName(example: k8s1|k8s2|k8s3|delk8s1|delk8s2|delk8s3|3in1)";
    exit 1;
}

if [[ -z "${clustername}" ]]; then
    Help
fi

case ${clustername} in
    k8s1)
    endpoint="https://x.x.x.x:123456"
    ;;
    k8s2)
    endpoint="https://x.x.x.x:123456"
    ;;
    k8s3)
    endpoint="https://x.x.x.x:123456"
    ;;
    delk8s1)
    kubectl -n kube-system delete sa all-readonly-k8s1
    kubectl delete clusterrolebinding all-readonly-k8s1
    kubectl delete clusterrole all-readonly-k8s1
    echo "${clustername} successful."
    exit 0
    ;;
    delk8s2)
    kubectl -n kube-system delete sa all-readonly-k8s2
    kubectl delete clusterrolebinding all-readonly-k8s2
    kubectl delete clusterrole all-readonly-k8s2
    echo "${clustername} successful."
    exit 0
    ;;
    delk8s3)
    kubectl -n kube-system delete sa all-readonly-k8s3
    kubectl delete clusterrolebinding all-readonly-k8s3
    kubectl delete clusterrole all-readonly-k8s3
    echo "${clustername} successful."
    exit 0
    ;;
    3in1)
    KUBECONFIG=./all-readonly-k8s1.conf:all-readonly-k8s2.conf:all-readonly-k8s3.conf kubectl config view --flatten > ./all-readonly-3in1.conf
    kubectl --kubeconfig=./all-readonly-3in1.conf config use-context "k8s3"
    kubectl --kubeconfig=./all-readonly-3in1.conf config set-context "k8s3" --namespace="default"
    kubectl --kubeconfig=./all-readonly-3in1.conf config get-contexts
    echo -e "\n\n\n"
    cat ./all-readonly-3in1.conf |base64 -w 0
    exit 0
    ;;
    *)
    Help
esac

echo "---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: all-readonly-${clustername}
rules:
- apiGroups:
  - ''
  resources:
  - configmaps
  - endpoints
  - persistentvolumes
  - persistentvolumeclaims
  - pods
  - replicationcontrollers
  - replicationcontrollers/scale
  - serviceaccounts
  - services
  - nodes
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ''
  resources:
  - bindings
  - events
  - limitranges
  - namespaces/status
  - pods/log
  - pods/status
  - replicationcontrollers/status
  - resourcequotas
  - resourcequotas/status
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ''
  resources:
  - namespaces
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - controllerrevisions
  - daemonsets
  - deployments
  - deployments/scale
  - replicasets
  - replicasets/scale
  - statefulsets
  - statefulsets/scale
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - autoscaling
  resources:
  - horizontalpodautoscalers
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - batch
  resources:
  - cronjobs
  - jobs
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  resources:
  - daemonsets
  - deployments
  - deployments/scale
  - ingresses
  - networkpolicies
  - replicasets
  - replicasets/scale
  - replicationcontrollers/scale
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - policy
  resources:
  - poddisruptionbudgets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - networking.k8s.io
  resources:
  - networkpolicies
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - metrics.k8s.io
  resources:
  - pods
  verbs:
  - get
  - list
  - watch" | kubectl apply -f -

kubectl -n kube-system create sa all-readonly-${clustername}
kubectl create clusterrolebinding all-readonly-${clustername} --clusterrole=all-readonly-${clustername} --serviceaccount=kube-system:all-readonly-${clustername}

tokenName=$(kubectl -n kube-system get sa all-readonly-${clustername} -o "jsonpath={.secrets[0].name}")
token=$(kubectl -n kube-system get secret $tokenName -o "jsonpath={.data.token}" | base64 --decode)
certificate=$(kubectl -n kube-system get secret $tokenName -o "jsonpath={.data['ca\.crt']}")

echo "apiVersion: v1
kind: Config
preferences: {}
clusters:
- cluster:
    certificate-authority-data: $certificate
    server: $endpoint
  name: all-readonly-${clustername}-cluster
users:
- name: all-readonly-${clustername}
  user:
    as-user-extra: {}
    client-key-data: $certificate
    token: $token
contexts:
- context:
    cluster: all-readonly-${clustername}-cluster
    user: all-readonly-${clustername}
  name: ${clustername}
current-context: ${clustername}" > ./all-readonly-${clustername}.conf