#!/bin/bash

# n8n Raspberry Pi Setup Script
# This script helps set up n8n with PostgreSQL on Raspberry Pi

set -e

echo "========================================="
echo "n8n on Raspberry Pi Setup"
echo "========================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed."
    echo "Please install Docker first:"
    echo "  curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh"
    exit 1
fi

echo "✅ Docker is installed"

# Check if Docker Compose is available
if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not installed."
    echo "Please install Docker Compose plugin first."
    exit 1
fi

echo "✅ Docker Compose is installed"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp env.example .env
    echo "✅ Created .env file"
    echo ""
    echo "⚠️  IMPORTANT: Please edit .env and set:"
    echo "   1. POSTGRES_PASSWORD (strong password)"
    echo "   2. N8N_BASIC_AUTH_PASSWORD (admin password)"
    echo "   3. N8N_ENCRYPTION_KEY (generate with: openssl rand -hex 32)"
    echo ""
    read -p "Press Enter after you've edited .env file..."
else
    echo "✅ .env file already exists"
fi

# Generate encryption key if not set
if grep -q "your_encryption_key_here" .env; then
    echo "🔑 Generating encryption key..."
    ENCRYPTION_KEY=$(openssl rand -hex 32)
    # For macOS compatibility
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/N8N_ENCRYPTION_KEY=.*/N8N_ENCRYPTION_KEY=$ENCRYPTION_KEY/" .env
    else
        sed -i "s/N8N_ENCRYPTION_KEY=.*/N8N_ENCRYPTION_KEY=$ENCRYPTION_KEY/" .env
    fi
    echo "✅ Encryption key generated and set"
fi

# Check for default passwords
if grep -q "your_secure_password_here\|your_admin_password_here" .env; then
    echo ""
    echo "⚠️  WARNING: Default passwords detected in .env file!"
    echo "Please update the following in .env:"
    grep -E "POSTGRES_PASSWORD|N8N_BASIC_AUTH_PASSWORD" .env | grep -v "^#"
    echo ""
    read -p "Have you updated the passwords? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Please update .env file with secure passwords and run this script again."
        exit 1
    fi
fi

echo ""
echo "🚀 Starting Docker Compose services..."
echo ""

# Pull images
echo "📥 Pulling Docker images (this may take a while)..."
docker compose pull

# Start services
echo "🏃 Starting services..."
docker compose up -d

echo ""
echo "⏳ Waiting for services to be ready (this may take 30-60 seconds)..."
sleep 5

# Wait for PostgreSQL to be healthy
echo "⏳ Waiting for PostgreSQL to be healthy..."
timeout=60
elapsed=0
while ! docker compose ps postgres | grep -q "healthy"; do
    sleep 2
    elapsed=$((elapsed + 2))
    if [ $elapsed -ge $timeout ]; then
        echo "❌ Timeout waiting for PostgreSQL to be healthy"
        docker compose logs postgres
        exit 1
    fi
done
echo "✅ PostgreSQL is healthy"

# Wait for n8n to start
echo "⏳ Waiting for n8n to start..."
sleep 10

# Check n8n status
if docker compose ps n8n | grep -q "Up"; then
    echo "✅ n8n is running"
else
    echo "⚠️  n8n container status:"
    docker compose ps n8n
fi

echo ""
echo "========================================="
echo "✅ Setup Complete!"
echo "========================================="
echo ""
echo "📋 Service Information:"
echo "   - PostgreSQL: Running in container 'n8n_postgres'"
echo "   - n8n: Running in container 'n8n_app'"
echo ""
echo "🌐 Access n8n at:"
echo "   http://localhost:5678"
echo ""
echo "   Or from another device on your network:"
IP=$(hostname -I | awk '{print $1}')
echo "   http://${IP}:5678"
echo ""
echo "📝 Login credentials (from .env):"
echo "   Username: $(grep N8N_BASIC_AUTH_USER .env | cut -d '=' -f2)"
echo "   Password: [Set in .env file]"
echo ""
echo "🔧 Useful commands:"
echo "   View logs:      docker compose logs -f"
echo "   Stop services:  docker compose stop"
echo "   Start services: docker compose start"
echo "   Restart:        docker compose restart"
echo "   Check status:   docker compose ps"
echo ""
echo "📚 See README.md for more information"
echo ""

