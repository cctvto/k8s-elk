# kafaka 在k8s中的安装
+ 安装NFS
  ```
  #安装nfs
  yum install nfs-utils
  #创建共享目录
  mkdir /nfs_data
  mkdir -p  /nfs_dir/zookeeper/pv{1..3}
  mkdir -p  /nfs_dir/kafka/pv{1..3}
  chown nobody.nobody /nfs_data
  #修改配置文件
  echo '/nfs_data *(rw,sync,no_root_squash)' > /etc/exports
  #重启服务
  systemctl restart rpcbind
  systemctl restart nfs
  systemctl enable nfs
  #测试nfs功能
  showmount -e 10.10.10.222
+ 创建ZooKeeper集群
  1.创建pv
  ```yaml
  apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: k8s-pv-zk01
    labels:
      app: zk
    annotations:
      volume.beta.kubernetes.io/storage-class: "anything"
  spec:
    capacity:
      storage: 1Gi
    accessModes:
      - ReadWriteOnce
    nfs:
      server: 10.10.10.220
      path: "/nfs_dir/zookeeper/pv1"
    persistentVolumeReclaimPolicy: Recycle  
  ```
  2.创建 ZooKeeper 集群 
    ```
     zookeeper.yaml 
+ 创建 Kafka 集群
  1.搭建一个包含 3 个节点的 Kafka 集群创建一个 kafka.yaml 文件
