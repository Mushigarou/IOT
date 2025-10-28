#!/bin/bash
set -e

echo "Applying deployment..."
kubectl apply -f /confs/deploy.yaml

echo "Applying services..."
kubectl apply -f /confs/apps-services.yaml

echo "Applying ingress..."
kubectl apply -f /confs/ingress.yaml

echo "Waiting briefly for resources to settle..."
sleep 3

echo "Requesting app1.com..."
curl -sS -H "Host: app1.com" $NODE_SERVER_IP || echo "curl to app1.com failed"

echo "Requesting app2.com..."
curl -sS -H "Host: app2.com" $NODE_SERVER_IP || echo "curl to app2.com failed"

echo "Requesting app3.com..."
curl -sS -H "Host: app3.com" $NODE_SERVER_IP || echo "curl to app3.com failed"

echo "Deployment and checks complete."