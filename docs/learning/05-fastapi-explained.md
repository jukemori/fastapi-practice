# FastAPI Explained: Modern Python Web Framework

## 🚀 What is FastAPI?

**FastAPI** is like a **super-powered restaurant kitchen** that:

- **Takes orders efficiently** (handles HTTP requests)
- **Validates ingredients automatically** (input validation with Pydantic)
- **Prepares food consistently** (type safety with Python type hints)
- **Documents recipes automatically** (auto-generated API docs)
- **Serves multiple customers simultaneously** (async support)
- **Follows health standards** (built-in security features)

### FastAPI vs Other Frameworks:

```python
# Flask (Traditional)
@app.route('/todos', methods=['POST'])
def create_todo():
    data = request.get_json()
    # Manual validation needed
    if not data or 'title' not in data:
        return {'error': 'Title required'}, 400
    # No automatic documentation
    # No type hints
    todo = create_todo_in_db(data)
    return jsonify(todo)

# FastAPI (Modern)
@app.post("/todos", response_model=Todo)
async def create_todo(todo: TodoCreate):
    # Automatic validation ✅
    # Automatic documentation ✅
    # Type safety ✅
    # Async support ✅
    return crud.create_todo(todo)
```

## 🏗️ FastAPI Architecture

### Core Components:

```
FastAPI Application
├── Path Operations (Routes)
├── Dependency Injection System
├── Pydantic Models (Validation)
├── Middleware Stack
├── Exception Handlers
└── Automatic Documentation
```

### Our Todo App Structure:
```
backend/app/
├── main.py          → FastAPI app and routes
├── models.py        → SQLAlchemy database models
├── schemas.py       → Pydantic validation models
├── crud.py          → Database operations
├── auth.py          → Authentication logic
├── database.py      → Database connection
└── neo4j_client.py  → Neo4j operations
```

## 🛠️ Building FastAPI Applications

### 1. **Basic App Setup**
```python
from fastapi import FastAPI

# Create FastAPI instance
app = FastAPI(
    title="Todo App API",
    description="A comprehensive todo application",
    version="1.0.0",
    docs_url="/docs",        # Swagger UI
    redoc_url="/redoc"       # Alternative docs
)

# Basic route
@app.get("/")
async def root():
    return {"message": "Hello World"}

# Run with: uvicorn main:app --reload
```

### 2. **Path Operations (Routes)**
```python
# Different HTTP methods
@app.get("/todos")           # GET - Retrieve data
@app.post("/todos")          # POST - Create data
@app.put("/todos/{id}")      # PUT - Replace data
@app.patch("/todos/{id}")    # PATCH - Update data
@app.delete("/todos/{id}")   # DELETE - Remove data

# Path parameters
@app.get("/todos/{todo_id}")
async def get_todo(todo_id: int):
    return {"todo_id": todo_id}

# Query parameters
@app.get("/todos")
async def get_todos(
    skip: int = 0,           # Default value
    limit: int = 100,        # Default value
    completed: bool = None   # Optional parameter
):
    return {"skip": skip, "limit": limit, "completed": completed}

# Request body
@app.post("/todos")
async def create_todo(todo: TodoCreate):  # Pydantic model
    return {"title": todo.title}
```

### 3. **Pydantic Models for Validation**
```python
from pydantic import BaseModel, Field, validator
from typing import Optional
from datetime import datetime

# Input validation model
class TodoCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200, description="Todo title")
    description: Optional[str] = Field(None, max_length=1000)
    priority: str = Field("medium", regex="^(low|medium|high)$")
    
    # Custom validation
    @validator('title')
    def title_must_not_be_empty(cls, v):
        if not v.strip():
            raise ValueError('Title cannot be empty')
        return v.strip()

# Response model
class Todo(BaseModel):
    id: int
    title: str
    description: Optional[str] = None
    completed: bool = False
    priority: str
    created_at: datetime
    user_id: int
    
    class Config:
        from_attributes = True  # Enable ORM mode for SQLAlchemy

# Update model (partial)
class TodoUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    completed: Optional[bool] = None
    priority: Optional[str] = None
```

