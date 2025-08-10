# BUGS

### Description

- Internal-IP in output of `kubectl get nodes -o wide`

```bash
vagrant@mfouadiS:~$ kubectl get nodes -o wide
NAME        STATUS   ROLES                  AGE     VERSION        INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
mfouadis    Ready    control-plane,master   115m    v1.33.3+k3s1   10.0.2.15     <none>        Ubuntu 24.04.2 LTS   6.8.0-64-generic   containerd://2.0.5-k3s2
mfouadisw   Ready    <none>                 4m20s   v1.33.3+k3s1   10.0.2.15     <none>        Ubuntu 24.04.2 LTS   6.8.0-64-generic   containerd://2.0.5-k3s2
```

### Expected

Machines IP adresses 