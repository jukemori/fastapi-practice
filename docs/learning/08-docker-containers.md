# Docker & Containers: Packaging Applications for Consistency

## 📦 What are Containers?

**Containers** are like **shipping containers for software**:

- **Standardized packaging** - Works the same everywhere
- **Includes everything needed** - Code, runtime, libraries, dependencies
- **Isolated from host system** - Won't conflict with other applications
- **Portable** - Run on any system that supports containers
- **Lightweight** - Share OS kernel, faster than virtual machines

Think of it as **packaging your entire application** with its environment into a box that can run identically on any computer.

## 🏗️ Virtual Machines vs Containers

### Virtual Machines (Traditional):
```
Host Operating System
├── Hypervisor (VMware, VirtualBox)
├── Guest OS #1 (Full Linux/Windows)
│   └── App #1
├── Guest OS #2 (Full Linux/Windows)  
│   └── App #2
└── Guest OS #3 (Full Linux/Windows)
    └── App #3

Problems:
- Each VM needs full OS (heavy)
- Slow to start (boot entire OS)
- Resource intensive
```

### Containers (Modern):
```
Host Operating System
├── Container Engine (Docker)
├── Container #1 (App + minimal deps)
├── Container #2 (App + minimal deps)
└── Container #3 (App + minimal deps)

Benefits:
- Share host OS kernel (lightweight)
- Start in seconds
- Efficient resource usage
- Consistent environment
```

## 🐳 Docker Architecture

### Core Components:
```
Docker Architecture:
├── Docker Client (docker command)
├── Docker Daemon (dockerd)
├── Docker Images (blueprints)
├── Docker Containers (running instances)
├── Docker Registry (image storage)
└── Docker Compose (multi-container apps)
```

### Our Todo App Docker Setup:
```
Todo Application Containers:
├── Frontend Container (Next.js + Node.js)
├── Backend Container (FastAPI + Python)
├── PostgreSQL Container (Database)
├── Neo4j Container (Graph Database)
└── Shared Network (Communication)
```

## 🛠️ Docker Images vs Containers

### Images (Blueprints):
```dockerfile
# Dockerfile - Recipe for building an image
FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0"]
```

### Containers (Running Instances):
```bash
# Create container from image
docker run -p 8000:8000 my-fastapi-app

# Multiple containers from same image
docker run --name backend1 -p 8001:8000 my-fastapi-app
docker run --name backend2 -p 8002:8000 my-fastapi-app
```

Think of it like:
- **Image** = Recipe for cake
- **Container** = Actual cake baked from recipe

## 📝 Dockerfile Deep Dive

### 1. **Basic Dockerfile Structure**
```dockerfile
# Base image - what to start from
FROM python:3.12-slim

# Metadata
LABEL maintainer="you@example.com"
LABEL description="Todo App Backend"

# Set working directory inside container
WORKDIR /app

# Copy dependency file first (for better caching)
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port (documentation)
EXPOSE 8000

# Command to run when container starts
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 2. **Multi-Stage Builds** (Advanced)
```dockerfile
# Stage 1: Build dependencies
FROM python:3.12-slim as builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# Stage 2: Runtime
FROM python:3.12-slim

# Copy only installed packages from builder stage
COPY --from=builder /root/.local /root/.local
COPY . /app
WORKDIR /app

# Make sure scripts in .local are usable
ENV PATH=/root/.local/bin:$PATH

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0"]
```

### 3. **Frontend Dockerfile**
```dockerfile
FROM node:20-alpine

WORKDIR /app

# Copy package files first (better caching)
COPY package*.json ./
RUN npm install

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Expose port
EXPOSE 3000

# Start the application
CMD ["npm", "start"]
```

## 🔧 Docker Commands Essentials

### 1. **Image Management**
```bash
# Build image from Dockerfile
docker build -t todo-backend .
docker build -t todo-frontend ./frontend

# List images
docker images

# Remove image
docker rmi todo-backend

# Pull image from registry
docker pull postgres:16
docker pull neo4j:5.25

# Push image to registry
docker push yourusername/todo-backend
```

### 2. **Container Management**
```bash
# Run container
docker run -d -p 8000:8000 --name backend todo-backend

# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Stop container
docker stop backend

# Start stopped container
docker start backend

# Remove container
docker rm backend

# View container logs
docker logs backend
docker logs -f backend  # Follow logs in real-time
```

### 3. **Container Interaction**
```bash
# Execute command in running container
docker exec -it backend bash

# Copy files to/from container
docker cp file.txt backend:/app/
docker cp backend:/app/logs ./local-logs

# Inspect container details
docker inspect backend

# View container resource usage
docker stats
```

## 🌐 Docker Networking

### 1. **Network Types**
```bash
# List networks
docker network ls

# Default networks:
# - bridge (default for containers)
# - host (use host networking)
# - none (no networking)

# Create custom network
docker network create todo-network

