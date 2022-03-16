
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