### 4. **Dependency Injection**
```python
from fastapi import Depends
from sqlalchemy.orm import Session

# Database dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Authentication dependency
async def get_current_user(token: str = Depends(oauth2_scheme)):
    # Validate JWT token
    payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    username = payload.get("sub")
    user = get_user_by_username(username)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid token")
    return user

# Use dependencies in routes
@app.get("/todos", response_model=List[Todo])
async def get_todos(
    db: Session = Depends(get_db),                    # Database session
    current_user: User = Depends(get_current_user),   # Current user
    skip: int = 0,
    limit: int = 100
):
    return crud.get_todos(db, user_id=current_user.id, skip=skip, limit=limit)
```

## 🔐 Authentication in FastAPI

### 1. **JWT Token Authentication**
```python
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from passlib.context import CryptContext
from jose import JWTError, jwt

# Security setup
SECRET_KEY = "your-secret-key"
ALGORITHM = "HS256"
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Password hashing
def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

# JWT token creation
def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

# Login endpoint
@app.post("/token")
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    # Authenticate user
    user = authenticate_user(form_data.username, form_data.password)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # Create token
    access_token = create_access_token(data={"sub": user.username})
    return {"access_token": access_token, "token_type": "bearer"}

# Protected endpoint
@app.get("/protected")
async def protected_route(current_user: User = Depends(get_current_user)):
    return {"message": f"Hello {current_user.username}"}
```

### 2. **Authentication Flow**
```
1. User Registration:
   Frontend → POST /register → FastAPI → Hash Password → Database

2. User Login:
   Frontend → POST /token → FastAPI → Verify Password → JWT Token

3. Authenticated Requests:
   Frontend → GET /todos (with token) → FastAPI → Verify Token → Data
```

## 📊 Database Integration

### 1. **SQLAlchemy Models**
```python
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True)
    email = Column(String(100), unique=True, index=True)
    hashed_password = Column(String(255))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationship
    todos = relationship("Todo", back_populates="owner")

class Todo(Base):
    __tablename__ = "todos"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200))
    completed = Column(Boolean, default=False)
    user_id = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationship
    owner = relationship("User", back_populates="todos")
```

### 2. **CRUD Operations**
```python
from sqlalchemy.orm import Session

def get_todos(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return db.query(Todo).filter(Todo.user_id == user_id).offset(skip).limit(limit).all()

def create_todo(db: Session, todo: TodoCreate, user_id: int):
    db_todo = Todo(**todo.dict(), user_id=user_id)
    db.add(db_todo)
    db.commit()
    db.refresh(db_todo)
    return db_todo

def update_todo(db: Session, todo_id: int, todo_update: TodoUpdate, user_id: int):
    db_todo = db.query(Todo).filter(Todo.id == todo_id, Todo.user_id == user_id).first()
    if db_todo:
        update_data = todo_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_todo, field, value)
        db.commit()
        db.refresh(db_todo)
    return db_todo

def delete_todo(db: Session, todo_id: int, user_id: int):
    db_todo = db.query(Todo).filter(Todo.id == todo_id, Todo.user_id == user_id).first()
    if db_todo:
        db.delete(db_todo)
        db.commit()
    return db_todo
```

### 3. **Using CRUD in Routes**
```python
@app.post("/todos", response_model=Todo)
async def create_todo(
    todo: TodoCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return crud.create_todo(db=db, todo=todo, user_id=current_user.id)

@app.get("/todos", response_model=List[Todo])
async def read_todos(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return crud.get_todos(db, user_id=current_user.id, skip=skip, limit=limit)
```

## ⚡ Async Programming in FastAPI

### 1. **Why Async?**
```python
# Synchronous (blocking)
def slow_operation():
    time.sleep(1)  # Blocks entire server for 1 second
    return "done"

@app.get("/slow")
def slow_endpoint():
    result = slow_operation()
    return {"result": result}

# Asynchronous (non-blocking)
async def fast_operation():
    await asyncio.sleep(1)  # Other requests can be processed
    return "done"

@app.get("/fast")
async def fast_endpoint():
    result = await fast_operation()
    return {"result": result}
```

