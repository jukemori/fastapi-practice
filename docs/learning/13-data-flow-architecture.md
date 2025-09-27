# Data Flow Architecture: Understanding Request Lifecycles

## 🌊 What is Data Flow Architecture?

**Data flow architecture** is like **tracking a package through a delivery system** - understanding:

- **Where requests start** (user clicks a button)
- **How they travel** through your system (frontend → backend → database)
- **What transforms them** (validation, business logic, formatting)
- **Where responses end up** (back to the user interface)
- **What can go wrong** at each step (errors, timeouts, failures)

Think of it as **mapping the journey of every piece of information** in your application from start to finish.

## 🗺️ Our Todo App's Complete Data Flow

### High-Level Journey:
```
User Action (Create Todo)
    ↓
Next.js Frontend
    ↓ HTTP Request
FastAPI Backend
    ↓ SQL/Cypher
PostgreSQL & Neo4j
    ↓ Response
FastAPI Backend
    ↓ JSON Response
Next.js Frontend
    ↓ UI Update
User Sees Result
```

### Detailed Breakdown:
```
[User] → [Browser] → [Next.js] → [FastAPI] → [Databases] → [FastAPI] → [Next.js] → [Browser] → [User]
   1        2          3          4           5            6          7          8         9
```

## 📱 Frontend Data Flow (Next.js)

### 1. **User Interaction Layer**
```typescript
// components/TodoForm.tsx
const TodoForm = () => {
  const [title, setTitle] = useState('')
  const [loading, setLoading] = useState(false)
  const { user } = useAuth()
  
  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    
    // Step 1: Validate user input
    if (!title.trim()) {
      toast.error('Todo title is required')
      return
    }
    
    // Step 2: Show loading state
    setLoading(true)
    
    try {
      // Step 3: Call API service
      await createTodo({ title: title.trim() })
      
      // Step 4: Handle success
      toast.success('Todo created!')
      setTitle('')
      
    } catch (error) {
      // Step 5: Handle errors
      console.error('Failed to create todo:', error)
      toast.error('Failed to create todo')
    } finally {
      // Step 6: Reset loading state
      setLoading(false)
    }
  }
  
  return (
    <form onSubmit={handleSubmit}>
      <input 
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        disabled={loading}
      />
      <button type="submit" disabled={loading}>
        {loading ? 'Creating...' : 'Create Todo'}
      </button>
    </form>
  )
}
```

### 2. **API Service Layer**
```typescript
// services/todoService.ts
class TodoService {
  private baseURL = process.env.NEXT_PUBLIC_API_URL
  
  async createTodo(todoData: CreateTodoRequest): Promise<Todo> {
    // Step 1: Prepare request
    const url = `${this.baseURL}/todos`
    const token = localStorage.getItem('authToken')
    
    // Step 2: Configure request
    const requestConfig = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify(todoData)
    }
    
    // Step 3: Make HTTP request
    const response = await fetch(url, requestConfig)
    
    // Step 4: Handle HTTP errors
    if (!response.ok) {
      const errorData = await response.json()
      throw new APIError(response.status, errorData.detail)
    }
    
    // Step 5: Parse successful response
    const todo = await response.json()
    
    // Step 6: Validate response format
    if (!this.isValidTodo(todo)) {
      throw new Error('Invalid todo format received')
    }
    
    return todo
  }
  
  private isValidTodo(data: any): data is Todo {
    return data && 
           typeof data.id === 'number' &&
           typeof data.title === 'string' &&
           typeof data.completed === 'boolean'
  }
}
```

### 3. **State Management Flow**
```typescript
// hooks/useTodos.ts
export const useTodos = () => {
  const [todos, setTodos] = useState<Todo[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  
  const createTodo = async (todoData: CreateTodoRequest) => {
    try {
      setLoading(true)
      setError(null)
      
      // Step 1: Call API
      const newTodo = await todoService.createTodo(todoData)
      
      // Step 2: Update local state optimistically
      setTodos(prevTodos => [...prevTodos, newTodo])
      
      // Step 3: Trigger background sync (optional)
      await syncWithBackend()
      
    } catch (error) {
      setError(error.message)
      // Revert optimistic update if needed
      throw error
    } finally {
      setLoading(false)
    }
  }
  
  return { todos, loading, error, createTodo }
}
```

## 🔧 Backend Data Flow (FastAPI)

