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
  systemctl enable nfs rpcbind
  #测试nfs功能
  showmount -e 10.10.10.222
+ 创建ZooKeeper集群
  1.创建pv (zookeeper-pv.yaml)
  ```yaml
  kubectl apply -f https://github.com/cctvto/k8s-elk/blob/main/yaml/zookeeper-pv.yaml  
  ```
  2.创建 ZooKeeper 集群 
    ```
  kubectl apply -f https://github.com/cctvto/k8s-elk/blob/main/yaml/zookeeper.yaml
+ 创建 Kafka 集群
  1.搭建一个包含 3 个节点的 Kafka 集群创建一个 kafka.yaml 文件
   ```
  kubectl apply -f https://github.com/cctvto/k8s-elk/blob/main/yaml/kafka.yaml