### 2. **Database Async Operations**
```python
# Using async SQLAlchemy
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine

async_engine = create_async_engine("postgresql+asyncpg://user:pass@localhost/db")

async def get_todos_async(db: AsyncSession, user_id: int):
    result = await db.execute(
        select(Todo).where(Todo.user_id == user_id)
    )
    return result.scalars().all()

@app.get("/todos")
async def read_todos(
    db: AsyncSession = Depends(get_async_db),
    current_user: User = Depends(get_current_user)
):
    return await get_todos_async(db, current_user.id)
```

### 3. **External API Calls**
```python
import httpx

@app.get("/external-data")
async def get_external_data():
    async with httpx.AsyncClient() as client:
        # Non-blocking HTTP request
        response = await client.get("https://api.external.com/data")
        return response.json()
```

## 🛡️ Error Handling & Validation

### 1. **HTTP Exceptions**
```python
from fastapi import HTTPException

@app.get("/todos/{todo_id}")
async def get_todo(todo_id: int, current_user: User = Depends(get_current_user)):
    todo = crud.get_todo(todo_id, current_user.id)
    if not todo:
        raise HTTPException(
            status_code=404,
            detail="Todo not found"
        )
    return todo

# Custom exception handler
@app.exception_handler(ValueError)
async def value_error_handler(request: Request, exc: ValueError):
    return JSONResponse(
        status_code=422,
        content={"message": f"Validation error: {str(exc)}"}
    )
```

### 2. **Validation Errors**
```python
from pydantic import ValidationError

class TodoCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    priority: str = Field(..., regex="^(low|medium|high)$")
    
    @validator('title')
    def validate_title(cls, v):
        if not v.strip():
            raise ValueError('Title cannot be empty')
        return v.strip()

# FastAPI automatically handles ValidationError and returns 422
```

### 3. **Global Error Handling**
```python
@app.middleware("http")
async def catch_exceptions_middleware(request: Request, call_next):
    try:
        return await call_next(request)
    except Exception as exc:
        logger.error(f"Unhandled exception: {exc}")
        return JSONResponse(
            status_code=500,
            content={"message": "Internal server error"}
        )
```

## 🎭 Middleware in FastAPI

### 1. **CORS Middleware**
```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:3001"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### 2. **Custom Middleware**
```python
import time

@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response

@app.middleware("http")
async def log_requests(request: Request, call_next):
    logger.info(f"Request: {request.method} {request.url}")
    response = await call_next(request)
    logger.info(f"Response: {response.status_code}")
    return response
```

## 📚 Automatic Documentation

### 1. **OpenAPI Schema Generation**
```python
app = FastAPI(
    title="Todo API",
    description="A comprehensive todo application API",
    version="1.0.0",
    contact={
        "name": "API Support",
        "email": "support@todoapp.com",
    },
    license_info={
        "name": "MIT",
        "url": "https://opensource.org/licenses/MIT",
    },
)
```

### 2. **Enhanced Documentation**
```python
@app.post(
    "/todos",
    response_model=Todo,
    status_code=201,
    summary="Create a new todo",
    description="Create a new todo item for the authenticated user",
    response_description="The created todo item",
    tags=["todos"]
)
async def create_todo(
    todo: TodoCreate = Body(
        ...,
        example={
            "title": "Learn FastAPI",
            "description": "Study FastAPI documentation and examples",
            "priority": "high"
        }
    ),
    current_user: User = Depends(get_current_user)
):
    """
    Create a new todo with the following information:
    
    - **title**: Todo title (required, 1-200 characters)
    - **description**: Detailed description (optional, max 1000 characters)
    - **priority**: Priority level (low, medium, or high)
    """
    return crud.create_todo(db, todo=todo, user_id=current_user.id)
```

### 3. **Response Models & Examples**
```python
from pydantic import BaseModel, Field

class TodoResponse(BaseModel):
    id: int = Field(..., description="Unique identifier")
    title: str = Field(..., description="Todo title")
    completed: bool = Field(..., description="Completion status")
    
    class Config:
        schema_extra = {
            "example": {
                "id": 1,
                "title": "Learn FastAPI",
                "completed": False
            }
        }

@app.get("/todos", response_model=List[TodoResponse])
async def get_todos():
    pass
