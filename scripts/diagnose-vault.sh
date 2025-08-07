#!/bin/bash

echo "🔍 VAULT DEPLOYMENT DIAGNOSTICS"
echo "================================"

NAMESPACE="vault"
SERVICE_NAME="vault-minimal"

echo ""
echo "📊 1. CHECKING NAMESPACE"
kubectl get namespace $NAMESPACE

echo ""
echo "📦 2. CHECKING PODS"
kubectl get pods -n $NAMESPACE -o wide

echo ""
echo "🏷️  3. CHECKING SERVICES"
kubectl get svc -n $NAMESPACE

echo ""
echo "📋 4. CHECKING DEPLOYMENTS"
kubectl get deployments -n $NAMESPACE

echo ""
echo "🔄 5. CHECKING REPLICASETS"
kubectl get rs -n $NAMESPACE

echo ""
echo "📜 6. CHECKING EVENTS (Last 10 minutes)"
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -20

echo ""
echo "🚨 7. CHECKING POD STATUS DETAILS"
PODS=$(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
for POD in $PODS; do
    echo "--- Pod: $POD ---"
    kubectl describe pod $POD -n $NAMESPACE | grep -A 20 "Conditions:\|Events:"
done

echo ""
echo "📝 8. CHECKING POD LOGS"
for POD in $PODS; do
    echo "--- Logs for: $POD ---"
    kubectl logs $POD -n $NAMESPACE --tail=50 || echo "No logs available"
done

echo ""
echo "🔧 9. CHECKING HELM RELEASE STATUS"
helm status vault-minimal -n $NAMESPACE

echo ""
echo "📊 10. CHECKING SERVICE ENDPOINTS"
kubectl get endpoints -n $NAMESPACE

echo ""
echo "🎯 11. TESTING SERVICE CONNECTIVITY"
kubectl run debug-pod --image=nicolaka/netshoot --rm -it --restart=Never -- /bin/bash -c "nslookup $SERVICE_NAME.$NAMESPACE.svc.cluster.local && curl -v http://$SERVICE_NAME.$NAMESPACE.svc.cluster.local:8200/v1/sys/health" || echo "Service connectivity test failed"