# Run containers on custom network
docker run -d --network todo-network --name postgres postgres:16
docker run -d --network todo-network --name backend todo-backend
```

### 2. **Container Communication**
```bash
# Containers on same network can reach each other by name
# Backend connects to: postgresql://postgres:5432/todoapp
# Instead of: postgresql://localhost:5432/todoapp

# Check network details
docker network inspect todo-network
```

### 3. **Port Mapping**
```bash
# Map container port to host port
docker run -p 8000:8000 backend  # host:container
docker run -p 3001:3000 frontend

# Multiple port mappings
docker run -p 7474:7474 -p 7687:7687 neo4j
```

## 💾 Docker Volumes & Data Persistence

### 1. **Volume Types**
```bash
# Named volumes (managed by Docker)
docker volume create postgres-data
docker run -v postgres-data:/var/lib/postgresql/data postgres:16

# Bind mounts (map host directory)
docker run -v /host/path:/container/path app
docker run -v $(pwd):/app node:20  # Current directory

# Temporary volumes (in memory)
docker run --tmpfs /tmp app
```

### 2. **Data Persistence Strategy**
```bash
# Database data (persistent)
docker run -v postgres-data:/var/lib/postgresql/data postgres:16

# Application code (development)
docker run -v $(pwd)/backend:/app -p 8000:8000 backend

# Configuration files
docker run -v ./config:/app/config backend
```

### 3. **Volume Management**
```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect postgres-data

# Remove unused volumes
docker volume prune

# Backup volume
docker run --rm -v postgres-data:/data -v $(pwd):/backup alpine \
  tar czf /backup/postgres-backup.tar.gz -C /data .
```

## 🎭 Docker Compose: Multi-Container Applications

### 1. **Why Docker Compose?**
```bash
# Without Compose (manual)
docker network create todo-network
docker run -d --name postgres --network todo-network postgres:16
docker run -d --name neo4j --network todo-network neo4j:5.25
docker run -d --name backend --network todo-network -p 8000:8000 backend
docker run -d --name frontend --network todo-network -p 3000:3000 frontend

# With Compose (simple)
docker-compose up
```

### 2. **Our docker-compose.yml**
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16
    container_name: todo_postgres
    environment:
      POSTGRES_DB: todoapp
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - todo_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 30s
      timeout: 10s
      retries: 3

  neo4j:
    image: neo4j:5.25
    container_name: todo_neo4j
    environment:
      NEO4J_AUTH: neo4j/password
      NEO4J_PLUGINS: '["apoc"]'
    ports:
      - "7474:7474"
      - "7687:7687"
    volumes:
      - neo4j_data:/data
      - neo4j_logs:/logs
    networks:
      - todo_network

  backend:
    build: ./backend
    container_name: todo_backend
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgresql://postgres:password@postgres:5432/todoapp
      NEO4J_URI: bolt://neo4j:7687
      NEO4J_USER: neo4j
      NEO4J_PASSWORD: password
    depends_on:
      postgres:
        condition: service_healthy
      neo4j:
        condition: service_started
    volumes:
      - ./backend:/app  # For development
    networks:
      - todo_network
    restart: unless-stopped

  frontend:
    build: ./frontend
    container_name: todo_frontend
    ports:
      - "3000:3000"
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:8000
    depends_on:
      - backend
    volumes:
      - ./frontend:/app
      - /app/node_modules  # Anonymous volume for node_modules
    networks:
      - todo_network

volumes:
  postgres_data:
  neo4j_data:
  neo4j_logs:

networks:
  todo_network:
    driver: bridge
```

### 3. **Docker Compose Commands**
```bash
# Start all services
docker-compose up

# Start in background (detached)
docker-compose up -d

# Build and start
docker-compose up --build

# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# View logs
docker-compose logs
docker-compose logs backend

# Scale services
docker-compose up --scale backend=3

# Execute command in service
docker-compose exec backend bash
```

## 🔄 Development vs Production Setups

### 1. **Development Configuration**
```yaml
# docker-compose.dev.yml
version: '3.8'

services:
  backend:
    build: 
      context: ./backend
      dockerfile: Dockerfile.dev
    volumes:
      - ./backend:/app  # Hot reload
    environment:
      - DEBUG=True
      - RELOAD=True
    command: uvicorn app.main:app --host 0.0.0.0 --reload

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.dev
    volumes:
      - ./frontend:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
    command: npm run dev
```

### 2. **Production Configuration**
```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  backend:
    build: 
      context: ./backend
      dockerfile: Dockerfile.prod
    environment:
      - DEBUG=False
    restart: always
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.prod
    restart: always
```

### 3. **Environment-Specific Usage**
```bash
# Development
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# Production
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up
```

## 🔒 Security Best Practices

### 1. **Image Security**
```dockerfile
# Use specific versions (not latest)
FROM python:3.12.0-slim

# Don't run as root
RUN adduser --disabled-password --gecos '' appuser
USER appuser

# Copy files with proper permissions
COPY --chown=appuser:appuser . /app

# Use .dockerignore to exclude sensitive files
# .dockerignore
.env
.git
node_modules
```

