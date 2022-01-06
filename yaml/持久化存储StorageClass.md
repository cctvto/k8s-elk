# StorageClass 安装
---
+ 生成StorageClass配置
  ```
  具体配置看nfs-sc.yaml
+ 创建StorageClass
  ```
  kubectl apply -f nfs-sc.yaml 
  kubectl get sc
+ 创建PVC
  ```
  kubectl  apply -f pvc-sc.yaml 
+ 应用PVC
  ```
  nginx.yaml 
  volumes:
        - name: html-files
          persistentVolumeClaim:
            claimName: pvc-sc
