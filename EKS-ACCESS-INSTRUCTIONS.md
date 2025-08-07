# Additional AWS auth mapping for EKS cluster access
# Add this to your tf-aws-dev-eks workspace main.tf

# Add to the eks module configuration:
# In the module "eks" block, add this parameter:

# access_entries = {
#   # Add your AWS role for kubectl access
#   david_joo_access = {
#     kubernetes_groups = ["system:masters"]
#     principal_arn     = "arn:aws:sts::521614675974:assumed-role/aws_david.joo_test-developer/david.joo@hashicorp.com"
#     type             = "STANDARD"
#   }
# }

# Or alternatively, you can use the aws_auth configmap approach:
# manage_aws_auth_configmap = true
# aws_auth_roles = [
#   {
#     rolearn  = "arn:aws:iam::521614675974:role/aws_david.joo_test-developer"
#     username = "david.joo"
#     groups   = ["system:masters"]
#   }
# ]
