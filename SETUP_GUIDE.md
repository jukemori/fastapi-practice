# Complete Setup Guide - FastAPI Practice Project

This guide will walk you through setting up this full-stack application on a completely fresh computer with nothing installed.

---

## Table of Contents
1. [Prerequisites Installation](#1-prerequisites-installation)
2. [Clone the Repository](#2-clone-the-repository)
3. [Backend Setup](#3-backend-setup)
4. [Frontend Setup](#4-frontend-setup)
5. [Database Setup](#5-database-setup)
6. [Running with Docker](#6-running-with-docker)
7. [Running Locally (Without Docker)](#7-running-locally-without-docker)
8. [Documentation Setup](#8-documentation-setup)
9. [Testing Setup](#9-testing-setup)
10. [AWS Deployment](#10-aws-deployment)
11. [Verification](#11-verification)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. Prerequisites Installation

### 1.1 Install Git
**macOS:**
```bash
# Install Homebrew first (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Git
brew install git
```

**Windows:**
- Download from: https://git-scm.com/download/win
- Run the installer and follow the wizard

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install git -y
```

**Verify:**
```bash
git --version
```

---

### 1.2 Install Python 3.12+
**macOS:**
```bash
brew install python@3.12
```

**Windows:**
- Download from: https://www.python.org/downloads/
- **IMPORTANT:** Check "Add Python to PATH" during installation

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install python3.12 python3.12-venv python3-pip -y
```

**Verify:**
```bash
python3 --version  # Should show 3.12.x
pip3 --version
```

---

### 1.3 Install Node.js 20+ and npm
**macOS:**
```bash
brew install node@20
```

**Windows:**
- Download from: https://nodejs.org/
- Choose LTS version (20.x)
- Run the installer

**Linux (Ubuntu/Debian):**
```bash
# Using NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

**Verify:**
```bash
node --version  # Should show v20.x.x
npm --version
```

---

### 1.4 Install Docker Desktop
**macOS:**
```bash
brew install --cask docker
```
Or download from: https://www.docker.com/products/docker-desktop

**Windows:**
- Download from: https://www.docker.com/products/docker-desktop
- Run the installer
- **Requires:** WSL2 backend (installer will help you set this up)

**Linux (Ubuntu/Debian):**
```bash
# Install Docker Engine
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

# Add your user to docker group (to run without sudo)
sudo usermod -aG docker $USER
newgrp docker
```

**Verify:**
```bash
docker --version
docker compose version
```

**Start Docker Desktop** (macOS/Windows):
- Open Docker Desktop application
- Wait for it to fully start (whale icon in system tray should be steady)

---

### 1.5 Install PostgreSQL Client (Optional - for local development)
**macOS:**
```bash
brew install postgresql@16
```

**Windows:**
- Download from: https://www.postgresql.org/download/windows/
- Or use Docker (recommended)

**Linux (Ubuntu/Debian):**
```bash
sudo apt install postgresql-client-16 -y
```

---

### 1.6 Install Code Editor (Optional but Recommended)
**Visual Studio Code:**
```bash
# macOS
brew install --cask visual-studio-code

# Windows: Download from https://code.visualstudio.com/

# Linux
sudo snap install --classic code
```

---

## 2. Clone the Repository

```bash
# Navigate to where you want to store the project
cd ~/projects  # or any directory you prefer

# Clone the repository (replace with your actual repo URL)
git clone <your-repo-url>
cd fastapi-practice

# Verify you're in the right directory
ls -la
# You should see: backend/, frontend/, deployment/, docs/, docker-compose.yml
```

---

## 3. Backend Setup

### 3.1 Create Python Virtual Environment
```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
# macOS/Linux:
source venv/bin/activate

# Windows (Command Prompt):
venv\Scripts\activate.bat

# Windows (PowerShell):
venv\Scripts\Activate.ps1

# Your prompt should now show (venv)
```

### 3.2 Install Python Dependencies
```bash
# Make sure you're in the backend directory with venv activated
pip install --upgrade pip
pip install -r requirements.txt

# Verify installation
pip list
# Should show FastAPI, uvicorn, SQLAlchemy, etc.
```

### 3.3 Create Environment File
```bash
# Copy the example env file
cp .env.example .env

# Edit .env with your preferred editor
# On macOS/Linux:
nano .env

# On Windows:
notepad .env

# Or use VS Code:
code .env
```

**Update the .env file with these values:**
```env
DATABASE_URL=postgresql://postgres:password@localhost:5432/todoapp
NEO4J_URI=bolt://localhost:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=password
SECRET_KEY=your-super-secret-key-change-this-in-production-min-32-chars
```

**Generate a secure SECRET_KEY:**
```bash
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
# Copy the output and paste it as your SECRET_KEY
```

### 3.4 Verify Backend Installation
```bash
# Check if FastAPI can be imported
python3 -c "import fastapi; print(f'FastAPI version: {fastapi.__version__}')"

# Navigate back to project root
cd ..
```

---

## 4. Frontend Setup

### 4.1 Install Frontend Dependencies
```bash
# Navigate to frontend directory
cd frontend

# Install all npm packages (this may take a few minutes)
npm install

# If you encounter errors, try:
npm install --legacy-peer-deps

# Verify installation
npm list --depth=0
# Should show next, react, react-dom, etc.
```

### 4.2 Create Frontend Environment File (Optional)
```bash
# Create .env.local file
touch .env.local

# Edit the file
# macOS/Linux:
nano .env.local

# Windows:
notepad .env.local
```

**Add this content:**
```env
NEXT_PUBLIC_API_URL=http://localhost:8000
```

### 4.3 Verify Frontend Installation
```bash
# Check Next.js version
npx next --version

# Navigate back to project root
cd ..
```

---

## 5. Database Setup

You have two options: **Docker** (recommended) or **Local Installation**

### Option A: Using Docker (Recommended)

**This is covered in Section 6 - skip to there if using Docker**

### Option B: Local Installation

#### 5.1 Install PostgreSQL Locally

**macOS:**
```bash
brew install postgresql@16
brew services start postgresql@16

# Create database
createdb todoapp

# Create user
psql postgres -c "CREATE USER postgres WITH PASSWORD 'password';"
psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE todoapp TO postgres;"
```

**Windows:**
- Download installer from https://www.postgresql.org/download/windows/
- Run installer and set password to 'password' (or update .env accordingly)
- Open pgAdmin or command line:
```sql
CREATE DATABASE todoapp;
```

**Linux:**
```bash
sudo apt install postgresql-16 -y
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
sudo -u postgres psql -c "CREATE DATABASE todoapp;"
sudo -u postgres psql -c "CREATE USER postgres WITH PASSWORD 'password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE todoapp TO postgres;"
```

#### 5.2 Install Neo4j Locally

**macOS:**
```bash
brew install neo4j
neo4j start

# Set password
neo4j-admin set-initial-password password
```

**Windows/Linux:**
- Download from: https://neo4j.com/download/
- Follow installation wizard
- Set initial password to 'password'
- Install APOC plugin:
  - Download from https://github.com/neo4j/apoc/releases
  - Place in `plugins` folder
  - Add to neo4j.conf: `dbms.security.procedures.unrestricted=apoc.*`

---

## 6. Running with Docker (Recommended)

This is the easiest way to get everything running!

### 6.1 Start All Services with Docker Compose
```bash
# Make sure you're in the project root directory
cd /path/to/fastapi-practice

# Start all services (PostgreSQL, Neo4j, Backend, Frontend)
docker compose up --build

# To run in detached mode (background):
docker compose up -d --build

# To view logs:
docker compose logs -f

# To view logs for specific service:
docker compose logs -f backend
docker compose logs -f frontend
```

### 6.2 Wait for Services to Start
```bash
# Check service status
docker compose ps

# All services should show "running" or "Up"
```

**Expected output:**
```
NAME                  STATUS      PORTS
postgres              Up          0.0.0.0:5432->5432/tcp
neo4j                 Up          0.0.0.0:7474->7474/tcp, 0.0.0.0:7687->7687/tcp
backend               Up          0.0.0.0:8000->8000/tcp
frontend              Up          0.0.0.0:3000->3000/tcp
```

### 6.3 Initialize Database Tables
```bash
# Run database initialization inside the backend container
docker compose exec backend python -c "
from app.database import engine
from app.models import Base
Base.metadata.create_all(bind=engine)
print('Database tables created successfully!')
"
```

### 6.4 Access the Applications
- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:8000
- **API Documentation:** http://localhost:8000/docs (Swagger UI)
- **Alternative API Docs:** http://localhost:8000/redoc (ReDoc)
- **Neo4j Browser:** http://localhost:7474 (username: neo4j, password: password)

### 6.5 Stop Services
```bash
# Stop all services
docker compose down

# Stop and remove volumes (WARNING: deletes all data)
docker compose down -v
```

---

## 7. Running Locally (Without Docker)

If you prefer to run services locally without Docker:

### 7.1 Start Databases
```bash
# Start PostgreSQL (if installed locally)
# macOS:
brew services start postgresql@16

# Linux:
sudo systemctl start postgresql

# Start Neo4j (if installed locally)
# macOS:
neo4j start

# Linux:
sudo systemctl start neo4j

# Windows: Use Neo4j Desktop or Services panel
```

### 7.2 Initialize Database Tables
```bash
# Navigate to backend directory
cd backend

# Activate virtual environment
source venv/bin/activate  # macOS/Linux
# venv\Scripts\activate    # Windows

# Create tables
python -c "
from app.database import engine
from app.models import Base
Base.metadata.create_all(bind=engine)
print('Database tables created successfully!')
"
```

### 7.3 Start Backend Server
```bash
# Make sure you're in backend directory with venv activated
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Server will start at http://localhost:8000
```

### 7.4 Start Frontend Server (New Terminal)
```bash
# Open a new terminal
cd frontend

# Start development server
npm run dev

# Server will start at http://localhost:3000
```

---

## 8. Documentation Setup

### 8.1 Install Documentation Dependencies
```bash
# Navigate to docs directory
cd docs

# Create virtual environment (if not using backend's venv)
python3 -m venv venv
source venv/bin/activate  # macOS/Linux
# venv\Scripts\activate    # Windows

# Install dependencies
pip install -r requirements.txt
```

### 8.2 Build Documentation
```bash
# Build HTML documentation
make html

# On Windows (if make is not available):
sphinx-build -b html source build/html

# View documentation
# macOS:
open build/html/index.html

# Linux:
xdg-open build/html/index.html

# Windows:
start build/html/index.html
```

---

## 9. Testing Setup

### 9.1 Install Testing Dependencies
```bash
# Navigate to backend directory
cd backend

# Activate virtual environment
source venv/bin/activate  # macOS/Linux

# Testing dependencies are already in requirements.txt
# Verify pytest is installed:
pytest --version
```

### 9.2 Run Tests
```bash
# Run all tests
pytest

# Run with verbose output
pytest -v

# Run with coverage
pytest --cov=app

# Run specific test file
pytest tests/test_api.py
```

### 9.3 Run Setup Validation Script
```bash
# Navigate to project root
cd ..

# Make script executable
chmod +x test-setup.sh

# Run validation
./test-setup.sh

# This script checks:
# - Docker status
# - Port availability
# - Service health
# - Database connections
```

---

## 10. AWS Deployment

### 10.1 Install AWS CLI
**macOS:**
```bash
brew install awscli
```

**Windows:**
- Download from: https://aws.amazon.com/cli/

**Linux:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Verify:**
```bash
aws --version
```

### 10.2 Configure AWS Credentials
```bash
aws configure

# Enter your:
# AWS Access Key ID: [your-key]
# AWS Secret Access Key: [your-secret]
# Default region name: us-east-1 (or your preferred region)
# Default output format: json
```

### 10.3 Update Backend .env with AWS Credentials
```bash
cd backend
nano .env  # or code .env

# Add:
# AWS_ACCESS_KEY_ID=your-access-key
# AWS_SECRET_ACCESS_KEY=your-secret-key
# AWS_REGION=us-east-1
```

### 10.4 Deploy to AWS ECS
```bash
# Navigate to deployment directory
cd deployment/aws

# Make deploy script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh

# This script will:
# 1. Create ECR repositories
# 2. Build and push Docker images
# 3. Deploy CloudFormation stack
# 4. Create ECS cluster and services
```

### 10.5 Access Deployed Application
```bash
# Get the load balancer URL from CloudFormation outputs
aws cloudformation describe-stacks \
  --stack-name fastapi-todo-app \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
  --output text
```

---

## 11. Verification

### 11.1 Test Backend API
```bash
# Test health endpoint
curl http://localhost:8000/

# Expected response: {"message": "Welcome to FastAPI Todo App"}

# Test API documentation
open http://localhost:8000/docs  # macOS
# or visit in browser: http://localhost:8000/docs
```

### 11.2 Test Frontend
```bash
# Visit in browser
open http://localhost:3000  # macOS
# or visit: http://localhost:3000

# You should see the login/registration page
```

### 11.3 Test Database Connections
```bash
# Test PostgreSQL
docker compose exec postgres psql -U postgres -d todoapp -c "\dt"
# Should show: users, todos, categories tables

# Test Neo4j
# Visit http://localhost:7474 in browser
# Login with: neo4j / password
# Run query: MATCH (n) RETURN n LIMIT 10
```

### 11.4 Create Test User via API
```bash
# Register a new user
curl -X POST "http://localhost:8000/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "testpassword123"
  }'

# Login to get token
curl -X POST "http://localhost:8000/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser&password=testpassword123"

# Copy the access_token from response
```

---

## 12. Troubleshooting

### 12.1 Docker Issues

**Problem:** Docker daemon not running
```bash
# macOS/Windows: Open Docker Desktop app

# Linux:
sudo systemctl start docker
```

**Problem:** Port already in use
```bash
# Find what's using the port (example for port 8000)
# macOS/Linux:
lsof -i :8000

# Windows:
netstat -ano | findstr :8000

# Kill the process or use alternative docker-compose.local.yml:
docker compose -f docker-compose.local.yml up
# This uses ports 3001, 8001, 5433 instead
```

**Problem:** Container won't start
```bash
# View container logs
docker compose logs backend
docker compose logs frontend
docker compose logs postgres
docker compose logs neo4j

# Restart a specific service
docker compose restart backend

# Rebuild without cache
docker compose build --no-cache
docker compose up
```

### 12.2 Python/Backend Issues

**Problem:** Module not found
```bash
# Make sure virtual environment is activated
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt
```

**Problem:** Database connection error
```bash
# Check if PostgreSQL is running
docker compose ps postgres

# Check connection string in .env
cat backend/.env | grep DATABASE_URL

# Test connection manually
docker compose exec postgres psql -U postgres -d todoapp -c "SELECT 1;"
```

**Problem:** Neo4j connection error
```bash
# Check if Neo4j is running
docker compose ps neo4j

# Check Neo4j browser: http://localhost:7474
# Login with neo4j/password

# Verify credentials in .env match
cat backend/.env | grep NEO4J
```

### 12.3 Frontend Issues

**Problem:** npm install fails
```bash
# Clear npm cache
npm cache clean --force

# Delete node_modules and package-lock.json
rm -rf node_modules package-lock.json

# Reinstall
npm install

# If still fails, try:
npm install --legacy-peer-deps
```

**Problem:** Next.js won't start
```bash
# Delete .next directory
rm -rf .next

# Restart dev server
npm run dev
```

**Problem:** API connection refused
```bash
# Make sure backend is running
curl http://localhost:8000/

# Check frontend .env.local
cat frontend/.env.local
# Should have: NEXT_PUBLIC_API_URL=http://localhost:8000

# Check browser console for CORS errors
```

### 12.4 Permission Issues (Linux)

**Problem:** Docker permission denied
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Logout and login, or:
newgrp docker

# Test:
docker ps
```

**Problem:** Can't write to directory
```bash
# Check ownership
ls -la

# Fix ownership
sudo chown -R $USER:$USER .
```

### 12.5 Database Migration Issues

**Problem:** Tables not created
```bash
# Recreate all tables
docker compose exec backend python -c "
from app.database import engine
from app.models import Base
Base.metadata.drop_all(bind=engine)
Base.metadata.create_all(bind=engine)
print('Database reset complete!')
"
```

**Problem:** Alembic migrations
```bash
# Initialize Alembic (if needed)
cd backend
alembic init alembic

# Create migration
alembic revision --autogenerate -m "Initial migration"

# Apply migration
alembic upgrade head
```

---

## Quick Start Commands Summary

### Using Docker (Simplest):
```bash
# Clone and navigate
git clone <repo-url>
cd fastapi-practice

# Start everything
docker compose up -d --build

# Initialize database
docker compose exec backend python -c "from app.database import engine; from app.models import Base; Base.metadata.create_all(bind=engine)"

# Access:
# Frontend: http://localhost:3000
# Backend: http://localhost:8000/docs
```

### Local Development:
```bash
# Backend (Terminal 1)
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your settings
uvicorn app.main:app --reload

# Frontend (Terminal 2)
cd frontend
npm install
npm run dev
```

---

## Environment Variables Reference

### Backend (.env)
```env
DATABASE_URL=postgresql://postgres:password@localhost:5432/todoapp
NEO4J_URI=bolt://localhost:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=password
SECRET_KEY=your-secret-key-min-32-chars
AWS_ACCESS_KEY_ID=your-aws-key (optional)
AWS_SECRET_ACCESS_KEY=your-aws-secret (optional)
AWS_REGION=us-east-1 (optional)
```

### Frontend (.env.local)
```env
NEXT_PUBLIC_API_URL=http://localhost:8000
```

---

## Port Reference

| Service    | Port | URL                          |
|------------|------|------------------------------|
| Frontend   | 3000 | http://localhost:3000        |
| Backend    | 8000 | http://localhost:8000        |
| PostgreSQL | 5432 | localhost:5432               |
| Neo4j Web  | 7474 | http://localhost:7474        |
| Neo4j Bolt | 7687 | bolt://localhost:7687        |

### Alternative Ports (docker-compose.local.yml)
| Service    | Port |
|------------|------|
| Frontend   | 3001 |
| Backend    | 8001 |
| PostgreSQL | 5433 |
| Neo4j Web  | 7475 |
| Neo4j Bolt | 7688 |

---

## Next Steps

After setup is complete:

1. **Read the documentation:** Check `docs/learning/` directory for guides
2. **Read LEARNING_GUIDE.md:** Comprehensive learning path
3. **Explore the API:** Visit http://localhost:8000/docs
4. **Create your first todo:** Use the frontend or API
5. **Experiment with Neo4j:** Try the recommendation feature
6. **Write tests:** Add tests in `backend/tests/`
7. **Customize:** Modify models, add features, enhance UI

---

## Additional Resources

- **FastAPI Documentation:** https://fastapi.tiangolo.com/
- **Next.js Documentation:** https://nextjs.org/docs
- **PostgreSQL Documentation:** https://www.postgresql.org/docs/
- **Neo4j Documentation:** https://neo4j.com/docs/
- **Docker Documentation:** https://docs.docker.com/
- **SQLAlchemy Documentation:** https://docs.sqlalchemy.org/

---

## Support

If you encounter issues not covered in this guide:

1. Check the logs: `docker compose logs [service-name]`
2. Review the README.md file
3. Check individual component documentation in `docs/learning/`
4. Search for error messages online
5. Review the GitHub issues (if applicable)

---

**Happy Coding!** 🚀
