# Azure DR Analytics Platform

This Terraform configuration creates a disaster recovery (DR) replica of an AWS analytics platform in Azure. The infrastructure supports R/Shiny applications with high availability, security, and scalability.

## Architecture Overview

### Azure Services Mapping from AWS:

| AWS Service | Azure Service | Purpose |
|-------------|---------------|---------|
| VPC | Virtual Network (VNet) | Network isolation |
| ECS/Fargate | Container Instances | Container orchestration |
| ELB | Application Gateway | Load balancing with WAF |
| S3 | Blob Storage + Azure Files | Object and file storage |
| EFS | Azure Files | Shared file system |
| Athena | Synapse Analytics | Data analytics |
| Route 53 | Azure DNS | DNS management |
| CloudWatch | Azure Monitor | Monitoring and logging |
| GuardDuty | Security Center | Security monitoring |
| Certificate Manager | Key Vault | Certificate management |
| ECR | Container Registry | Container image storage |
| Transfer Family | Container Instance (SFTP) | File transfer |
| DataSync | Data Factory | Data movement |

## Infrastructure Components

### Networking
- **Virtual Network**: Multi-zone setup with public and private subnets
- **NAT Gateways**: Outbound internet access for private resources
- **Application Gateway**: Load balancing with integrated WAF
- **Network Security Groups**: Traffic filtering and security

### Compute
- **Container Groups**: Shiny and RStudio applications in multiple zones
- **Auto Scaling**: Automatic scaling based on demand
- **SFTP Server**: File ingestion endpoint

### Storage & Data
- **Storage Account**: Blob storage for data and files
- **Azure Files**: Shared file system for applications
- **Synapse Analytics**: Data warehousing and analytics
- **SQL Database**: Metadata and configuration storage

### Security
- **Web Application Firewall**: Protection against web attacks
- **Key Vault**: Secure storage for secrets and certificates
- **Private Endpoints**: Secure connectivity to PaaS services
- **Network Security Groups**: Granular network security

### Monitoring
- **Azure Monitor**: Comprehensive monitoring solution
- **Application Insights**: Application performance monitoring
- **Log Analytics**: Centralized logging
- **Alerts**: Proactive monitoring and notifications

## Prerequisites

1. **Azure CLI**: Install and authenticate
   ```bash
   az login
   ```

2. **Terraform**: Install Terraform >= 1.0 (tested with v1.13.4)
   ```bash
   terraform --version
   ```

3. **Azure Subscription**: Ensure you have appropriate permissions

## Deployment Instructions

### 1. Clone and Configure

```bash
# Clone the repository
git clone <repository-url>
cd azure-dr-analytics-platform

# Copy and customize variables
cp terraform.tfvars.example terraform.tfvars
```

### 2. Customize Variables

Edit `terraform.tfvars` with your specific values:

```hcl
resource_group_name = "your-dr-rg"
location           = "East US 2"
project_name       = "yourproject"
domain_name        = "your-domain.com"
admin_email        = "admin@your-domain.com"

# Set strong passwords
synapse_admin_password = "YourStrongPassword123!"
sql_admin_password     = "YourStrongPassword123!"
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply configuration
terraform apply
```

### 4. Post-Deployment Configuration

After deployment, configure:

1. **DNS**: Update your domain's nameservers to point to Azure DNS
2. **Certificates**: Import SSL certificates into Key Vault
3. **Container Images**: Push your applications to Container Registry
4. **Data Sync**: Configure Data Factory for data replication

## Application Deployment

### Container Registry

```bash
# Get registry credentials
az acr credential show --name <registry-name>

# Build and push images
docker build -t <registry>.azurecr.io/shiny-app:latest .
docker push <registry>.azurecr.io/shiny-app:latest
```

### Update Container Groups

After pushing images, update the container groups to use your custom images:

```bash
terraform apply -var="shiny_image=<registry>.azurecr.io/shiny-app:latest"
```

## Monitoring and Maintenance

### Key Metrics to Monitor

- Container CPU and memory usage
- Storage account capacity
- Application Gateway performance
- Network security group violations

### Backup Strategy

- **Storage Account**: Geo-redundant storage with versioning
- **SQL Database**: Automated backups with point-in-time recovery
- **Application Data**: Regular snapshots of Azure Files

### Disaster Recovery Testing

1. Regularly test failover procedures
2. Validate data synchronization
3. Test application functionality
4. Document recovery procedures

## Security Best Practices

1. **Network Security**: Restrict IP ranges in production
2. **Secrets Management**: Use Key Vault for all secrets
3. **Access Control**: Implement least privilege access
4. **Monitoring**: Enable all diagnostic settings
5. **Updates**: Keep container images updated

## Cost Optimization

1. **Resource Sizing**: Right-size based on actual usage
2. **Auto-Shutdown**: Configure auto-pause for Synapse
3. **Storage Tiers**: Use appropriate storage tiers
4. **Reserved Instances**: Consider reserved capacity for predictable workloads

## Troubleshooting

### Common Issues

1. **Container Start Failures**: Check container logs and resource limits
2. **Network Connectivity**: Verify NSG rules and routing
3. **DNS Issues**: Confirm DNS zone configuration
4. **Certificate Errors**: Check Key Vault certificate status

### Useful Commands

```bash
# Check container logs
az container logs --resource-group <rg> --name <container-group>

# Monitor metrics
az monitor metrics list --resource <resource-id>

# Check Application Gateway health
az network application-gateway show-backend-health --resource-group <rg> --name <appgw>
```

## Support

For issues or questions:
1. Check Azure documentation
2. Review Terraform Azure provider docs
3. Contact your infrastructure team

## License

This infrastructure code is provided as-is for disaster recovery purposes.