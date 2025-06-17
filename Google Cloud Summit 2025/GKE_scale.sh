# Create a cluster
gcloud container clusters create-auto demo \
    --release-channel=stable \
    --cluster-version 1.30.12-gke.1033000 \
    --region=us-central1

# Deploy to 'demo' cluster
gcloud container clusters get-credentials demo --region=us-central1
kubectl apply -f demoApp.yml

### Create yml file

# s/w context
kubectl config use-context <context-name>
kubectl config use-context gke_$(gcloud config get-value project)_us-central1_demo

# Get the external IP for the service
echo "Waiting for External IP for the 'demo' cluster..."
while [[ -z $(kubectl get svc php-apache -o jsonpath='{.status.loadBalancer.ingress[0].ip}') ]]; do
    sleep 2
done
EXTERNAL_IP_DEMO=$(kubectl get svc php-apache -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "External IP for 'old' cluster is: $EXTERNAL_IP_DEMO"


# New tab for monitoring
watch kubectl get hpa,pods

# Return to the first tab

# Simulate load for 3 min w/ 50 connections
hey -z 5m -c 50 http://$EXTERNAL_IP_DEMO