### 1. **Request Reception & Authentication**
```python
# app/main.py
from fastapi import FastAPI, Request, Depends
from fastapi.middleware.cors import CORSMiddleware
import time
import logging

app = FastAPI()

@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all incoming requests for debugging."""
    start_time = time.time()
    
    # Step 1: Log incoming request
    logging.info(f"Incoming {request.method} {request.url}")
    logging.info(f"Headers: {dict(request.headers)}")
    
    # Step 2: Process request
    response = await call_next(request)
    
    # Step 3: Log response
    process_time = time.time() - start_time
    logging.info(f"Response: {response.status_code} in {process_time:.2f}s")
    
    return response

# Step 4: Authentication dependency
async def get_current_user(token: str = Depends(oauth2_scheme)):
    """Extract and validate user from JWT token."""
    try:
        # Decode JWT token
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username = payload.get("sub")
        
        if username is None:
            raise HTTPException(401, "Invalid token")
        
        # Get user from database
        user = crud.get_user_by_username(db, username)
        if user is None:
            raise HTTPException(401, "User not found")
            
        return user
        
    except JWTError:
        raise HTTPException(401, "Invalid token")
```

### 2. **Request Validation & Routing**
```python
# app/routers/todos.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.schemas import TodoCreate, TodoResponse
from app.dependencies import get_db, get_current_user

router = APIRouter()

@router.post("/todos", response_model=TodoResponse, status_code=201)
async def create_todo(
    todo: TodoCreate,  # Step 1: Automatic Pydantic validation
    current_user: User = Depends(get_current_user),  # Step 2: Authentication
    db: Session = Depends(get_db)  # Step 3: Database session
):
    """
    Create a new todo item.
    
    Data Flow:
    1. Request body → Pydantic validation
    2. JWT token → User authentication  
    3. Validated data → Service layer
    4. Service layer → Database operations
    5. Database response → Response formatting
    """
    
    try:
        # Step 4: Input validation
        if len(todo.title.strip()) == 0:
            raise HTTPException(400, "Todo title cannot be empty")
        
        if len(todo.title) > 200:
            raise HTTPException(400, "Todo title too long")
            
        # Step 5: Business logic via service layer
        created_todo = await todo_service.create_todo(
            db=db, 
            todo_data=todo, 
            user_id=current_user.id
        )
        
        # Step 6: Response formatting
        return TodoResponse.from_orm(created_todo)
        
    except ValidationError as e:
        raise HTTPException(422, str(e))
    except Exception as e:
        logging.error(f"Failed to create todo: {str(e)}")
        raise HTTPException(500, "Internal server error")
```

### 3. **Service Layer Processing**
```python
# app/services/todo_service.py
class TodoService:
    """Business logic layer for todo operations."""
    
    def __init__(self, db: Session, neo4j_client: Neo4jClient):
        self.db = db
        self.neo4j_client = neo4j_client
    
    async def create_todo(self, todo_data: TodoCreate, user_id: int) -> Todo:
        """
        Create todo with dual database synchronization.
        
        Data Flow:
        1. Validate business rules
        2. Begin database transaction
        3. Create in PostgreSQL (source of truth)
        4. Sync to Neo4j (relationships)
        5. Commit or rollback
        """
        
        # Step 1: Business validation
        await self._validate_todo_creation(todo_data, user_id)
        
        # Step 2: Start transaction
        db_todo = None
        try:
            # Step 3: Create in PostgreSQL
            db_todo = Todo(
                title=todo_data.title,
                description=todo_data.description,
                user_id=user_id,
                created_at=datetime.utcnow()
            )
            
            self.db.add(db_todo)
            self.db.flush()  # Get ID without committing
            
            # Step 4: Create relationships in Neo4j
            await self._create_neo4j_relationships(db_todo)
            
            # Step 5: Commit transaction
            self.db.commit()
            self.db.refresh(db_todo)
            
            # Step 6: Background tasks (optional)
            await self._trigger_background_tasks(db_todo)
            
            return db_todo
            
        except Exception as e:
            # Step 7: Rollback on error
            self.db.rollback()
            await self._cleanup_neo4j_on_error(db_todo)
            raise e
    
    async def _validate_todo_creation(self, todo_data: TodoCreate, user_id: int):
        """Validate business rules for todo creation."""
        
        # Check user exists and is active
        user = crud.get_user(self.db, user_id)
        if not user or not user.is_active:
            raise HTTPException(403, "User not authorized")
        
        # Check rate limiting
        recent_todos = crud.get_recent_todos(self.db, user_id, minutes=1)
        if len(recent_todos) > 10:
            raise HTTPException(429, "Too many todos created recently")
        
        # Check for duplicates
        existing = crud.get_todo_by_title(self.db, todo_data.title, user_id)
        if existing:
            raise HTTPException(409, "Todo with this title already exists")
```

