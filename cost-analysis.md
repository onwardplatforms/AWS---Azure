# Azure DR Infrastructure - Cost Breakdown Analysis

## 💰 **Estimated Monthly Costs (East US 2)**

*Costs based on Pay-As-You-Go pricing as of January 2025. Actual costs may vary based on usage patterns, reserved instances, and regional pricing.*

---

## 📊 **Total Estimated Monthly Cost: $2,850 - $4,200**

| **Category** | **Low Usage** | **Medium Usage** | **High Usage** |
|--------------|---------------|------------------|----------------|
| **Compute** | $850 | $1,200 | $1,800 |
| **Storage & Data** | $400 | $800 | $1,200 |
| **Networking** | $300 | $450 | $650 |
| **Security & Monitoring** | $200 | $300 | $450 |
| **Management** | $100 | $150 | $200 |
| **TOTAL** | **$1,850** | **$2,900** | **$4,300** |

---

## 🖥️ **COMPUTE COSTS**

### Container Instances (4 instances)
- **Shiny Containers (2x)**: 1 vCPU, 2GB RAM each
  - Cost per instance: ~$45/month
  - **Total**: $90/month

- **RStudio Containers (2x)**: 2 vCPU, 4GB RAM each
  - Cost per instance: ~$90/month
  - **Total**: $180/month

- **SFTP Container (1x)**: 1 vCPU, 1GB RAM
  - Cost: ~$22/month
  - **Total**: $22/month

**Container Instances Subtotal: ~$292/month**

### Application Gateway with WAF
- **Standard WAF v2 (2 instances)**
  - Base cost: $246/month (2 capacity units)
  - Data processing: $0.008/GB
  - Estimated with moderate traffic: ~$320/month

### Azure Synapse Analytics
- **Dedicated SQL Pool** (if running continuously)
  - DW100c: ~$1,000/month
  - **Recommended**: Use serverless billing
  - Serverless: ~$50-200/month based on queries

### Data Factory
- **Pipeline orchestration**: $1/1000 executions
- **Data movement**: $0.25/DIU-hour
- **Estimated**: ~$50-150/month

**Compute Total: $850-1,800/month**

---

## 💾 **STORAGE & DATA COSTS**

### Storage Account
- **Zone Redundant Storage (ZRS)**
  - Hot tier: $0.024/GB/month
  - 1TB estimated: ~$25/month
  - Transactions: ~$10/month

### Azure Files (Shared Storage)
- **Standard tier with ZRS**
  - Shiny share (100GB): ~$12/month
  - RStudio share (200GB): ~$24/month
  - SFTP share (500GB): ~$60/month
  - **Total Files**: ~$96/month

### SQL Database
- **Standard S1** (20 DTUs)
  - Cost: ~$20/month
  - Backup storage: ~$5/month

### Synapse Spark Pool
- **Small nodes (4 vCores, 32GB)**
  - Auto-pause enabled: ~$50-200/month
  - Depends on usage patterns

### Container Registry
- **Standard tier**
  - Storage: $0.10/GB/day
  - 10GB estimated: ~$30/month

**Storage & Data Total: $400-1,200/month**

---

## 🌐 **NETWORKING COSTS**

### Virtual Network
- **Basic VNet**: Free
- **Subnets**: Free

### NAT Gateway (2 instances)
- **Gateway hours**: $0.045/hour × 2 × 744 hours = $67/month
- **Data processing**: $0.045/GB processed
- Estimated 500GB/month: $22.50/month
- **NAT Gateway Total**: ~$90/month

### Public IP Addresses (3 total)
- **Standard IPs**: $0.005/hour × 3 × 744 hours = ~$11/month

### Application Gateway Bandwidth
- **Data transfer**: $0.087/GB (first 10TB)
- Estimated 1TB/month: ~$87/month

### DNS Zone
- **Hosted zone**: $0.50/zone/month
- **DNS queries**: $0.40/million queries
- Estimated: ~$5/month

### DDoS Protection (if enabled)
- **Standard plan**: $2,944/month
- **Note**: This is optional but recommended for production

**Networking Total: $300-650/month**

---

## 🛡️ **SECURITY & MONITORING COSTS**

### Key Vault
- **Standard tier**: $0.03/10,000 operations
- Certificate operations: ~$10/month

### Azure Monitor & Log Analytics
- **Data ingestion**: $2.76/GB
- **Data retention**: $0.12/GB/month
- Estimated 50GB/month: ~$150/month

### Application Insights
- **Data ingestion**: $2.88/GB (first 5GB free)
- Estimated 20GB/month: ~$43/month

### Security Center/Defender
- **Standard tier per resource type**:
  - VMs: $15/month per server
  - Storage: $15/month per storage account
  - SQL: $15/month per server
  - Containers: $7/month per core
  - **Total**: ~$100/month

### Advanced Threat Protection
- **Storage ATP**: $0.02/10,000 transactions
- **SQL ATP**: Included with Defender for SQL
- Estimated: ~$20/month

**Security & Monitoring Total: $200-450/month**

---

## 🔧 **MANAGEMENT & GOVERNANCE COSTS**

