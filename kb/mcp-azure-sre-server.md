---
layout: default
title: "Model Context Protocol (MCP) with Azure SRE Server"
date: 2024-08-29
tags: [mcp, azure, sre, devops, automation]
categories: [knowledge-base, azure, sre]
---

# Model Context Protocol (MCP) with Azure SRE Server

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Setup and Configuration](#setup-and-configuration)
- [Client Connections](#client-connections)
- [Common Tasks and Examples](#common-tasks-and-examples)
- [Security Best Practices](#security-best-practices)
- [Troubleshooting](#troubleshooting)
- [References](#references)

## Overview

The Model Context Protocol (MCP) is an open-source protocol that enables seamless communication between AI assistants and external data sources. When integrated with Azure SRE (Site Reliability Engineering) workflows, MCP provides a powerful framework for automating operational tasks, monitoring, and incident response.

### Why MCP Matters for SRE Workflows

**Enhanced Automation**: MCP enables AI assistants to directly interact with Azure resources, automating routine SRE tasks such as:
- Resource monitoring and health checks
- Log analysis and troubleshooting
- Automated remediation based on predefined runbooks
- Real-time infrastructure insights

**Improved Incident Response**: During outages or performance issues, MCP allows AI to:
- Quickly gather diagnostic information from multiple Azure services
- Cross-reference telemetry data with historical patterns
- Suggest remediation steps based on similar past incidents
- Execute approved fixes automatically

**Operational Efficiency**: By connecting AI assistants to Azure APIs, teams can:
- Reduce mean time to resolution (MTTR)
- Minimize manual intervention in routine operations
- Standardize troubleshooting procedures
- Maintain consistent operational practices across teams

## Architecture

The MCP Azure SRE server architecture follows a client-server pattern where the MCP client (AI assistant) communicates with the Azure SRE server to access Azure resources and services.

```
┌─────────────────┐    MCP Protocol    ┌──────────────────┐    Azure APIs    ┌─────────────────┐
│   MCP Client    │◄──────────────────►│  Azure SRE       │◄─────────────────►│   Azure Cloud   │
│   (AI Assistant)│                    │  MCP Server      │                   │   Services      │
│                 │                    │                  │                   │                 │
│ • VS Code       │                    │ • Authentication │                   │ • Virtual Machines│
│ • CLI Tools     │                    │ • Resource Mgmt  │                   │ • App Service   │
│ • Custom Apps   │                    │ • Monitoring     │                   │ • Storage       │
│                 │                    │ • Automation     │                   │ • Databases     │
└─────────────────┘                    └──────────────────┘                   │ • Log Analytics │
                                                                               │ • Monitor       │
                                                                               └─────────────────┘
```

### Key Components

1. **MCP Client**: The AI assistant or application that needs to interact with Azure resources
2. **Azure SRE MCP Server**: The middleware that translates MCP requests into Azure API calls
3. **Azure Services**: The target cloud services being managed and monitored

## Prerequisites

### Azure Requirements

**Azure Subscription**: Active Azure subscription with appropriate permissions

**Required Azure Roles**:
- `Reader` - For basic resource information and monitoring data
- `Contributor` - For resource management and configuration changes
- `Monitoring Contributor` - For accessing Azure Monitor and Log Analytics
- Custom roles with specific permissions based on your SRE needs

**Azure Services Setup**:
- Azure Monitor and Log Analytics workspace configured
- Application Insights (if managing applications)
- Azure Key Vault for secure credential storage
- Resource groups organized by environment/application

### Development Environment

**Required Tools**:
```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Node.js and npm (for MCP server)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Python (alternative runtime)
sudo apt-get install python3 python3-pip
```

**SDK Requirements**:
```json
{
  "dependencies": {
    "@azure/identity": "^4.0.0",
    "@azure/arm-resources": "^5.0.0",
    "@azure/arm-monitor": "^8.0.0",
    "@azure/monitor-query": "^1.0.0",
    "@modelcontextprotocol/sdk": "^0.5.0"
  }
}
```

## Setup and Configuration

### Step 1: Install the Azure SRE MCP Server

```bash
# Clone the Azure SRE MCP Server repository
git clone https://github.com/azure/mcp-azure-sre-server.git
cd mcp-azure-sre-server

# Install dependencies
npm install

# Build the server
npm run build
```

### Step 2: Configure Authentication

#### Option A: Managed Identity (Recommended for Azure VMs)

```bash
# Enable system-assigned managed identity on your Azure VM
az vm identity assign --resource-group myResourceGroup --name myVM
```

#### Option B: Service Principal

```bash
# Create a service principal
az ad sp create-for-rbac --name "mcp-azure-sre-sp" \
  --role "Monitoring Reader" \
  --scopes "/subscriptions/{subscription-id}"

# Store the output securely
{
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "displayName": "mcp-azure-sre-sp",
  "password": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

### Step 3: Server Configuration

Create a configuration file `config.json`:

```json
{
  "server": {
    "name": "azure-sre-mcp-server",
    "version": "1.0.0",
    "port": 3000
  },
  "azure": {
    "subscriptionId": "${AZURE_SUBSCRIPTION_ID}",
    "tenantId": "${AZURE_TENANT_ID}",
    "authentication": {
      "type": "managedIdentity", // or "servicePrincipal"
      "clientId": "${AZURE_CLIENT_ID}",      // for service principal
      "clientSecret": "${AZURE_CLIENT_SECRET}" // for service principal
    }
  },
  "monitoring": {
    "logAnalyticsWorkspaceId": "${LOG_ANALYTICS_WORKSPACE_ID}",
    "applicationInsightsConnectionString": "${APPINSIGHTS_CONNECTION_STRING}"
  },
  "security": {
    "enableAuditLogging": true,
    "maxRequestsPerMinute": 100,
    "allowedClients": ["*"] // Restrict in production
  }
}
```

### Step 4: Environment Variables

Create a `.env` file:

```bash
# Azure Configuration
AZURE_SUBSCRIPTION_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_TENANT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_CLIENT_SECRET=your-client-secret

# Monitoring
LOG_ANALYTICS_WORKSPACE_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
APPINSIGHTS_CONNECTION_STRING=InstrumentationKey=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# MCP Server
MCP_SERVER_PORT=3000
MCP_LOG_LEVEL=info
```

### Step 5: Start the Server

```bash
# Start the MCP server
npm start

# Or run in development mode
npm run dev

# Verify server is running
curl http://localhost:3000/health
```

## Client Connections

### VS Code Integration

Install the MCP extension for VS Code:

```bash
# Install the extension
code --install-extension mcp-vscode-extension
```

Configure VS Code settings (`.vscode/settings.json`):

```json
{
  "mcp.servers": [
    {
      "name": "Azure SRE Server",
      "command": "node",
      "args": ["/path/to/azure-sre-mcp-server/dist/index.js"],
      "env": {
        "AZURE_SUBSCRIPTION_ID": "your-subscription-id",
        "AZURE_TENANT_ID": "your-tenant-id"
      }
    }
  ]
}
```

### CLI Client Example

Create a simple CLI client script:

```javascript
// cli-client.js
const { MCPClient } = require('@modelcontextprotocol/sdk');

class AzureSREClient {
  constructor(serverUrl) {
    this.client = new MCPClient(serverUrl);
  }

  async connect() {
    await this.client.connect();
    console.log('Connected to Azure SRE MCP Server');
  }

  async listResources(resourceGroup = null) {
    const result = await this.client.call('azure.resources.list', {
      resourceGroup: resourceGroup
    });
    return result;
  }

  async getVMStatus(resourceGroup, vmName) {
    const result = await this.client.call('azure.vm.status', {
      resourceGroup: resourceGroup,
      vmName: vmName
    });
    return result;
  }

  async queryLogs(query, timeRange = '1h') {
    const result = await this.client.call('azure.logs.query', {
      query: query,
      timeRange: timeRange
    });
    return result;
  }
}

// Usage
async function main() {
  const client = new AzureSREClient('http://localhost:3000');
  await client.connect();
  
  // List all VMs in a resource group
  const vms = await client.listResources('myapp-prod-rg');
  console.log('VMs:', vms);
  
  // Check VM status
  const status = await client.getVMStatus('myapp-prod-rg', 'web-server-01');
  console.log('VM Status:', status);
}

main().catch(console.error);
```

### Python Client Example

```python
# python_client.py
import asyncio
import json
from mcp_client import MCPClient

class AzureSREClient:
    def __init__(self, server_url):
        self.client = MCPClient(server_url)
    
    async def connect(self):
        await self.client.connect()
        print("Connected to Azure SRE MCP Server")
    
    async def get_resource_health(self, resource_id):
        result = await self.client.call('azure.resource.health', {
            'resourceId': resource_id
        })
        return result
    
    async def scale_app_service(self, resource_group, app_name, instance_count):
        result = await self.client.call('azure.appservice.scale', {
            'resourceGroup': resource_group,
            'appName': app_name,
            'instanceCount': instance_count
        })
        return result

async def main():
    client = AzureSREClient('http://localhost:3000')
    await client.connect()
    
    # Check application health
    health = await client.get_resource_health('/subscriptions/.../myapp')
    print(f"App Health: {health}")
    
    # Scale application based on metrics
    if health['metrics']['cpu_usage'] > 80:
        await client.scale_app_service('myapp-rg', 'myapp', 3)
        print("Scaled up application due to high CPU usage")

if __name__ == "__main__":
    asyncio.run(main())
```

## Common Tasks and Examples

### 1. Resource Inventory and Monitoring

```javascript
// Get comprehensive resource inventory
async function getResourceInventory() {
  const resources = await client.call('azure.resources.inventory', {
    subscriptionId: 'your-subscription-id',
    includeMetrics: true,
    includeTags: true
  });
  
  return resources.map(resource => ({
    name: resource.name,
    type: resource.type,
    status: resource.status,
    location: resource.location,
    tags: resource.tags,
    metrics: resource.metrics
  }));
}
```

### 2. Performance Diagnostics

```javascript
// Analyze application performance issues
async function diagnosePerformanceIssue(appName, timeRange = '24h') {
  const diagnostics = await client.call('azure.diagnostics.performance', {
    applicationName: appName,
    timeRange: timeRange,
    includeMetrics: ['cpu', 'memory', 'requests', 'errors']
  });
  
  const issues = [];
  
  if (diagnostics.cpu.average > 80) {
    issues.push({
      type: 'High CPU Usage',
      severity: 'critical',
      value: diagnostics.cpu.average,
      recommendation: 'Consider scaling up or optimizing code'
    });
  }
  
  if (diagnostics.errors.rate > 5) {
    issues.push({
      type: 'High Error Rate',
      severity: 'warning',
      value: diagnostics.errors.rate,
      recommendation: 'Review application logs for error patterns'
    });
  }
  
  return issues;
}
```

### 3. Automated Remediation Runbooks

```javascript
// Automated response to high memory usage
async function handleHighMemoryUsage(resourceGroup, vmName) {
  console.log(`Investigating high memory usage on ${vmName}`);
  
  // Step 1: Get current metrics
  const metrics = await client.call('azure.vm.metrics', {
    resourceGroup: resourceGroup,
    vmName: vmName,
    timeRange: '1h'
  });
  
  if (metrics.memory.average > 90) {
    console.log('Memory usage is critically high');
    
    // Step 2: Check for memory leaks in processes
    const processes = await client.call('azure.vm.processes', {
      resourceGroup: resourceGroup,
      vmName: vmName,
      sortBy: 'memory'
    });
    
    // Step 3: Identify problematic processes
    const highMemoryProcesses = processes.filter(p => p.memoryPercent > 20);
    
    if (highMemoryProcesses.length > 0) {
      console.log('Found high memory processes:', highMemoryProcesses);
      
      // Step 4: Restart services if they're known applications
      for (const process of highMemoryProcesses) {
        if (process.name.includes('myapp')) {
          await client.call('azure.vm.restart_service', {
            resourceGroup: resourceGroup,
            vmName: vmName,
            serviceName: process.name
          });
          console.log(`Restarted service: ${process.name}`);
        }
      }
    }
    
    // Step 5: Scale up if still problematic
    const updatedMetrics = await client.call('azure.vm.metrics', {
      resourceGroup: resourceGroup,
      vmName: vmName,
      timeRange: '5m'
    });
    
    if (updatedMetrics.memory.average > 85) {
      await client.call('azure.vm.scale_up', {
        resourceGroup: resourceGroup,
        vmName: vmName,
        newSize: 'Standard_D4s_v3'
      });
      console.log('Scaled up VM due to persistent high memory usage');
    }
  }
}
```

### 4. Log Analysis and Alerting

```javascript
// Advanced log analysis for error patterns
async function analyzeApplicationLogs(appName, timeRange = '4h') {
  const logQuery = `
    AppTraces
    | where TimeGenerated > ago(${timeRange})
    | where AppRoleName == "${appName}"
    | where SeverityLevel >= 3
    | summarize ErrorCount = count() by bin(TimeGenerated, 5m), Message
    | order by TimeGenerated desc
  `;
  
  const logs = await client.call('azure.logs.query', {
    query: logQuery,
    workspace: 'your-log-analytics-workspace'
  });
  
  // Analyze error patterns
  const errorPatterns = logs.reduce((patterns, log) => {
    const pattern = log.Message.split(' ').slice(0, 5).join(' ');
    patterns[pattern] = (patterns[pattern] || 0) + log.ErrorCount;
    return patterns;
  }, {});
  
  // Create alerts for new error patterns
  const knownPatterns = await getKnownErrorPatterns();
  const newPatterns = Object.keys(errorPatterns).filter(
    pattern => !knownPatterns.includes(pattern) && errorPatterns[pattern] > 10
  );
  
  if (newPatterns.length > 0) {
    await client.call('azure.alerts.create', {
      alertName: `New Error Pattern - ${appName}`,
      description: `Detected new error patterns: ${newPatterns.join(', ')}`,
      severity: 'warning',
      resourceId: `/subscriptions/.../resourceGroups/.../providers/Microsoft.Web/sites/${appName}`
    });
  }
  
  return {
    totalErrors: Object.values(errorPatterns).reduce((a, b) => a + b, 0),
    patterns: errorPatterns,
    newPatterns: newPatterns
  };
}
```

### 5. Infrastructure Health Dashboard

```javascript
// Create a real-time infrastructure health summary
async function getInfrastructureHealth() {
  const health = {
    timestamp: new Date().toISOString(),
    overall: 'healthy',
    services: {}
  };
  
  // Check App Services
  const appServices = await client.call('azure.appservices.list', {});
  for (const app of appServices) {
    const appHealth = await client.call('azure.appservice.health', {
      resourceGroup: app.resourceGroup,
      name: app.name
    });
    
    health.services[app.name] = {
      type: 'App Service',
      status: appHealth.status,
      responseTime: appHealth.responseTime,
      availability: appHealth.availability,
      errors: appHealth.errorRate
    };
    
    if (appHealth.status !== 'healthy') {
      health.overall = 'degraded';
    }
  }
  
  // Check Virtual Machines
  const vms = await client.call('azure.vms.list', {});
  for (const vm of vms) {
    const vmHealth = await client.call('azure.vm.health', {
      resourceGroup: vm.resourceGroup,
      name: vm.name
    });
    
    health.services[vm.name] = {
      type: 'Virtual Machine',
      status: vmHealth.powerState,
      cpu: vmHealth.metrics.cpu,
      memory: vmHealth.metrics.memory,
      disk: vmHealth.metrics.disk
    };
  }
  
  // Check Storage Accounts
  const storageAccounts = await client.call('azure.storage.list', {});
  for (const storage of storageAccounts) {
    const storageHealth = await client.call('azure.storage.health', {
      resourceGroup: storage.resourceGroup,
      accountName: storage.name
    });
    
    health.services[storage.name] = {
      type: 'Storage Account',
      status: storageHealth.status,
      availability: storageHealth.availability,
      throughput: storageHealth.throughput
    };
  }
  
  return health;
}
```

## Security Best Practices

### Authentication and Authorization

**Use Managed Identity Where Possible**:
```javascript
// Preferred: Managed Identity configuration
const credential = new DefaultAzureCredential();

// Less preferred: Service Principal (when Managed Identity isn't available)
const credential = new ClientSecretCredential(
  process.env.AZURE_TENANT_ID,
  process.env.AZURE_CLIENT_ID,
  process.env.AZURE_CLIENT_SECRET
);
```

**Implement Least Privilege Access**:
```json
{
  "roleDefinition": {
    "roleName": "MCP Azure SRE Reader",
    "description": "Minimal permissions for MCP Azure SRE operations",
    "permissions": [
      {
        "actions": [
          "Microsoft.Resources/subscriptions/resourceGroups/read",
          "Microsoft.Compute/virtualMachines/read",
          "Microsoft.Compute/virtualMachines/instanceView/read",
          "Microsoft.Web/sites/read",
          "Microsoft.Insights/metrics/read",
          "Microsoft.OperationalInsights/workspaces/query/action"
        ],
        "notActions": [
          "Microsoft.Resources/subscriptions/resourceGroups/delete",
          "Microsoft.Compute/virtualMachines/delete",
          "Microsoft.Web/sites/delete"
        ]
      }
    ]
  }
}
```

### Secure Configuration Management

**Use Azure Key Vault for Secrets**:
```javascript
const { SecretClient } = require('@azure/keyvault-secrets');
const { DefaultAzureCredential } = require('@azure/identity');

class SecureConfig {
  constructor(keyVaultUrl) {
    this.credential = new DefaultAzureCredential();
    this.secretClient = new SecretClient(keyVaultUrl, this.credential);
  }
  
  async getSecret(secretName) {
    try {
      const secret = await this.secretClient.getSecret(secretName);
      return secret.value;
    } catch (error) {
      console.error(`Failed to retrieve secret ${secretName}:`, error);
      throw error;
    }
  }
}

// Usage
const config = new SecureConfig('https://your-keyvault.vault.azure.net/');
const dbPassword = await config.getSecret('database-password');
```

**Network Security**:
```json
{
  "networkSecurity": {
    "allowedIPs": ["10.0.0.0/8", "192.168.0.0/16"],
    "requireHTTPS": true,
    "enableCORS": false,
    "rateLimiting": {
      "requestsPerMinute": 100,
      "burstLimit": 20
    }
  }
}
```

### Audit Logging

```javascript
// Comprehensive audit logging
class AuditLogger {
  constructor(logAnalyticsClient) {
    this.logAnalytics = logAnalyticsClient;
  }
  
  async logMCPOperation(operation, user, resource, result) {
    const auditEvent = {
      timestamp: new Date().toISOString(),
      operation: operation,
      user: user,
      resource: resource,
      result: result.success ? 'success' : 'failure',
      errorMessage: result.error || null,
      sourceIP: result.sourceIP,
      userAgent: result.userAgent
    };
    
    await this.logAnalytics.send('MCPAuditLogs', auditEvent);
  }
}

// Use in MCP server middleware
app.use((req, res, next) => {
  req.startTime = Date.now();
  next();
});

app.use((req, res, next) => {
  res.on('finish', async () => {
    await auditLogger.logMCPOperation(
      req.body.method,
      req.user,
      req.body.params?.resourceId,
      {
        success: res.statusCode < 400,
        error: res.statusCode >= 400 ? res.statusMessage : null,
        sourceIP: req.ip,
        userAgent: req.get('User-Agent'),
        duration: Date.now() - req.startTime
      }
    );
  });
  next();
});
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Authentication Failures

**Issue**: `401 Unauthorized` errors when calling Azure APIs

**Diagnosis**:
```bash
# Check if Azure CLI is authenticated
az account show

# Test service principal authentication
az login --service-principal \
  --username $AZURE_CLIENT_ID \
  --password $AZURE_CLIENT_SECRET \
  --tenant $AZURE_TENANT_ID
```

**Solutions**:
- Verify credentials are correct and not expired
- Ensure service principal has necessary permissions
- Check if multi-factor authentication is required
- Validate tenant ID and subscription ID

#### 2. Permission Denied Errors

**Issue**: `403 Forbidden` errors for specific operations

**Diagnosis**:
```javascript
// Check current user permissions
async function checkPermissions(resourceId) {
  const permissions = await client.call('azure.auth.permissions', {
    resourceId: resourceId
  });
  console.log('Current permissions:', permissions);
}
```

**Solutions**:
- Review and assign necessary Azure RBAC roles
- Use Azure CLI to check role assignments:
  ```bash
  az role assignment list --assignee $AZURE_CLIENT_ID
  ```
- Implement least-privilege principle correctly

#### 3. Connection Timeouts

**Issue**: MCP client timeouts when connecting to server

**Diagnosis**:
```javascript
// Add connection monitoring
const client = new MCPClient('http://localhost:3000', {
  timeout: 30000,
  retries: 3,
  retryDelay: 1000
});

client.on('connect', () => console.log('Connected'));
client.on('disconnect', () => console.log('Disconnected'));
client.on('error', (error) => console.error('Connection error:', error));
```

**Solutions**:
- Check network connectivity and firewall rules
- Verify MCP server is running and listening on correct port
- Increase timeout values for slow operations
- Implement connection retry logic

#### 4. Resource Not Found Errors

**Issue**: Azure resources return 404 Not Found

**Diagnosis**:
```javascript
// Validate resource existence
async function validateResource(resourceGroup, resourceName, resourceType) {
  try {
    const resource = await client.call('azure.resource.get', {
      resourceGroup: resourceGroup,
      resourceName: resourceName,
      resourceType: resourceType
    });
    return resource;
  } catch (error) {
    if (error.statusCode === 404) {
      console.log(`Resource not found: ${resourceName} in ${resourceGroup}`);
      return null;
    }
    throw error;
  }
}
```

**Solutions**:
- Verify resource names and resource group names
- Check if resources have been moved or deleted
- Ensure correct subscription context
- Validate resource type specifications

#### 5. High Memory Usage in MCP Server

**Issue**: MCP server consuming excessive memory

**Diagnosis**:
```bash
# Monitor server memory usage
ps aux | grep mcp-server
top -p $(pgrep -f mcp-server)

# Check Node.js heap usage
node --inspect server.js
# Connect to Chrome DevTools for memory profiling
```

**Solutions**:
- Implement connection pooling for Azure clients
- Add memory limits and garbage collection tuning
- Cache frequently accessed data with TTL
- Use streaming for large data responses

### Error Codes Reference

| Error Code | Description | Common Causes | Solution |
|------------|-------------|---------------|----------|
| AUTH001 | Authentication failed | Invalid credentials | Verify service principal/managed identity |
| AUTH002 | Token expired | Credential refresh needed | Implement token refresh logic |
| PERM001 | Insufficient permissions | Missing RBAC roles | Assign required Azure roles |
| CONN001 | Connection timeout | Network issues | Check connectivity and increase timeout |
| RATE001 | Rate limit exceeded | Too many requests | Implement rate limiting and backoff |
| RSRC001 | Resource not found | Invalid resource reference | Verify resource names and subscription |

### Debugging Tools

**Enable Debug Logging**:
```bash
# Set environment variable for detailed logging
export DEBUG=mcp:*,azure:*
export MCP_LOG_LEVEL=debug

# Run server with debug output
npm start
```

**Health Check Endpoint**:
```javascript
// Add comprehensive health check
app.get('/health', async (req, res) => {
  const health = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    checks: {}
  };
  
  try {
    // Test Azure connectivity
    const subscriptions = await azureClient.subscriptions.list();
    health.checks.azure = { status: 'ok', subscriptionCount: subscriptions.length };
  } catch (error) {
    health.checks.azure = { status: 'error', error: error.message };
    health.status = 'error';
  }
  
  try {
    // Test Log Analytics connectivity
    const query = 'Heartbeat | limit 1';
    await logAnalyticsClient.query(query);
    health.checks.logAnalytics = { status: 'ok' };
  } catch (error) {
    health.checks.logAnalytics = { status: 'error', error: error.message };
    health.status = 'error';
  }
  
  res.status(health.status === 'ok' ? 200 : 503).json(health);
});
```

## References

### Official Documentation
- [Model Context Protocol Specification](https://modelcontextprotocol.io/introduction)
- [Azure REST API Reference](https://docs.microsoft.com/en-us/rest/api/azure/)
- [Azure Monitor REST API](https://docs.microsoft.com/en-us/rest/api/monitor/)
- [Azure Resource Manager Templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/)

### Azure SDKs and Libraries
- [Azure SDK for JavaScript](https://github.com/Azure/azure-sdk-for-js)
- [Azure SDK for Python](https://github.com/Azure/azure-sdk-for-python)
- [Azure Identity Library](https://docs.microsoft.com/en-us/javascript/api/@azure/identity/)
- [Azure Monitor Query Library](https://docs.microsoft.com/en-us/javascript/api/@azure/monitor-query/)

### MCP Resources
- [MCP SDK Documentation](https://github.com/modelcontextprotocol/sdk)
- [MCP Client Examples](https://github.com/modelcontextprotocol/examples)
- [MCP Server Development Guide](https://modelcontextprotocol.io/docs/server-development)

### Sample Code and Templates
- [Azure MCP Server Template](https://github.com/azure-samples/mcp-azure-server)
- [SRE Automation Scripts](https://github.com/azure-samples/sre-automation)
- [Azure Monitoring Queries](https://github.com/MicrosoftDocs/azure-docs/tree/master/articles/azure-monitor/logs/queries)

### Community Resources
- [Azure SRE Community](https://techcommunity.microsoft.com/t5/azure-architecture-blog/bg-p/AzureArchitectureBlog)
- [MCP Community Forum](https://community.modelcontextprotocol.io/)
- [Azure DevOps Best Practices](https://docs.microsoft.com/en-us/azure/devops/learn/)

---

*This article was last updated on August 29, 2024. For the most current information, please refer to the official documentation links provided above.*