## 🗄️ Database Layer Data Flow

### 1. **PostgreSQL Operations**
```python
# app/crud/todo.py
def create_todo(db: Session, todo: TodoCreate, user_id: int) -> Todo:
    """
    PostgreSQL data flow for todo creation.
    
    Steps:
    1. Prepare SQL statement
    2. Execute with parameters
    3. Handle database constraints
    4. Return created object
    """
    
    # Step 1: Create model instance
    db_todo = Todo(
        title=todo.title,
        description=todo.description,
        completed=False,
        user_id=user_id,
        created_at=datetime.utcnow()
    )
    
    # Step 2: Add to session (prepare for commit)
    db.add(db_todo)
    
    try:
        # Step 3: Execute SQL
        db.commit()
        
        # Step 4: Refresh object with DB-generated values
        db.refresh(db_todo)
        
        return db_todo
        
    except IntegrityError as e:
        db.rollback()
        if 'duplicate key' in str(e):
            raise HTTPException(409, "Duplicate todo")
        elif 'foreign key' in str(e):
            raise HTTPException(404, "User not found")
        else:
            raise HTTPException(500, "Database error")
```

### 2. **Neo4j Graph Operations**
```python
# app/services/neo4j_service.py
class Neo4jService:
    """Handle graph database operations."""
    
    async def create_todo_relationships(self, todo: Todo):
        """
        Create todo relationships in Neo4j.
        
        Data Flow:
        1. Create todo node
        2. Link to user node  
        3. Analyze patterns
        4. Create recommendations
        """
        
        async with self.driver.session() as session:
            # Step 1: Create todo node
            await session.run("""
                MERGE (t:Todo {id: $todo_id})
                SET t.title = $title,
                    t.created_at = $created_at
            """, todo_id=todo.id, title=todo.title, created_at=todo.created_at)
            
            # Step 2: Link to user
            await session.run("""
                MATCH (u:User {id: $user_id}), (t:Todo {id: $todo_id})
                MERGE (u)-[:OWNS]->(t)
            """, user_id=todo.user_id, todo_id=todo.id)
            
            # Step 3: Create category relationships if applicable
            if todo.categories:
                for category in todo.categories:
                    await session.run("""
                        MATCH (t:Todo {id: $todo_id}), (c:Category {id: $cat_id})
                        MERGE (t)-[:BELONGS_TO]->(c)
                    """, todo_id=todo.id, cat_id=category.id)
            
            # Step 4: Update similarity scores
            await self._update_user_similarity(session, todo.user_id)
```

## 🔄 Error Handling & Resilience

### 1. **Error Propagation Flow**
```python
# Error handling at each layer

# Database Layer
try:
    result = db.execute(query)
except SQLAlchemyError as e:
    logging.error(f"Database error: {e}")
    raise DatabaseError("Failed to execute query")

# Service Layer  
try:
    todo = await todo_service.create_todo(data)
except DatabaseError as e:
    logging.error(f"Service error: {e}")
    raise ServiceError("Failed to create todo")

# API Layer
try:
    result = await service.method()
except ServiceError as e:
    raise HTTPException(500, "Internal server error")
except ValidationError as e:
    raise HTTPException(422, str(e))

# Frontend Layer
try:
    await api.createTodo(data)
catch (error) {
    if (error.status === 422) {
        showValidationError(error.detail)
    } else if (error.status >= 500) {
        showGenericError("Server error, please try again")
    } else {
        showError(error.message)
    }
}
```

### 2. **Retry and Circuit Breaker Patterns**
```python
# app/utils/resilience.py
import asyncio
from functools import wraps

class CircuitBreaker:
    """Prevent cascading failures."""
    
    def __init__(self, failure_threshold=5, timeout=60):
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.failure_count = 0
        self.last_failure_time = None
        self.state = 'CLOSED'  # CLOSED, OPEN, HALF_OPEN
    
    async def call(self, func, *args, **kwargs):
        if self.state == 'OPEN':
            if time.time() - self.last_failure_time > self.timeout:
                self.state = 'HALF_OPEN'
            else:
                raise CircuitBreakerError("Circuit breaker is OPEN")
        
        try:
            result = await func(*args, **kwargs)
            self._on_success()
            return result
        except Exception as e:
            self._on_failure()
            raise e
    
    def _on_success(self):
        self.failure_count = 0
        self.state = 'CLOSED'
    
    def _on_failure(self):
        self.failure_count += 1
        self.last_failure_time = time.time()
        
        if self.failure_count >= self.failure_threshold:
            self.state = 'OPEN'

# Usage in service
neo4j_circuit_breaker = CircuitBreaker()

async def create_todo_with_resilience(todo_data):
    try:
        # Primary operation (PostgreSQL)
        db_todo = crud.create_todo(db, todo_data)
        
        # Secondary operation with circuit breaker (Neo4j)
        await neo4j_circuit_breaker.call(
            neo4j_service.create_relationships, db_todo
        )
        
        return db_todo
        
    except CircuitBreakerError:
        # Neo4j is down, but todo is still created
        logging.warning("Neo4j unavailable, skipping graph operations")
        return db_todo
```

