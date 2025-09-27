# Todo App - Full Stack Learning Project

A comprehensive todo application built with modern technologies to demonstrate full-stack development concepts.

## 🚀 Technology Stack

- **Backend**: FastAPI (Python 3.12)
- **Databases**: PostgreSQL + Neo4j
- **Frontend**: Next.js 15 with TypeScript
- **Containerization**: Docker/Podman
- **Cloud**: AWS (ECS, ECR, CloudFormation)
- **Documentation**: Sphinx

## 📋 Features

- User authentication with JWT
- CRUD operations for todos
- Category management
- Graph-based recommendations (Neo4j)
- Responsive web interface
- Containerized deployment
- AWS cloud deployment
- Comprehensive documentation

## 🛠️ Quick Start

### Prerequisites
- Docker or Podman
- Node.js 20+ (for local frontend development)
- Python 3.12+ (for local backend development)

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd fastapi-practice
   ```

2. **Set up environment variables**
   ```bash
   cp backend/.env.example backend/.env
   # Edit backend/.env with your configurations
   ```

3. **Start with Docker Compose**
   ```bash
   docker-compose up
   ```

4. **Access the application**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8000
   - API Documentation: http://localhost:8000/docs
   - Neo4j Browser: http://localhost:7474

### With Podman

```bash
cd deployment/podman
podman-compose up
```

## 📁 Project Structure

```
fastapi-practice/
├── backend/                 # FastAPI application
│   ├── app/
│   │   ├── main.py         # API routes and FastAPI app
│   │   ├── models.py       # SQLAlchemy database models
│   │   ├── schemas.py      # Pydantic validation schemas
│   │   ├── auth.py         # JWT authentication
│   │   ├── crud.py         # Database CRUD operations
│   │   ├── database.py     # Database connection setup
│   │   └── neo4j_client.py # Neo4j graph database client
│   ├── requirements.txt    # Python dependencies
│   └── Dockerfile         # Backend container
├── frontend/               # Next.js application
│   ├── src/
│   │   ├── app/           # Next.js app router
│   │   ├── components/    # React components
│   │   ├── context/       # React context providers
│   │   └── lib/           # API client and utilities
│   ├── package.json       # Node.js dependencies
│   └── Dockerfile         # Frontend container
├── deployment/            # Deployment configurations
│   ├── aws/              # AWS CloudFormation templates
│   └── podman/           # Podman-specific configs
├── docs/                 # Sphinx documentation
│   ├── source/           # Documentation source files
│   └── requirements.txt  # Documentation dependencies
├── docker-compose.yml    # Multi-service development setup
├── LEARNING_GUIDE.md     # Comprehensive learning guide
└── README.md            # This file
```

## 🔧 Development

### Backend Development

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### Frontend Development

```bash
cd frontend
npm install
npm run dev
```

### Documentation

```bash
cd docs
pip install -r requirements.txt
make html
```

## 🚀 Deployment

### AWS Deployment

1. **Prerequisites**
   - AWS CLI configured
   - Docker installed
   - Appropriate AWS permissions

2. **Deploy to AWS**
   ```bash
   cd deployment/aws
   ./deploy.sh
   ```

This script will:
- Create ECR repositories
- Build and push Docker images
- Deploy infrastructure with CloudFormation
- Set up ECS service

### Manual Docker Build

```bash
# Backend
cd backend
docker build -t todo-backend .

# Frontend
cd frontend
docker build -t todo-frontend .
```

## 🏗️ Architecture

### Database Design
- **PostgreSQL**: Stores structured data (users, todos, categories)
- **Neo4j**: Manages relationships and provides recommendations

### API Endpoints
- `POST /register` - User registration
- `POST /token` - User login
- `GET /users/me` - Get current user
- `GET/POST /todos` - Todo operations
- `GET/POST /categories` - Category operations
- `GET /recommendations` - Neo4j-powered recommendations

### Authentication Flow
1. User registers/logs in via frontend
2. Backend validates credentials
3. JWT token returned and stored
4. Token included in subsequent API calls

## 📚 Learning Resources

See [LEARNING_GUIDE.md](LEARNING_GUIDE.md) for detailed explanations of:
- How each technology works
- Why we chose each tool
- How they connect together
- Step-by-step learning path
- Common patterns and best practices

## 🔍 API Documentation

When running locally, visit http://localhost:8000/docs for interactive API documentation powered by FastAPI's automatic OpenAPI generation.

## 🧪 Testing

### Backend Tests
```bash
cd backend
pytest
```

### Frontend Tests
```bash
cd frontend
npm test
```

## 🤝 Contributing

This is a learning project. Feel free to:
- Add new features
- Improve documentation
- Optimize performance
- Add tests
- Enhance UI/UX

## 📝 Environment Variables

### Backend (.env)
```
DATABASE_URL=postgresql://postgres:password@localhost:5432/todoapp
NEO4J_URI=bolt://localhost:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=password
SECRET_KEY=your-secret-key-here
```

### Frontend
```
NEXT_PUBLIC_API_URL=http://localhost:8000
```

## 🔒 Security Notes

- Change default passwords in production
- Use environment-specific secrets
- Enable HTTPS in production
- Implement rate limiting
- Add input validation

## 📊 Monitoring

The application includes:
- Structured logging
- Health check endpoints
- CloudWatch integration (AWS)
- Error tracking

## 🚨 Troubleshooting

### Common Issues

1. **Port conflicts**: Ensure ports 3000, 8000, 5432, 7474, 7687 are available
2. **Database connection**: Check PostgreSQL and Neo4j are running
3. **Authentication errors**: Verify JWT secret key is set
4. **Docker issues**: Try `docker-compose down` and `docker-compose up --build`

### Logs

```bash
# View all services
docker-compose logs

# Specific service
docker-compose logs backend
docker-compose logs frontend
```

## 📈 Performance

- Backend: FastAPI with async support
- Frontend: Next.js with SSR/SSG
- Database: Indexed queries
- Caching: Redis can be added
- CDN: AWS CloudFront for static assets

## 🎯 Next Steps

1. Add real-time updates with WebSockets
2. Implement email notifications
3. Add file upload for attachments
4. Create mobile app with React Native
5. Add advanced analytics dashboard
6. Implement team collaboration features

## 📄 License

This project is for educational purposes. Feel free to use and modify as needed for learning.

---

**Happy Learning! 🚀**

This project demonstrates modern full-stack development practices and provides a solid foundation for understanding how different technologies work together in a real-world application.