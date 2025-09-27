#!/bin/bash

echo "🚀 Testing Todo App Setup..."

# Check if Docker is running
echo "1. Checking Docker..."
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
else
    echo "✅ Docker is running"
fi

# Check required ports
echo "2. Checking if required ports are available..."
PORTS=(3000 8000 5432 7474 7687)
for port in "${PORTS[@]}"; do
    if lsof -i :$port > /dev/null 2>&1; then
        echo "⚠️  Port $port is already in use"
    else
        echo "✅ Port $port is available"
    fi
done

# Start the application
echo "3. Starting the application with Docker Compose..."
docker-compose up -d

# Wait for services to be ready
echo "4. Waiting for services to be ready..."
sleep 30

# Test backend health
echo "5. Testing backend API..."
if curl -s http://localhost:8000/ > /dev/null; then
    echo "✅ Backend API is responding"
else
    echo "❌ Backend API is not responding"
fi

# Test frontend
echo "6. Testing frontend..."
if curl -s http://localhost:3000/ > /dev/null; then
    echo "✅ Frontend is responding"
else
    echo "❌ Frontend is not responding"
fi

# Test PostgreSQL
echo "7. Testing PostgreSQL connection..."
if docker exec todo_postgres pg_isready -U postgres > /dev/null 2>&1; then
    echo "✅ PostgreSQL is ready"
else
    echo "❌ PostgreSQL is not ready"
fi

# Test Neo4j
echo "8. Testing Neo4j connection..."
if curl -s http://localhost:7474/ > /dev/null; then
    echo "✅ Neo4j browser is accessible"
else
    echo "❌ Neo4j browser is not accessible"
fi

echo ""
echo "🎉 Setup test completed!"
echo ""
echo "📍 Access points:"
echo "   • Frontend:      http://localhost:3000"
echo "   • Backend API:   http://localhost:8000"
echo "   • API Docs:      http://localhost:8000/docs"
echo "   • Neo4j Browser: http://localhost:7474 (neo4j/password)"
echo ""
echo "🔧 To stop the application:"
echo "   docker-compose down"