# ERPNext Custom App - Complete Workflow

## 📁 Project Structure

```
erpnext-custom/
├── apps/
│   └── custom_app/              # Your custom app (tracked in git)
│       ├── custom_app/
│       ├── setup.py
│       └── ...
├── docker-compose.yml           # Production config (tracked in git)
├── docker-compose.override.yml  # Local dev config (NOT in git)
├── Dockerfile                   # Build config (tracked in git)
├── .env                         # Local env vars (NOT in git)
├── .env.example                 # Template (tracked in git)
└── .gitignore                   # Git ignore rules (tracked in git)
```

---

## 🖥️ Local Development Workflow

### Initial Setup

```bash
# 1. Clone the repository
git clone <your-repo-url>
cd erpnext-custom

# 2. Create local environment file
cp .env.example .env

# Edit .env with local settings:
# DB_HOST=db
# DB_ROOT_PASSWORD=admin
# ADMIN_PASSWORD=admin

# 3. Start all services (includes local database)
docker-compose up -d

# Wait for services to be ready (first time takes 5-10 minutes)
docker-compose logs -f create-site

# 4. Access ERPNext
# http://localhost:8080
# Username: Administrator
# Password: admin (or what you set in .env)
```

### Daily Development

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f backend

# Make changes to your custom app
cd apps/custom_app
# Edit files...

# The changes are live! Just refresh browser
# For Python changes, restart backend:
docker-compose restart backend

# Run migrations after doctype changes
docker-compose exec backend bench --site frontend migrate

# Clear cache
docker-compose exec backend bench --site frontend clear-cache

# Stop services
docker-compose down
```

### Common Development Commands

```bash
# Access backend container shell
docker-compose exec backend bash

# Inside container:
bench --site frontend console    # Open Python console
bench --site frontend migrate    # Run migrations
bench --site frontend list-apps  # List installed apps

# View real-time logs
docker-compose logs -f backend
docker-compose logs -f queue-default
docker-compose logs -f scheduler

# Restart specific service
docker-compose restart backend
docker-compose restart queue-default

# Rebuild after Dockerfile changes
docker-compose build
docker-compose up -d
```

### Exporting Customizations

```bash
# After making customizations in ERPNext UI
docker-compose exec backend bash

# Inside container:
cd apps/custom_app
bench --site frontend export-fixtures

# Check what was exported
git status

# Commit changes
git add custom_app/fixtures/
git commit -m "Export customizations"
git push origin main
```

---

## ☁️ Coolify Deployment Workflow

### First-Time Coolify Setup

#### Step 1: Deploy Database (Separate App)

1. In Coolify: **New Resource** → **Docker Compose**
2. Name: `erpnext-database`
3. Create `docker-compose.yml`:

```yaml
version: "3"
services:
  mariadb:
    image: mariadb:10.6
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
      MYSQL_DATABASE: erpnext
    volumes:
      - db-data:/var/lib/mysql
    command:
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_unicode_ci
    networks:
      - coolify
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 30s

volumes:
  db-data:

networks:
  coolify:
    external: true
```

4. Environment Variables:
   - `DB_ROOT_PASSWORD`: (strong password)
5. Deploy
6. **Note the container name** (e.g., `erpnext-database-mariadb-1`)

#### Step 2: Deploy ERPNext Application

1. In Coolify: **New Resource** → **Docker Compose**
2. Name: `erpnext-app`
3. Source: Connect GitHub Repository
4. Branch: `main`
5. Build Type: **Docker Compose**
6. Docker Compose File: `/docker-compose.yml`

7. Environment Variables in Coolify:
```
DB_HOST=erpnext-database-mariadb-1  # ← From Step 1
DB_ROOT_PASSWORD=<same-as-database>
ADMIN_PASSWORD=<your-admin-password>
```

8. Domain Settings:
   - Add your domain
   - Enable SSL

9. Enable Auto-Deploy:
   - ✅ Deploy on Push
   - Branch: `main`

10. Deploy!

### Ongoing Development & Deployment

```bash
# Local: Make changes to custom app
cd apps/custom_app
# ... edit code ...

# Local: Test changes
docker-compose restart backend
# Test in browser at localhost:8080

# Local: Export any UI customizations
docker-compose exec backend bench --site frontend export-fixtures

# Commit and push
git add apps/custom_app/
git commit -m "Add new feature"
git push origin main

