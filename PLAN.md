# Plan: Running n8n on Raspberry Pi with PostgreSQL using Docker Compose

## Overview
This plan outlines the setup of n8n workflow automation tool on a Raspberry Pi, using Docker Compose with PostgreSQL as the database backend.

## Architecture Components

### 1. Services Required
- **n8n**: Workflow automation platform (official Docker image)
- **PostgreSQL**: Database for storing n8n workflows, credentials, and execution data

### 2. Raspberry Pi Considerations

#### Hardware Requirements
- **Minimum**: Raspberry Pi 4 with 4GB RAM (8GB recommended)
- **Storage**: At least 32GB SD card (64GB+ recommended for production)
- **Architecture**: ARM64 or ARMv7 (use appropriate Docker images)

#### Resource Constraints
- Limit container memory usage
- Configure PostgreSQL with conservative settings
- Use ARM-compatible Docker images

### 3. Docker Compose Configuration

#### Services:
1. **postgres**:
   - Image: `postgres:15-alpine` (lightweight, ARM-compatible)
   - Persistent volume for data
   - Health checks
   - Custom configuration for Raspberry Pi constraints

2. **n8n**:
   - Image: `n8nio/n8n:latest` (ARM-compatible)
   - Environment variables for database connection
   - Volume for workflow data and credentials
   - Network dependency on PostgreSQL
   - Port mapping for web access

#### Networking:
- Internal Docker network for service communication
- n8n exposed on host port (default 5678)

#### Volumes:
- PostgreSQL data persistence
- n8n data persistence (workflows, credentials, settings)
- Optional: n8n custom nodes directory

### 4. Configuration Steps

#### Step 1: Prerequisites
- [ ] Raspberry Pi OS (64-bit recommended) installed and updated
- [ ] Docker installed (`curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh`)
- [ ] Docker Compose installed (usually included with Docker Desktop, or: `sudo apt-get install docker-compose-plugin`)
- [ ] User added to docker group: `sudo usermod -aG docker $USER`

#### Step 2: File Structure
```
n8n/
├── docker-compose.yml
├── .env
├── .env.example
├── postgres/
│   └── init.sql (optional, for custom DB setup)
└── README.md
```

#### Step 3: Environment Variables
- Database connection credentials
- n8n configuration (timezone, encryption key)
- Security settings (CORS, trusted domains)

#### Step 4: PostgreSQL Setup
- Database name: `n8n`
- User: `n8n` (separate from admin)
- Password: Strong password (via environment variable)
- Character encoding: UTF-8
- Timezone: UTC

#### Step 5: n8n Configuration
- Database type: `postgresdb`
- Connection to PostgreSQL service
- Encryption key for sensitive data
- Timezone configuration
- Webhook URL (if accessing from network)

#### Step 6: Persistence
- PostgreSQL data: `/docker/postgres/data`
- n8n data: `/docker/n8n/data`
- Backup strategy documentation

### 5. Security Considerations
- [ ] Use strong database passwords
- [ ] Set n8n encryption key (generate strong key)
- [ ] Configure firewall rules (if exposing to network)
- [ ] Regular backups of volumes
- [ ] Keep Docker images updated
- [ ] Use HTTPS reverse proxy (optional, for production)

### 6. Performance Optimizations
- PostgreSQL shared_buffers: 256MB (adjust based on RAM)
- PostgreSQL max_connections: 50 (for Raspberry Pi)
- n8n execution timeout: 300s (default)
- Consider disabling unused n8n features

### 7. Maintenance Tasks
- Regular Docker image updates
- Database backups (daily recommended)
- Monitor disk space usage
- Check container logs for issues
- Update Docker Compose file as needed

### 8. Troubleshooting
- Check container logs: `docker-compose logs`
- Verify database connectivity
- Check disk space
- Monitor memory usage
- Review n8n webhook URLs if external access

### 9. Backup Strategy
- PostgreSQL: `pg_dump` or volume backup
- n8n data: Volume backup of `/docker/n8n/data`
- Automated backup script (optional)
- Retention policy (keep last 7-30 days)

### 10. Optional Enhancements
- Reverse proxy (nginx/traefik) for HTTPS
- Automated backup script
- Monitoring (Prometheus/Grafana)
- Health check endpoint
- Auto-restart policies

## Implementation Order
1. Create Docker Compose configuration
2. Create environment variable template
3. Test on Raspberry Pi
4. Verify database persistence
5. Configure n8n settings
6. Set up backup procedure
7. Document access methods
8. Performance testing and tuning

## Estimated Resource Usage
- PostgreSQL: ~200-400MB RAM, ~2GB disk (grows with usage)
- n8n: ~300-500MB RAM, ~1GB disk (grows with workflows)
- **Total**: ~500-900MB RAM, ~3GB+ disk for base installation

## Success Criteria
- [ ] n8n accessible via web interface
- [ ] Workflows can be created and saved
- [ ] Database persists data across container restarts
- [ ] System stable with multiple workflows
- [ ] Backups can be restored