```

## 🧪 Testing FastAPI Applications

### 1. **Test Setup**
```python
import pytest
from httpx import AsyncClient
from fastapi.testclient import TestClient

# Sync testing
client = TestClient(app)

def test_create_todo():
    response = client.post(
        "/todos",
        json={"title": "Test Todo", "priority": "high"},
        headers={"Authorization": "Bearer test-token"}
    )
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "Test Todo"

# Async testing
@pytest.mark.asyncio
async def test_create_todo_async():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        response = await ac.post("/todos", json={"title": "Test Todo"})
        assert response.status_code == 201
```

### 2. **Database Testing**
```python
@pytest.fixture
def test_db():
    # Create test database
    engine = create_engine("sqlite:///./test.db")
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base.metadata.create_all(bind=engine)
    
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)

def test_crud_operations(test_db):
    # Test database operations
    todo = crud.create_todo(test_db, TodoCreate(title="Test"), user_id=1)
    assert todo.title == "Test"
    
    todos = crud.get_todos(test_db, user_id=1)
    assert len(todos) == 1
```

### 3. **Authentication Testing**
```python
def test_protected_endpoint_without_token():
    response = client.get("/todos")
    assert response.status_code == 401

def test_protected_endpoint_with_token():
    token = create_test_token(user_id=1)
    response = client.get(
        "/todos",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
```

## 🚀 Performance Optimization

### 1. **Database Optimization**
```python
# Use indexes
class Todo(Base):
    __tablename__ = "todos"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)  # Index for queries
    created_at = Column(DateTime, index=True)  # Index for sorting

# Eager loading to avoid N+1 queries
@app.get("/todos-with-users")
async def get_todos_with_users(db: Session = Depends(get_db)):
    return db.query(Todo).options(joinedload(Todo.owner)).all()

# Pagination
@app.get("/todos")
async def get_todos(skip: int = 0, limit: int = 100):
    return crud.get_todos(db, skip=skip, limit=limit)
```

### 2. **Caching**
```python
from functools import lru_cache

# Memory caching
@lru_cache(maxsize=1000)
def expensive_operation(param: str):
    # Expensive computation
    return result

# Redis caching
import redis
redis_client = redis.Redis(host='localhost', port=6379, db=0)

@app.get("/cached-data/{item_id}")
async def get_cached_data(item_id: int):
    cache_key = f"item:{item_id}"
    cached = redis_client.get(cache_key)
    
    if cached:
        return json.loads(cached)
    
    data = expensive_database_query(item_id)
    redis_client.setex(cache_key, 300, json.dumps(data))  # Cache for 5 minutes
    return data
```

### 3. **Async Optimizations**
```python
# Concurrent operations
import asyncio

@app.get("/user-dashboard/{user_id}")
async def get_user_dashboard(user_id: int):
    # Run multiple operations concurrently
    todos_task = asyncio.create_task(get_user_todos(user_id))
    stats_task = asyncio.create_task(get_user_stats(user_id))
    recent_task = asyncio.create_task(get_recent_activity(user_id))
    
    todos, stats, recent = await asyncio.gather(todos_task, stats_task, recent_task)
    
    return {
        "todos": todos,
        "stats": stats,
        "recent_activity": recent
    }
```

## 🔧 Configuration & Settings

### 1. **Environment-based Configuration**
```python
from pydantic import BaseSettings

class Settings(BaseSettings):
    database_url: str = "postgresql://user:pass@localhost/db"
    secret_key: str = "dev-secret-key"
    access_token_expire_minutes: int = 30
    debug: bool = False
    
    class Config:
        env_file = ".env"

settings = Settings()

# Use in application
app = FastAPI(debug=settings.debug)
```

### 2. **Environment Files**
```bash
# .env file
DATABASE_URL=postgresql://postgres:password@localhost:5432/todoapp
SECRET_KEY=your-super-secret-key-here
ACCESS_TOKEN_EXPIRE_MINUTES=30
DEBUG=True
```

## 🌐 Deployment Considerations

### 1. **Production Settings**
```python
# main.py
if settings.environment == "production":
    app = FastAPI(
        title="Todo API",
        docs_url=None,      # Disable docs in production
        redoc_url=None,     # Disable redoc in production
        openapi_url=None    # Disable OpenAPI schema
    )