### Backup Services
- **SQL Database backup**: Included (7-35 days free)
- **Storage backup**: $0.05/GB/month
- Estimated 500GB: ~$25/month

### Policy & Compliance
- **Azure Policy**: Free for built-in policies
- **Custom policies**: Minimal cost

### Resource Locks & Tags
- **Management operations**: Free

### Automation Account (if added)
- **Basic tier**: $5/month
- **Runbook execution**: $0.002/minute

**Management Total: $100-200/month**

---

## 📈 **USAGE SCENARIOS**

### 🟢 **Development/Testing Environment**
- **Monthly Cost**: ~$1,850
- Light usage patterns
- Auto-pause enabled for Synapse
- Minimal data transfer
- Basic monitoring

### 🟡 **Production/Staging Environment**
- **Monthly Cost**: ~$2,900
- Moderate usage patterns
- Regular Synapse analytics
- Standard data transfer
- Full monitoring suite

### 🔴 **Enterprise Production**
- **Monthly Cost**: ~$4,300+
- High availability requirements
- Heavy analytics workloads
- High data transfer volumes
- Advanced security features
- DDoS Protection Standard

---

## 💡 **COST OPTIMIZATION RECOMMENDATIONS**

### Immediate Savings (10-30% reduction)

1. **Reserved Instances**
   ```
   - SQL Database: 1-year reserved = 38% savings
   - Synapse: 1-year reserved = 38% savings
   - Potential savings: $300-600/month
   ```

2. **Auto-Scaling & Auto-Pause**
   ```
   - Synapse auto-pause: 15 minutes idle
   - Container instances: Scale to zero when not needed
   - Potential savings: $200-400/month
   ```

3. **Storage Tier Optimization**
   ```
   - Move old data to Cool/Archive tiers
   - Implement lifecycle policies
   - Potential savings: $50-150/month
   ```

### Advanced Optimizations (30-50% reduction)

4. **Spot Instances for Development**
   ```
   - Use spot pricing for non-critical workloads
   - Potential savings: $100-300/month
   ```

5. **Right-Sizing Resources**
   ```
   - Monitor actual CPU/memory usage
   - Downsize over-provisioned resources
   - Potential savings: $200-500/month
   ```

6. **Data Compression & Deduplication**
   ```
   - Compress stored data
   - Remove duplicate files
   - Potential savings: $50-200/month
   ```

---

## 🎯 **COST MONITORING SETUP**

### Budget Alerts
```hcl
# Add to your Terraform
resource "azurerm_consumption_budget_resource_group" "budget" {
  name              = "monthly-budget"
  resource_group_id = azurerm_resource_group.dr_rg.id

  amount     = 3000  # Set your budget limit
  time_grain = "Monthly"

  time_period {
    start_date = "2025-01-01T00:00:00Z"
    end_date   = "2026-01-01T00:00:00Z"
  }

  filter {
    dimension {
      name     = "ResourceGroupName"
      operator = "In"
      values   = [azurerm_resource_group.dr_rg.name]
    }
  }

  notification {
    enabled   = true
    threshold = 80
    operator  = "GreaterThan"

    contact_emails = [var.admin_email]
  }

  notification {
    enabled   = true
    threshold = 100
    operator  = "GreaterThan"

    contact_emails = [var.admin_email]
  }
}
```

### Cost Management Tags
```hcl
# Enhanced tagging for cost tracking
tags = {
  Environment   = "DR"
  Project       = "Analytics Platform"
  CostCenter    = "IT-Infrastructure"
  Owner         = "DataTeam"
  BusinessUnit  = "Analytics"
  Application   = "R-Analytics"
  Criticality   = "High"
}
```

---

## 📋 **COST COMPARISON**

### vs AWS Equivalent
| **Service Type** | **Azure Cost** | **AWS Equivalent** | **Difference** |
|------------------|----------------|-------------------|----------------|
| Containers | $292/month | ECS Fargate: ~$350/month | **Azure 20% cheaper** |
| Load Balancer | $320/month | ALB + WAF: ~$280/month | AWS 12% cheaper |
| Storage | $300/month | S3 + EFS: ~$320/month | **Azure 6% cheaper** |
| Analytics | $150/month | Athena: ~$100/month | AWS 33% cheaper |
| **TOTAL** | **$2,900/month** | **$3,200/month** | **Azure 9% cheaper** |

### ROI Analysis
- **DR Infrastructure Cost**: $2,900/month
- **Estimated Downtime Cost Avoided**: $50,000/hour
- **Break-even**: If DR prevents >1 hour downtime/month
- **ROI**: Typically 300-500% for critical analytics platforms

---

## 🚨 **COST ALERTS & THRESHOLDS**

### Immediate Action Required If:
- Monthly spend exceeds $4,000
- Daily spend rate > $150
- Any single resource > 40% of budget
- Synapse costs > $500/month (check for runaway queries)

### Cost Spike Indicators:
- Sudden increase in data transfer costs
- Container instances not auto-scaling down
- Synapse pools not auto-pausing
- Storage growing faster than expected

---

*Cost estimates based on Azure pricing as of January 2025. Use Azure Pricing Calculator for most current pricing. Consider Azure Enterprise Agreement discounts if applicable.*