# Quick Start Guide

## Fast Setup (5 minutes)

1. **Copy environment file:**
   ```bash
   cp env.example .env
   ```

2. **Edit `.env` and set:**
   - `POSTGRES_PASSWORD` (strong password)
   - `N8N_BASIC_AUTH_PASSWORD` (admin password)
   - Generate `N8N_ENCRYPTION_KEY`: `openssl rand -hex 32`

3. **Run setup script:**
   ```bash
   ./setup.sh
   ```

4. **Access n8n:**
   - Open browser: `http://localhost:5678`
   - Or from network: `http://<raspberry-pi-ip>:5678`

## Manual Setup

```bash
# 1. Create .env file
cp env.example .env
# Edit .env with your passwords and encryption key

# 2. Start services
docker compose up -d

# 3. Check status
docker compose ps

# 4. View logs
docker compose logs -f
```

## Essential Commands

| Command | Description |
|---------|-------------|
| `docker compose up -d` | Start all services |
| `docker compose stop` | Stop all services |
| `docker compose restart` | Restart all services |
| `docker compose logs -f` | View logs (follow mode) |
| `docker compose ps` | Check service status |
| `docker compose down` | Stop and remove containers |
| `docker compose pull` | Update images |

## Access URLs

- **Local:** http://localhost:5678
- **Network:** http://<raspberry-pi-ip>:5678

Find your IP: `hostname -I`

## Backup

```bash
# Database backup
docker compose exec postgres pg_dump -U n8n n8n > backup.sql

# Restore
cat backup.sql | docker compose exec -T postgres psql -U n8n n8n
```

## Troubleshooting

**Services won't start:**
```bash
docker compose logs
```

**Check disk space:**
```bash
df -h
docker system df
```

**Reset n8n (keeps database):**
```bash
docker compose restart n8n
```

**Full reset (⚠️ deletes all data):**
```bash
docker compose down -v
```

## File Structure

```
n8n/
├── docker-compose.yml    # Main configuration
├── env.example           # Environment template
├── .env                  # Your configuration (create this)
├── setup.sh             # Automated setup script
├── PLAN.md              # Detailed plan
├── README.md            # Full documentation
└── QUICK_START.md       # This file
```

## Security Checklist

- [ ] Changed `POSTGRES_PASSWORD`
- [ ] Changed `N8N_BASIC_AUTH_PASSWORD`
- [ ] Generated `N8N_ENCRYPTION_KEY` (32+ chars)
- [ ] Updated `WEBHOOK_URL` if accessing from network
- [ ] Firewall configured (if exposing to network)

## Resources

- Full docs: `README.md`
- Detailed plan: `PLAN.md`
- n8n docs: https://docs.n8n.io/