### 2. **Secrets Management**
```yaml
# Don't put secrets in docker-compose.yml
# Use environment files instead

services:
  backend:
    env_file: .env  # Load from file
    environment:
      - DATABASE_URL  # Reference env var
    secrets:
      - db_password
      - jwt_secret

secrets:
  db_password:
    file: ./secrets/db_password.txt
  jwt_secret:
    external: true
```

### 3. **Network Security**
```yaml
# Isolate services
networks:
  frontend:
    internal: false  # Can access internet
  backend:
    internal: true   # No internet access
  database:
    internal: true   # No internet access

services:
  frontend:
    networks:
      - frontend
      - backend

  backend:
    networks:
      - backend
      - database

  database:
    networks:
      - database
```

## 📊 Container Monitoring

### 1. **Resource Monitoring**
```bash
# View real-time stats
docker stats

# View specific container
docker stats todo_backend

# Format output
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

### 2. **Health Checks**
```dockerfile
# In Dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1
```

```yaml
# In docker-compose.yml
services:
  backend:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### 3. **Logging Strategy**
```yaml
services:
  backend:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    
  # Forward logs to external system
  frontend:
    logging:
      driver: "syslog"
      options:
        syslog-address: "tcp://logs.example.com:514"
```

## 🔧 Troubleshooting Common Issues

### 1. **Build Problems**
```bash
# Clear build cache
docker builder prune

# Build without cache
docker build --no-cache -t todo-backend .

# Debug build process
docker build --progress=plain -t todo-backend .

# Multi-platform builds
docker buildx build --platform linux/amd64,linux/arm64 -t todo-backend .
```

### 2. **Runtime Issues**
```bash
# Check container logs
docker logs todo_backend

# Follow logs in real-time
docker logs -f todo_backend

# Debug running container
docker exec -it todo_backend bash

# Check container processes
docker top todo_backend

# Inspect container configuration
docker inspect todo_backend
```

### 3. **Network Issues**
```bash
# Test connectivity between containers
docker exec todo_backend ping postgres

# Check port bindings
docker port todo_backend

# Inspect network
docker network inspect todo_network

# Test from host
curl http://localhost:8000/health
```

## 🚀 Performance Optimization

### 1. **Image Size Optimization**
```dockerfile
# Use multi-stage builds
FROM python:3.12-slim as builder
RUN pip install --user -r requirements.txt

FROM python:3.12-slim
COPY --from=builder /root/.local /root/.local
# Smaller final image

# Use .dockerignore
# .dockerignore
.git
.pytest_cache
__pycache__
*.pyc
node_modules
```

### 2. **Layer Caching**
```dockerfile
# Order matters for caching
FROM python:3.12-slim

# Copy requirements first (changes less frequently)
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy code last (changes more frequently)
COPY . .
```

### 3. **Resource Limits**
```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

## 🎯 Real-World Docker Patterns

### 1. **Init System for Multiple Processes**
```dockerfile
# Use tini for proper signal handling
FROM python:3.12-slim

RUN apt-get update && apt-get install -y tini
ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["uvicorn", "app.main:app"]
```

### 2. **Graceful Shutdown**
```dockerfile
# Handle shutdown signals properly
FROM python:3.12-slim

# Install signal handlers
COPY shutdown.py /app/
CMD ["python", "/app/shutdown.py"]
```

### 3. **Configuration Management**
```yaml
# Use environment-specific overrides
# docker-compose.override.yml (for development)
version: '3.8'

services:
  backend:
    volumes:
      - ./backend:/app
    environment:
      - DEBUG=True
```

## 🎓 Best Practices Summary

### 1. **Dockerfile Best Practices**
- Use specific base image versions
- Minimize layers and image size
- Order instructions for optimal caching
- Don't run as root user
- Use .dockerignore files
- Include health checks

### 2. **Docker Compose Best Practices**
- Use environment files for secrets
- Define explicit dependencies
- Use named volumes for persistent data
- Implement proper health checks
- Use networks for service isolation

### 3. **Development Workflow**
- Use bind mounts for code changes
- Implement hot reloading
- Separate dev/prod configurations
- Use override files for customization

### 4. **Production Considerations**
- Implement proper logging
- Set resource limits
- Use restart policies
- Monitor container health
- Plan for data backup/recovery

## 🛠️ Practical Exercise

Let's containerize our todo application step by step:

### 1. **Create Backend Dockerfile**
```dockerfile
# backend/Dockerfile
FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN adduser --disabled-password --gecos '' appuser
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 2. **Test Individual Containers**
```bash
# Build and test backend
cd backend
docker build -t todo-backend .
docker run -p 8000:8000 todo-backend

# Test frontend
cd frontend
docker build -t todo-frontend .
docker run -p 3000:3000 todo-frontend
```

### 3. **Run Complete Stack**
```bash
# Start everything
docker-compose up

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Test the application
curl http://localhost:8000/health
```

---

**Previous**: [Neo4j Graph Database](07-neo4j-graph-database.md) | **Next**: [Podman vs Docker](09-podman-vs-docker.md)