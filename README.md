
# Install cluster

```shell
kind create cluster --name my-cluster --config ./cluster-config.yaml
```

# Configure cluster

## Install NGINX Ingress Controller

```sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

Wait until is ready to process requests running:

```sh
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

## Install ArgoCD

```sh
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Web need to run argocd as `insecure` because we want the TLS to be terminated at the edge.

```sh
kubectl apply -f argocd-cmd-params-cm.yaml
kubectl rollout restart deployment argocd-server -n argocd
```

## Expose Web UI

Apply the argo-ingress resource

```sh
kubectl apply -f argocd-ingress.yaml
```

The UI should now be available at [http://argocd.localhost](http://argocd.localhost)

default username is **admin** and you can retrieve the default password with the following command

```sh
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Bootstrap argocd with "apps in app" strategy

```sh
kubectl apply -f argocd-bootstrapper.yaml
```

## Additional WSL considerations

Kubernetes clusters are usually deployed with WSL on Windows. This means that services exposed through ingress controllers or node ports are inaccessible outside the local host. 

To reach services from outside the local machine e.g. from another host on the local network, you would need to set up a port proxy that binds a listening port on 0.0.0.0 on your host and forwards any traffic to the guest (WSL) on a desired destination port. We could easily expose web endpoints as follows:

Find the WSL ip you want to forward to by logging into the wsl guest or by querying the ingress-controllers external ip:

```sh
kubectl get -n ingress-nginx svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Apply the port proxy on the windows machine by opening an elevated powershell terminal and run the following command

```powershell
netsh interface portproxy add v4tov4 listenport=80 listenaddress=0.0.0.0 connectport=80 connectaddress=<wsl-ip>
```

You can remove the forwarding rule with the following command if you need to change the configuration

```powerhsell
netsh interface portproxy delete v4tov4 listenport=80
```

Read more about the available [Netsh interface commands](https://docs.microsoft.com/en-us/windows-server/networking/technologies/netsh/netsh-interface-portproxy).