# Coolify automatically:
# 1. Detects push via GitHub webhook
# 2. Pulls latest code
# 3. Rebuilds Docker image (with your changes)
# 4. Stops old containers
# 5. Starts new containers
# 6. Runs migrations via install-apps service
# 7. Your changes are LIVE!
```

### Monitoring Deployment in Coolify

1. Go to your ERPNext app in Coolify
2. Click "Deployments" tab
3. View build logs in real-time
4. Check each service status
5. View container logs if issues

---

## 🔄 Git Workflow

### Feature Development

```bash
# Create feature branch
git checkout -b feature/new-doctype

# Make changes locally
cd apps/custom_app
# ... develop ...

# Test locally
docker-compose restart backend

# Export customizations
docker-compose exec backend bench --site frontend export-fixtures

# Commit
git add .
git commit -m "Add new Purchase Request doctype"
git push origin feature/new-doctype

# Create Pull Request on GitHub
# After review, merge to main
# Coolify auto-deploys to production!
```

### Hotfix Workflow

```bash
# For urgent fixes
git checkout -b hotfix/critical-bug

# Fix the issue
# ... edit files ...

# Test locally
docker-compose restart backend

# Deploy quickly
git add .
git commit -m "Fix critical issue in sales flow"
git push origin hotfix/critical-bug

# Merge directly to main for immediate deployment
git checkout main
git merge hotfix/critical-bug
git push origin main

# Coolify deploys within 2-3 minutes
```

---

## 🐛 Troubleshooting

### Local Development Issues

**Problem: Site creation fails**
```bash
# Check database is running
docker-compose ps db

# Check logs
docker-compose logs db
docker-compose logs create-site

# Recreate site
docker-compose down -v  # WARNING: Deletes all data!
docker-compose up -d
```

**Problem: Changes not reflecting**
```bash
# Restart backend
docker-compose restart backend

# Clear cache
docker-compose exec backend bench --site frontend clear-cache

# Check if volume is mounted
docker-compose exec backend ls -la apps/custom_app
```

**Problem: Worker not processing jobs**
```bash
# Check worker logs
docker-compose logs -f queue-default

# Restart workers
docker-compose restart queue-default queue-short queue-long
```

### Coolify Deployment Issues

**Problem: Build failing**
1. Check build logs in Coolify
2. Common issues:
   - Missing environment variables
   - Docker build errors
   - Git clone issues

**Problem: Database connection failed**
```bash
# Check DB_HOST is correct
# It should be: <database-app-name>-mariadb-1

# Check both apps use "coolify" network
# Verify in Coolify: Settings → Networks
```

**Problem: Site already exists error**
- This is normal on redeployments
- The `create-site` service should skip if exists
- Check logs: should say "Site already exists, skipping"

**Problem: Migrations not running**
```bash
# In Coolify, check install-apps service logs
# Should show:
# "Installing custom_app..."
# "Running migrations..."

# If stuck, manually run:
# docker exec <container> bench --site frontend migrate
```

---

## 📊 Key Differences: Local vs Production

| Aspect | Local | Production (Coolify) |
|--------|-------|---------------------|
| **Database** | Local container (override) | Separate Coolify app |
| **Code Mounting** | `./apps` volume mounted | Baked into Docker image |
| **Changes** | Instant (live mount) | Requires git push + rebuild |
| **Ports** | Exposed (8080, 3306, etc.) | Internal only, via proxy |
| **Environment** | `.env` file | Coolify UI variables |
| **Override File** | Used | Ignored (not in git) |
| **Data Persistence** | Named volumes | Coolify-managed volumes |

---

## ✅ Best Practices

### Development
1. Always test locally before pushing
2. Use feature branches for new work
3. Export fixtures after UI customizations
4. Commit with clear messages
5. Never commit `.env` or `docker-compose.override.yml`

### Deployment
1. Use strong passwords in production
2. Monitor Coolify deployment logs
3. Test thoroughly after each deploy
4. Keep separate staging environment
5. Backup database regularly

### Code Organization
1. Keep custom app self-contained
2. Document custom doctypes
3. Use fixtures for customizations
4. Version control everything except secrets
5. Follow Frappe/ERPNext conventions

---

## 🎓 Quick Reference

### Start Everything (Local)
```bash
docker-compose up -d
```

### Stop Everything (Local)
```bash
docker-compose down
```

### Deploy to Production
```bash
git push origin main  # That's it!
```

### View Logs (Local)
```bash
docker-compose logs -f backend
```

### Run Migrations (Local)
```bash
docker-compose exec backend bench --site frontend migrate
```

### Access Database (Local)
```bash
docker-compose exec db mysql -u root -p
```

### Rebuild After Changes (Local)
```bash
docker-compose build
docker-compose up -d
```