# SSM Product Passport and Tracking

This is the installation guide of the Docker Environment.

## Prerequisites

This setup uses pre-built Docker images that need to be loaded before starting the stack:
- `dgraph_v24.1.3.tgz` - Dgraph database image
- `ratel_v24.1.3.tgz` - Ratel UI image

## Quick Start

### Automated Setup (Recommended)

#### Windows:
```bash
./complete-setup.sh
```

#### Linux
```bash
sudo ./complete-setup.sh
```

#### MacOS:
```bash
sh complete-setup.sh
```

This script will:
- Load the required Docker images (only if not already present)
- Start all services
- Initialize the database with schema and data

## Manual Setup Windows Only

If you prefer manual control:

1. **Load Docker images:**
   ```bash
   docker load -i dgraph_v24.1.3.tgz
   docker load -i ratel_v24.1.3.tgz
   docker tag dgraph/ratel:latest dgraph/ratel:v24.1.3
   docker tag dgraph/dgraph:latest dgraph/dgraph:v24.1.3
   ```

2. **Start the services:**
   ```bash
   docker compose up -d
   ```

3. **Initialize database (wait 10 seconds after startup):**
   ```bash
   ./setup-database.sh
   ```

## Access Points

- **Ratel UI:** http://localhost:8000
- **Database API:** http://localhost:8080
- **Health Check:** http://localhost:8080/health

## Alternative Manual Database Setup

If the automated database initialization doesn't work:

1. Go to http://localhost:8000
2. **Schema tab**: Copy/paste contents of `data/schema/schema.graphql`
3. **Mutate tab**: Copy/paste contents of `data/import/data.json`

## Files Structure

```
├── compose.yaml              # Docker setup
├── complete-setup.sh         # One-command automated setup
├── setup-database.sh         # Database initialization only
├── data/
│   ├── schema/               # Predefined schemas
│   └── import/               # Predefined data
└── dgraph/                   # Persistent data (auto-created)
```