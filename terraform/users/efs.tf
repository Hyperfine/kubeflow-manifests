
resource "kubectl_manifest" "pvc" {
  depends_on = [time_sleep.wait_for_namespace]
  yaml_body = <<YAML
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "${local.key}-efs"
  namespace: ${local.key}
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 20Gi
YAML
}


resource "kubectl_manifest" "efs-home" {
    depends_on = [time_sleep.wait_for_namespace]

  yaml_body = <<YAML
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "${local.key}-efs-home"
  namespace: ${local.key}
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 30Gi
YAML
}

/*
resource "kubectl_manifest" "pvc-transfer" {
  yaml_body = <<YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: transfer
  namespace: ${local.key}
spec:
  template:
    spec:
      volumes:
      - name: "original"
        persistentVolumeClaim:
          claimName: ${local.key}-efs
      - name: "new"
        persistentVolumeClaim:
          claimName: ${local.key}-efs-home
      containers:
      - name: pi
        image: 369500102003.dkr.ecr.us-east-1.amazonaws.com/dl-research:7f8fb9a43dc6bfb0221322aaf6ff7b9b8fdcd79491680450fc3c1d4d0600ec50
        command:
        - "sh"
        - "-c"
        - |
          cp -r /data1/* /data2
          echo "done"
        securityContext:
          runAsUser: 0
        volumeMounts:
        - mountPath: "/data1"
          name: "original"
        - mountPath: "/data2"
          name: "new"
      restartPolicy: Never
  backoffLimit: 4
YAML
}
*/
