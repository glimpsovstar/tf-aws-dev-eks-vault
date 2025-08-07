#!/bin/bash

echo "🔍 VAULT LOADBALANCER TROUBLESHOOTING"
echo "====================================="

LB_DNS="ae73af49b83984c168f9588ccec2cf42-78812259.ap-southeast-2.elb.amazonaws.com"

echo ""
echo "1. DNS Resolution Test:"
echo "----------------------"
nslookup $LB_DNS
echo ""
dig $LB_DNS

echo ""
echo "2. Network Connectivity Test:"
echo "----------------------------"
echo "Testing HTTP connection..."
curl -v -m 10 http://$LB_DNS:8200 || echo "HTTP connection failed"

echo ""
echo "3. Testing different ports:"
echo "--------------------------"
echo "Port 8200:"
nc -zv $LB_DNS 8200 || echo "Port 8200 not accessible"
echo "Port 80:"
nc -zv $LB_DNS 80 || echo "Port 80 not accessible"
echo "Port 443:"
nc -zv $LB_DNS 443 || echo "Port 443 not accessible"

echo ""
echo "4. AWS CLI Checks (if available):"
echo "--------------------------------"
if command -v aws &> /dev/null; then
    echo "Checking LoadBalancer status..."
    aws elbv2 describe-load-balancers --region ap-southeast-2 --query 'LoadBalancers[?DNSName==`'$LB_DNS'`]' || echo "AWS CLI check failed"
    
    echo ""
    echo "Checking target groups..."
    aws elbv2 describe-target-groups --region ap-southeast-2 || echo "Target group check failed"
else
    echo "AWS CLI not available for detailed checks"
fi

echo ""
echo "5. Alternative Access Methods:"
echo "-----------------------------"
echo "If this fails, try:"
echo "- Check AWS Console → EC2 → Load Balancers for the status"
echo "- Verify target group health in AWS Console"
echo "- Check security group rules allow port 8200"

echo ""
echo "Expected working URL: http://$LB_DNS:8200"