else:
    app = FastAPI(title="Todo API (Development)")
```

### 2. **Health Checks**
```python
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow(),
        "version": "1.0.0"
    }

@app.get("/health/db")
async def database_health(db: Session = Depends(get_db)):
    try:
        # Simple database query
        db.execute("SELECT 1")
        return {"database": "healthy"}
    except Exception as e:
        raise HTTPException(status_code=503, detail="Database unhealthy")
```

### 3. **Logging**
```python
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    
    logger.info(
        f"{request.client.host} - {request.method} {request.url} - "
        f"{response.status_code} - {process_time:.3f}s"
    )
    return response
```

## 🎯 Best Practices

### 1. **Project Structure**
```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py          # FastAPI app
│   ├── config.py        # Settings
│   ├── dependencies.py  # Common dependencies
│   ├── models/          # SQLAlchemy models
│   ├── schemas/         # Pydantic models
│   ├── crud/           # Database operations
│   ├── api/            # Route definitions
│   │   ├── __init__.py
│   │   └── v1/
│   │       ├── __init__.py
│   │       ├── todos.py
│   │       └── users.py
│   └── core/           # Core functionality
│       ├── __init__.py
│       ├── auth.py
│       └── security.py
├── tests/
├── requirements.txt
└── alembic/           # Database migrations
```

### 2. **Code Organization**
```python
# api/v1/todos.py
from fastapi import APIRouter, Depends
from ...dependencies import get_current_user, get_db

router = APIRouter(prefix="/todos", tags=["todos"])

@router.get("/", response_model=List[Todo])
async def get_todos():
    pass

@router.post("/", response_model=Todo)
async def create_todo():
    pass

# main.py
from .api.v1 import todos

app = FastAPI()
app.include_router(todos.router, prefix="/api/v1")
```

### 3. **Error Handling Standards**
```python
# Define custom exceptions
class TodoNotFound(HTTPException):
    def __init__(self, todo_id: int):
        super().__init__(
            status_code=404,
            detail=f"Todo with id {todo_id} not found"
        )

class InsufficientPermissions(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=403,
            detail="Insufficient permissions"
        )

# Use in routes
@app.get("/todos/{todo_id}")
async def get_todo(todo_id: int, current_user: User = Depends(get_current_user)):
    todo = crud.get_todo(todo_id)
    if not todo:
        raise TodoNotFound(todo_id)
    if todo.user_id != current_user.id:
        raise InsufficientPermissions()
    return todo
```

## 🎓 Key Takeaways

1. **FastAPI combines the best** of modern Python web development
2. **Type hints enable automatic validation** and documentation
3. **Async support** allows high-performance applications
4. **Dependency injection** makes code modular and testable
5. **Automatic documentation** saves development time
6. **Pydantic integration** provides robust data validation
7. **Security features** are built-in and easy to use
8. **Testing support** makes applications reliable
9. **Performance optimizations** are straightforward to implement
10. **Modern Python features** make code clean and maintainable

## 🛠️ Practical Exercise

Extend our todo API with a new feature:

### 1. Add Todo Categories
```python
# schemas.py
class CategoryCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=50)
    color: str = Field("#3B82F6", regex="^#[0-9A-Fa-f]{6}$")

class Category(BaseModel):
    id: int
    name: str
    color: str
    user_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# main.py
@app.post("/categories", response_model=Category)
async def create_category(
    category: CategoryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return crud.create_category(db, category=category, user_id=current_user.id)

@app.get("/categories", response_model=List[Category])
async def get_categories(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return crud.get_categories(db, user_id=current_user.id)
```

### 2. Test the New Endpoints
```bash
# Create a category
curl -X POST http://localhost:8001/categories \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"name": "Work", "color": "#FF5722"}'

# Get all categories
curl -X GET http://localhost:8001/categories \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 3. Check the Automatic Documentation
Visit: http://localhost:8001/docs

You'll see the new endpoints automatically documented!

---

**Previous**: [API Concepts](04-api-concepts.md) | **Next**: [PostgreSQL Deep Dive](06-postgresql-deep-dive.md)