#!/bin/bash

# Azure MCP SRE Server Quick Setup Script
# This script helps set up the Azure MCP SRE server with necessary prerequisites

set -e

echo "🚀 Azure MCP SRE Server Setup"
echo "============================="

# Check if required tools are installed
check_prerequisites() {
    echo "✓ Checking prerequisites..."
    
    if ! command -v az &> /dev/null; then
        echo "❌ Azure CLI is not installed. Please install it first."
        echo "   Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    
    if ! command -v node &> /dev/null; then
        echo "❌ Node.js is not installed. Please install Node.js 18 or later."
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        echo "❌ npm is not installed. Please install npm."
        exit 1
    fi
    
    echo "✅ All prerequisites are installed."
}

# Login to Azure
azure_login() {
    echo "🔐 Azure Authentication"
    
    if ! az account show &> /dev/null; then
        echo "Please login to Azure..."
        az login
    fi
    
    echo "Current Azure account:"
    az account show --query "{subscriptionId:id, subscriptionName:name, tenantId:tenantId}" -o table
    
    read -p "Is this the correct subscription? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Please set the correct subscription:"
        az account list --query "[].{subscriptionId:id, subscriptionName:name}" -o table
        read -p "Enter subscription ID: " SUBSCRIPTION_ID
        az account set --subscription "$SUBSCRIPTION_ID"
    fi
}

# Create service principal for MCP server
create_service_principal() {
    echo "🔑 Creating Service Principal"
    
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    SP_NAME="mcp-azure-sre-sp-$(date +%s)"
    
    echo "Creating service principal: $SP_NAME"
    SP_DETAILS=$(az ad sp create-for-rbac \
        --name "$SP_NAME" \
        --role "Reader" \
        --scopes "/subscriptions/$SUBSCRIPTION_ID" \
        --query "{appId:appId, password:password, tenant:tenant}" \
        -o json)
    
    CLIENT_ID=$(echo $SP_DETAILS | jq -r .appId)
    CLIENT_SECRET=$(echo $SP_DETAILS | jq -r .password)
    TENANT_ID=$(echo $SP_DETAILS | jq -r .tenant)
    
    echo "✅ Service Principal created successfully!"
    echo "   Client ID: $CLIENT_ID"
    echo "   Tenant ID: $TENANT_ID"
    echo "   🔐 Client Secret: [HIDDEN]"
    
    # Add additional role assignments
    echo "Adding additional role permissions..."
    az role assignment create \
        --assignee "$CLIENT_ID" \
        --role "Monitoring Reader" \
        --scope "/subscriptions/$SUBSCRIPTION_ID"
    
    az role assignment create \
        --assignee "$CLIENT_ID" \
        --role "Log Analytics Reader" \
        --scope "/subscriptions/$SUBSCRIPTION_ID"
}

# Create environment file
create_env_file() {
    echo "📝 Creating environment configuration"
    
    cat > .env << EOF
# Azure Configuration
AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
AZURE_TENANT_ID=$TENANT_ID
AZURE_CLIENT_ID=$CLIENT_ID
AZURE_CLIENT_SECRET=$CLIENT_SECRET

# Monitoring (Update these with your actual resource IDs)
LOG_ANALYTICS_WORKSPACE_ID=your-log-analytics-workspace-id
APPINSIGHTS_CONNECTION_STRING=your-application-insights-connection-string

# MCP Server Configuration
MCP_SERVER_PORT=3000
MCP_LOG_LEVEL=info

# Optional: Redis for caching
REDIS_URL=redis://localhost:6379
EOF
    
    echo "✅ Environment file created: .env"
    echo "📋 Please update the monitoring configuration with your actual resource IDs"
}

# Install MCP server dependencies
install_server() {
    echo "📦 Installing MCP Server"
    
    # Create package.json if it doesn't exist
    if [ ! -f package.json ]; then
        npm init -y
    fi
    
    # Install dependencies
    npm install \
        @azure/identity \
        @azure/arm-resources \
        @azure/arm-monitor \
        @azure/monitor-query \
        @azure/arm-compute \
        @azure/arm-appservice \
        @modelcontextprotocol/sdk \
        express \
        dotenv \
        winston
    
    echo "✅ Dependencies installed successfully!"
}

# Create basic server structure
create_server_structure() {
    echo "🏗️  Creating server structure"
    
    mkdir -p src/{routes,middleware,services,utils}
    mkdir -p config
    mkdir -p logs
    
    # Copy sample configuration
    if [ -f azure-sre-mcp-config.json ]; then
        cp azure-sre-mcp-config.json config/
    fi
    
    echo "✅ Server structure created"
}

# Display next steps
show_next_steps() {
    echo ""
    echo "🎉 Setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Update the .env file with your Log Analytics workspace ID and Application Insights connection string"
    echo "2. Review and customize the configuration in config/azure-sre-mcp-config.json"
    echo "3. Implement your MCP server logic in the src/ directory"
    echo "4. Test the setup by running: npm start"
    echo ""
    echo "For more information, see the knowledge base article:"
    echo "https://github.com/venuvedam/articles/blob/main/kb/mcp-azure-sre-server.md"
    echo ""
    echo "🔐 Important: Keep your .env file secure and never commit it to version control!"
}

# Main execution
main() {
    check_prerequisites
    azure_login
    create_service_principal
    create_env_file
    install_server
    create_server_structure
    show_next_steps
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi