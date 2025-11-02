# n8n on Raspberry Pi with PostgreSQL

This repository contains a Docker Compose setup to run n8n workflow automation on a Raspberry Pi with PostgreSQL as the database backend.

## Prerequisites

### Hardware Requirements
- Raspberry Pi 4 (4GB RAM minimum, 8GB recommended)
- 32GB+ SD card (64GB+ recommended)
- Stable power supply

### Software Requirements
- Raspberry Pi OS (64-bit recommended) or compatible Linux distribution
- Docker installed
- Docker Compose installed

## Installation

### 1. Install Docker

On Raspberry Pi OS, run:

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

### 2. Add User to Docker Group

```bash
sudo usermod -aG docker $USER
newgrp docker
```

### 3. Install Docker Compose

Docker Compose is usually included with modern Docker installations. Verify with:

```bash
docker compose version
```

If not installed:

```bash
sudo apt-get update
sudo apt-get install docker-compose-plugin
```

### 4. Clone or Copy This Repository

```bash
cd /home/pi
git clone <repository-url> n8n-setup
cd n8n-setup
```

Or copy the files to your desired directory.

### 5. Configure Environment Variables

Copy the example environment file:

```bash
cp env.example .env
```

Edit `.env` and set the following required values:

1. **POSTGRES_PASSWORD**: Set a strong password for PostgreSQL
2. **N8N_BASIC_AUTH_PASSWORD**: Set a password for n8n web interface access
3. **N8N_ENCRYPTION_KEY**: Generate a strong encryption key (minimum 32 characters)

Generate an encryption key:

```bash
openssl rand -hex 32
```

Update `WEBHOOK_URL` if you plan to access n8n from other devices on your network:

```bash
# Replace with your Raspberry Pi's IP address
WEBHOOK_URL=http://192.168.1.100:5678
```

### 6. Start the Services

```bash
docker compose up -d
```

This will:
- Pull the required Docker images (ARM-compatible versions)
- Create network and volumes
- Start PostgreSQL database
- Start n8n application

### 7. Verify Installation

Check that containers are running:

```bash
docker compose ps
```

Check logs:

```bash
docker compose logs -f
```

### 8. Access n8n

Open your web browser and navigate to:

```
http://localhost:5678
```

Or if accessing from another device on your network:

```
http://<raspberry-pi-ip>:5678
```

Login with the credentials set in `.env`:
- Username: Value of `N8N_BASIC_AUTH_USER` (default: `admin`)
- Password: Value of `N8N_BASIC_AUTH_PASSWORD`

## ngrok Setup (Expose n8n to Internet)

ngrok allows you to expose your n8n instance to the internet, enabling external webhook access and remote management.

### Prerequisites

1. **Create ngrok Account**: Sign up at [https://ngrok.com](https://ngrok.com) (free tier available)
2. **Get Auth Token**: 
   - Go to [https://dashboard.ngrok.com/get-started/your-authtoken](https://dashboard.ngrok.com/get-started/your-authtoken)
   - Copy your authtoken

### Configuration

1. **Add ngrok Token to `.env`**:
   ```bash
   NGROK_AUTHTOKEN=your_ngrok_auth_token_here
   ```

2. **Optional Settings** (in `.env`):
   ```bash
   # Static domain (requires paid ngrok plan)
   NGROK_DOMAIN=your-static-domain.ngrok-free.app
   
   # Region selection (us, eu, ap, au, sa, jp, in)
   NGROK_REGION=us
   
   # ngrok web interface port
   NGROK_WEB_PORT=4040
   ```

### Start ngrok Service

Start all services including ngrok:

```bash
# Start with ngrok profile
docker compose --profile ngrok up -d

# Or start normally, then start ngrok separately
docker compose up -d
docker compose --profile ngrok up -d ngrok
```

### Get Your Public URL

**Option 1: ngrok Dashboard (Recommended)**
- Access the ngrok dashboard: `http://localhost:4040`
- Find your public HTTPS URL (e.g., `https://abc123.ngrok-free.app`)

**Option 2: ngrok API**
```bash
curl http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url'
```

**Option 3: ngrok Logs**
```bash
docker compose logs ngrok
```

### Update Webhook URL

After getting your ngrok URL, update `WEBHOOK_URL` in `.env`:

```bash
# For free tier (URL changes on restart)
WEBHOOK_URL=https://abc123.ngrok-free.app

# For paid tier with static domain
WEBHOOK_URL=https://your-static-domain.ngrok-free.app
```

Then restart n8n to apply the change:

```bash
docker compose restart n8n
```

### Access n8n via ngrok

You can now access n8n from anywhere:

```
https://your-ngrok-url.ngrok-free.app
```

**Note**: ngrok free tier shows an interstitial warning page on first access. Users need to click "Visit Site" to proceed.

### ngrok Management

**View ngrok Status**:
```bash
docker compose ps ngrok
docker compose logs ngrok
```

**Stop ngrok**:
```bash
docker compose --profile ngrok stop ngrok
```

**Restart ngrok**:
```bash
docker compose --profile ngrok restart ngrok
```

### Troubleshooting ngrok

**ngrok not starting**:
- Verify `NGROK_AUTHTOKEN` is set correctly in `.env`
- Check logs: `docker compose logs ngrok`
- Ensure n8n service is running: `docker compose ps n8n`

**Can't access ngrok URL**:
- Verify ngrok is running: `docker compose ps ngrok`
- Check ngrok dashboard for errors: `http://localhost:4040`
- Ensure firewall allows outbound connections

**URL changes on restart (Free Tier)**:
- This is normal for ngrok free tier
- Consider upgrading to paid plan for static domains
- Or use ngrok API to dynamically update webhook URLs

## Management Commands

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f n8n
docker compose logs -f postgres
```

### Stop Services

```bash
docker compose stop
```

### Start Services

```bash
docker compose start
```

### Restart Services

```bash
docker compose restart
```

### Stop and Remove Containers (keeps data)

```bash
docker compose down
```

### Stop and Remove Everything Including Volumes (⚠️ deletes all data)

```bash
docker compose down -v
```

### Update n8n to Latest Version

```bash
docker compose pull n8n
docker compose up -d
```

## Backup

### Backup PostgreSQL Database

```bash
docker compose exec postgres pg_dump -U n8n n8n > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Backup n8n Data Volume

```bash
docker run --rm \
  -v n8n-setup_n8n_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/n8n_data_backup_$(date +%Y%m%d_%H%M%S).tar.gz /data
```

### Automated Backup Script

Create a backup script:

```bash
#!/bin/bash
BACKUP_DIR="/home/pi/backups/n8n"
mkdir -p "$BACKUP_DIR"

# Database backup
docker compose exec -T postgres pg_dump -U n8n n8n | gzip > "$BACKUP_DIR/db_$(date +%Y%m%d_%H%M%S).sql.gz"

# Data volume backup
docker run --rm \
  -v n8n-setup_n8n_data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf "/backup/n8n_data_$(date +%Y%m%d_%H%M%S).tar.gz" /data

# Keep only last 7 days
find "$BACKUP_DIR" -name "*.gz" -mtime +7 -delete
```

Make it executable and add to cron:

```bash
chmod +x backup.sh
crontab -e
# Add: 0 2 * * * /home/pi/n8n-setup/backup.sh
```

## Restore

### Restore PostgreSQL Database

```bash
cat backup_YYYYMMDD_HHMMSS.sql | docker compose exec -T postgres psql -U n8n n8n
```

### Restore n8n Data Volume

```bash
docker run --rm \
  -v n8n-setup_n8n_data:/data \
  -v $(pwd):/backup \
  alpine sh -c "cd / && tar xzf /backup/n8n_data_backup_YYYYMMDD_HHMMSS.tar.gz"
```

## Troubleshooting

### Check Container Status

```bash
docker compose ps
```

### Check Container Logs

```bash
docker compose logs n8n
docker compose logs postgres
docker compose logs ngrok
```

### Check Disk Space

```bash
df -h
docker system df
```

### Restart Services

```bash
docker compose restart
```

### Reset n8n (keeps database)

```bash
docker compose stop n8n
docker compose rm -f n8n
docker compose up -d n8n
```

### Performance Issues

1. Check memory usage: `free -h`
2. Check CPU: `htop`
3. Reduce PostgreSQL connections if needed
4. Consider limiting n8n execution concurrency

### Database Connection Issues

1. Verify PostgreSQL is healthy: `docker compose ps postgres`
2. Check logs: `docker compose logs postgres`
3. Verify credentials in `.env`
4. Test connection manually:
   ```bash
   docker compose exec postgres psql -U n8n -d n8n
   ```

## Security Considerations

1. **Change Default Passwords**: Always use strong passwords in `.env`
2. **Generate Encryption Key**: Use a strong, randomly generated encryption key
3. **Firewall**: If exposing to network, configure firewall:
   ```bash
   sudo ufw allow 5678/tcp
   ```
4. **HTTPS**: For production, use a reverse proxy (nginx/traefik) with SSL certificates
5. **Backups**: Regular backups protect against data loss
6. **Updates**: Keep Docker images updated regularly

## Optional: Reverse Proxy with HTTPS

For production use, consider setting up nginx or traefik as a reverse proxy with SSL certificates (Let's Encrypt).

## Resources

- [n8n Documentation](https://docs.n8n.io/)
- [n8n GitHub](https://github.com/n8n-io/n8n)
- [Docker Documentation](https://docs.docker.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## License

This setup is provided as-is. Please refer to n8n's license for usage terms.

