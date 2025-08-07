#!/bin/bash

echo "🔍 INVESTIGATING LOADBALANCERS"
echo "=============================="

LB1="ae75af49b85984c168f9588ccec2cf42"
REGION="ap-southeast-2"

echo "1. Getting details for LoadBalancer: $LB1"
echo "----------------------------------------"

if command -v aws &> /dev/null; then
    echo "LoadBalancer Details:"
    aws elbv2 describe-load-balancers --region $REGION --load-balancer-arns arn:aws:elasticloadbalancing:$REGION:521614675974:loadbalancer/classic/$LB1 2>/dev/null || \
    aws elb describe-load-balancers --region $REGION --load-balancer-names $LB1 2>/dev/null || \
    echo "Failed to get LoadBalancer details via AWS CLI"
    
    echo ""
    echo "Tags for LoadBalancer:"
    aws elb describe-tags --region $REGION --load-balancer-names $LB1 2>/dev/null || \
    aws elbv2 describe-tags --region $REGION --resource-arns arn:aws:elasticloadbalancing:$REGION:521614675974:loadbalancer/classic/$LB1 2>/dev/null || \
    echo "Failed to get tags"
    
    echo ""
    echo "Listeners/Ports:"
    aws elb describe-load-balancers --region $REGION --load-balancer-names $LB1 --query 'LoadBalancerDescriptions[0].ListenerDescriptions[*].[Listener.Protocol,Listener.LoadBalancerPort,Listener.InstancePort]' --output table 2>/dev/null || \
    echo "Failed to get listener details"
    
else
    echo "AWS CLI not available. Please check manually in AWS Console:"
    echo ""
    echo "1. Click on LoadBalancer: $LB1"
    echo "2. Check the 'Description' tab for creation details"
    echo "3. Check the 'Tags' tab for:"
    echo "   - kubernetes.io/cluster/vault-demo-cluster"
    echo "   - kubernetes.io/service-name"
    echo "   - kubernetes.io/service-namespace"
    echo "4. Check the 'Listeners' tab for port configuration"
fi

echo ""
echo "🔍 WHAT TO LOOK FOR:"
echo "==================="
echo "If this LoadBalancer has tags like:"
echo "- kubernetes.io/cluster/vault-demo-cluster = owned"
echo "- kubernetes.io/service-name = vault-minimal"
echo "- kubernetes.io/service-namespace = vault"
echo ""
echo "Then it's a DUPLICATE Vault LoadBalancer and causing conflicts!"
echo ""
echo "If it has different tags or no Kubernetes tags, it's from another service."
echo ""
echo "MANUAL CHECK STEPS:"
echo "1. Go to AWS Console → EC2 → Load Balancers"
echo "2. Click on: $LB1"
echo "3. Check 'Tags' tab"
echo "4. Check 'Description' tab for creation date/time"
echo "5. Compare with your Terraform apply timestamps"