## 📊 Monitoring Data Flow

### 1. **Request Tracing**
```python
# app/middleware/tracing.py
import uuid
from contextvars import ContextVar

# Global context for request tracing
request_id_var: ContextVar[str] = ContextVar('request_id')

@app.middleware("http")
async def add_request_id(request: Request, call_next):
    # Generate unique request ID
    request_id = str(uuid.uuid4())
    request_id_var.set(request_id)
    
    # Add to response headers
    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    
    return response

# Usage in services
class TodoService:
    async def create_todo(self, todo_data):
        request_id = request_id_var.get()
        
        logging.info(f"[{request_id}] Creating todo: {todo_data.title}")
        
        try:
            # Database operation
            result = crud.create_todo(db, todo_data)
            logging.info(f"[{request_id}] Todo created with ID: {result.id}")
            
            # Graph operation
            await neo4j_service.create_relationships(result)
            logging.info(f"[{request_id}] Graph relationships created")
            
            return result
            
        except Exception as e:
            logging.error(f"[{request_id}] Failed to create todo: {str(e)}")
            raise
```

### 2. **Performance Metrics**
```python
# app/middleware/metrics.py
import time
from prometheus_client import Counter, Histogram

# Metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration')

@app.middleware("http")
async def record_metrics(request: Request, call_next):
    start_time = time.time()
    
    # Process request
    response = await call_next(request)
    
    # Record metrics
    duration = time.time() - start_time
    REQUEST_DURATION.observe(duration)
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()
    
    return response
```

## 🔍 Data Flow Debugging

### 1. **Comprehensive Logging**
```python
# app/utils/logging.py
import structlog
import json

# Structured logging setup
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
)

logger = structlog.get_logger()

# Usage in data flow points
async def create_todo_with_logging(todo_data: TodoCreate, user_id: int):
    log = logger.bind(
        operation="create_todo",
        user_id=user_id,
        todo_title=todo_data.title
    )
    
    log.info("Starting todo creation")
    
    try:
        # Step 1: Validation
        log.info("Validating todo data")
        await validate_todo(todo_data, user_id)
        
        # Step 2: Database operation
        log.info("Creating todo in PostgreSQL")
        db_todo = crud.create_todo(db, todo_data, user_id)
        log.info("Todo created in PostgreSQL", todo_id=db_todo.id)
        
        # Step 3: Graph operation
        log.info("Creating relationships in Neo4j")
        await neo4j_service.create_relationships(db_todo)
        log.info("Relationships created in Neo4j")
        
        log.info("Todo creation completed successfully")
        return db_todo
        
    except Exception as e:
        log.error("Todo creation failed", error=str(e), error_type=type(e).__name__)
        raise
```

### 2. **Data Flow Visualization**
```python
# app/utils/flow_tracer.py
class DataFlowTracer:
    """Trace data flow for debugging."""
    
    def __init__(self):
        self.steps = []
    
    def step(self, name: str, data: dict = None):
        """Record a step in the data flow."""
        step_info = {
            'timestamp': datetime.utcnow().isoformat(),
            'step_name': name,
            'data': data or {},
            'duration': None
        }
        self.steps.append(step_info)
        return len(self.steps) - 1  # Return step index
    
    def complete_step(self, step_index: int, result: dict = None):
        """Mark a step as completed."""
        if step_index < len(self.steps):
            start_time = datetime.fromisoformat(self.steps[step_index]['timestamp'])
            duration = (datetime.utcnow() - start_time).total_seconds()
            self.steps[step_index]['duration'] = duration
            self.steps[step_index]['result'] = result or {}
    
    def get_trace(self):
        """Get complete trace for debugging."""
        return {
            'total_steps': len(self.steps),
            'total_duration': sum(s.get('duration', 0) for s in self.steps),
            'steps': self.steps
        }

# Usage in API endpoint
@router.post("/todos")
async def create_todo_traced(todo: TodoCreate, current_user: User = Depends(get_current_user)):
    tracer = DataFlowTracer()
    
    # Step 1: Input validation
    step1 = tracer.step('input_validation', {'title_length': len(todo.title)})
    validate_input(todo)
    tracer.complete_step(step1, {'valid': True})
    
    # Step 2: Database operation
    step2 = tracer.step('database_create')
    db_todo = crud.create_todo(db, todo, current_user.id)
    tracer.complete_step(step2, {'todo_id': db_todo.id})
    
    # Step 3: Graph operation
    step3 = tracer.step('graph_create')
    await neo4j_service.create_relationships(db_todo)
    tracer.complete_step(step3, {'relationships_created': True})
    
    # Include trace in response headers for debugging
    trace = tracer.get_trace()
    response.headers["X-Data-Flow-Trace"] = json.dumps(trace)
    
    return db_todo
```

