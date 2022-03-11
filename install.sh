#!/usr/bin/bash

kind create cluster --name my-cluster --config ./cluster-config.yaml

printf "\ninstalling nginx ingress controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

printf "\nwaiting for ingress controller to get ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

printf "\ninstalling argocd..."
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

printf "\nconfiguring argocd..."
kubectl apply -f argocd-cmd-params-cm.yaml
kubectl rollout restart deployment argocd-server -n argocd
kubectl wait -n argocd \
  --for=condition=ready pod \
  --timeout=90s \
  --selector=app.kubernetes.io/name=argocd-server

printf "\nexposing web UI..."
kubectl apply -f argocd-ingress.yaml

argo_password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
printf "\nArgoCD now available at http://argocd.local"
printf "admin:$argo_password"

printf "\ndone."