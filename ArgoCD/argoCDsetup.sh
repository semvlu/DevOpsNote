## Setup
# 1. Install
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 2. Download CLI
brew install argocd

# 3. Acc Argo CD
# Change the argocd-server service type to LoadBalancer:
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Get external IP
kubectl get svc argocd-server -n argocd -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'

kubectl port-forward svc/argocd-server -n argocd 8080:443
# Go to: https://localhost:8080

# ---

# 4. CLI login
# Get password
argocd admin initial-password -n argocd
# Login w/ userpass admin/<initial-password>
argocd login <ARGOCD_SERVER>

# Change password
argocd account update-password
# N.B. Delete `argocd-initial-admin-secret` from Argo CD ns once password changed.

# ---

# 6. Create app from git repo
    # UI: `+ New App` button -> 
    # General: Application Name: guestbook, Project: default
    # Source: Repo URL: <URL>, Path: guestbook
    # Destination: Cluster: https://kubernetes.default.svc, Namespace: default

kubectl config set-context --current --namespace=argocd

argocd app create guestbook \
    --repo https://github.com/argoproj/argocd-example-apps.git \
    --path guestbook \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace default

# 7. Sync (Deploy) app 
# UI: App page -> `Sync` button

# Check status
argocd app get guestbook
# Sync (deploy)
argocd app sync guestbook # works like kubectl apply