## 🎯 Performance Optimization

### 1. **Caching Layer**
```python
# app/cache/redis_cache.py
import redis
import json
from typing import Optional

class CacheService:
    """Redis caching for optimizing data flow."""
    
    def __init__(self):
        self.redis_client = redis.Redis(host='localhost', port=6379, db=0)
    
    async def get_user_todos(self, user_id: int) -> Optional[list]:
        """Get cached user todos."""
        cache_key = f"user_todos:{user_id}"
        cached = self.redis_client.get(cache_key)
        
        if cached:
            return json.loads(cached)
        
        return None
    
    async def set_user_todos(self, user_id: int, todos: list, ttl: int = 300):
        """Cache user todos for 5 minutes."""
        cache_key = f"user_todos:{user_id}"
        self.redis_client.setex(
            cache_key, 
            ttl, 
            json.dumps(todos, default=str)
        )
    
    async def invalidate_user_cache(self, user_id: int):
        """Invalidate cache when user data changes."""
        cache_key = f"user_todos:{user_id}"
        self.redis_client.delete(cache_key)

# Usage in service layer
async def get_user_todos_optimized(user_id: int) -> list:
    # Step 1: Check cache
    cached_todos = await cache_service.get_user_todos(user_id)
    if cached_todos:
        return cached_todos
    
    # Step 2: Query database
    db_todos = crud.get_user_todos(db, user_id)
    
    # Step 3: Cache result
    await cache_service.set_user_todos(user_id, db_todos)
    
    return db_todos
```

### 2. **Asynchronous Processing**
```python
# app/tasks/background.py
from celery import Celery

celery_app = Celery('todoapp')

@celery_app.task
async def sync_to_analytics(todo_data: dict):
    """Background task for analytics sync."""
    try:
        # Send to analytics service
        analytics_client.track_todo_created(todo_data)
        
        # Update recommendation engine
        recommendation_engine.update_user_profile(todo_data['user_id'])
        
        # Send notifications
        notification_service.notify_followers(todo_data)
        
    except Exception as e:
        logging.error(f"Background task failed: {e}")

# In main flow - non-blocking
async def create_todo_async(todo_data: TodoCreate, user_id: int):
    # Critical path - must succeed
    db_todo = crud.create_todo(db, todo_data, user_id)
    await neo4j_service.create_relationships(db_todo)
    
    # Background processing - can fail without affecting user
    sync_to_analytics.delay({
        'todo_id': db_todo.id,
        'user_id': user_id,
        'title': db_todo.title,
        'created_at': db_todo.created_at.isoformat()
    })
    
    return db_todo
```

## 🎓 Key Takeaways

1. **Data flows through multiple layers** - each with specific responsibilities
2. **Request tracing helps debug issues** across complex architectures  
3. **Error handling must exist at every layer** to prevent cascading failures
4. **Monitoring and logging are essential** for understanding system behavior
5. **Caching reduces database load** and improves response times
6. **Async processing** allows non-critical tasks to run in background
7. **Circuit breakers prevent system overload** during failures
8. **Structured logging** makes debugging much easier

## 🛠️ Practical Exercise

Trace a complete request through your todo app:

### 1. **Add Request Tracing**:
```bash
# Add logging to each layer
# Frontend: console.log with timestamps
# Backend: structured logging with request IDs
# Database: query logging
```

### 2. **Create a Test Request**:
```bash
# Make a todo creation request
curl -X POST http://localhost:8000/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-token" \
  -d '{"title": "Test Data Flow"}'
```

### 3. **Analyze the Logs**:
```bash
# Follow logs in real-time
docker-compose logs -f backend
```

### 4. **Identify Bottlenecks**:
```bash
# Look for slow steps
# Check database query times
# Monitor memory usage
# Analyze response times
```

---

**Previous**: [How Everything Connects](12-how-everything-connects.md) | **Next**: [Security Best Practices](14-security-best-practices.md)