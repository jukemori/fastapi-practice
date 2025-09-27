# API Concepts: How Applications Talk to Each Other

## 🤔 What is an API?

**API (Application Programming Interface)** is like a **waiter in a restaurant**:

- **You (Frontend)** = Customer who wants food
- **Kitchen (Backend/Database)** = Where food is prepared
- **Waiter (API)** = Takes your order, brings you food

**The waiter:**
- Takes your order (receives requests)
- Knows the menu (defines available operations)
- Communicates with kitchen (processes business logic)
- Brings you food (returns responses)
- Handles special requests (parameters and options)

## 🍽️ Restaurant Analogy in Detail

### Traditional Restaurant (Without APIs):
```
Customer → Goes to kitchen → Talks directly to chef → Gets food
```
**Problems:**
- Kitchen gets crowded
- Chef gets distracted
- No standardized ordering process
- Chaos!

### Modern Restaurant (With APIs):
```
Customer → Tells waiter → Waiter talks to kitchen → Waiter brings food
```
**Benefits:**
- Clear communication process
- Kitchen can focus on cooking
- Standardized menu/ordering
- Multiple customers served efficiently

### Our Todo App Restaurant:
```
Frontend (Customer) → FastAPI (Waiter) → Database (Kitchen) → Data (Food)
```

## 🏗️ Types of APIs

### 1. **REST APIs** (What we use)
**REST = REpresentational State Transfer**

Think of REST like a **standardized menu system**:

```
Menu (API endpoints):
├── GET /todos        → "Show me all my orders"
├── POST /todos       → "Place a new order"  
├── GET /todos/123    → "Show me order #123"
├── PUT /todos/123    → "Replace order #123 completely"
├── PATCH /todos/123  → "Modify part of order #123"
└── DELETE /todos/123 → "Cancel order #123"
```

**REST Principles:**
- **Stateless**: Each request is independent
- **Resource-based**: Everything is a "resource" (todos, users)
- **HTTP methods**: Use standard verbs (GET, POST, PUT, DELETE)
- **JSON format**: Data exchanged in JSON format

### 2. **GraphQL APIs**
Like a **custom order system**:

```javascript
// Instead of multiple REST calls:
GET /users/123
GET /users/123/todos
GET /users/123/categories

// One GraphQL query:
query {
  user(id: 123) {
    name
    todos {
      title
      completed
    }
    categories {
      name
    }
  }
}
```

### 3. **RPC APIs** (Remote Procedure Call)
Like **calling specific kitchen functions**:

```javascript
// Call functions directly
createTodo({title: "Learn APIs", priority: "high"})
getTodosByUser(userId: 123)
markTodoComplete(todoId: 456)
```

### 4. **WebSocket APIs**
Like a **direct phone line to the kitchen**:

```javascript
// Real-time, bidirectional communication
socket.on('todoCreated', (todo) => {
  // Instantly show new todo
});

socket.emit('createTodo', {title: "Live Todo"});
```

## 🛠️ REST API Deep Dive

### HTTP Methods & Their Purposes:

#### GET - Retrieve Data
```http
GET /todos HTTP/1.1
Host: localhost:8001
Authorization: Bearer token...

Response:
[
  {"id": 1, "title": "Learn APIs", "completed": false},
  {"id": 2, "title": "Build app", "completed": true}
]
```
**Characteristics:**
- **Safe**: Doesn't change server state
- **Idempotent**: Same result every time
- **Cacheable**: Browsers can cache responses

#### POST - Create New Resource
```http
POST /todos HTTP/1.1
Host: localhost:8001
Content-Type: application/json

{
  "title": "Master REST APIs",
  "priority": "high",
  "description": "Learn all HTTP methods"
}

Response:
{
  "id": 123,
  "title": "Master REST APIs", 
  "priority": "high",
  "completed": false,
  "created_at": "2025-09-27T10:30:00Z"
}
```
**Characteristics:**
- **Not safe**: Changes server state
- **Not idempotent**: Creates new resource each time
- **Returns created resource**: With new ID and metadata

#### PUT - Replace Entire Resource
```http
PUT /todos/123 HTTP/1.1
Host: localhost:8001
Content-Type: application/json

{
  "title": "Master REST APIs - Updated",
  "priority": "medium", 
  "completed": true,
  "description": "Completed learning REST"
}
```
**Characteristics:**
- **Not safe**: Changes server state
- **Idempotent**: Same result if repeated
- **Complete replacement**: All fields must be provided

#### PATCH - Partial Update
```http
PATCH /todos/123 HTTP/1.1
Host: localhost:8001
Content-Type: application/json

{
  "completed": true
}
```
**Characteristics:**
- **Not safe**: Changes server state
- **Idempotent**: Same result if repeated
- **Partial update**: Only specified fields changed

#### DELETE - Remove Resource
```http
DELETE /todos/123 HTTP/1.1
Host: localhost:8001
Authorization: Bearer token...

Response:
{
  "message": "Todo deleted successfully"
}
```
**Characteristics:**
- **Not safe**: Changes server state
- **Idempotent**: Same result if repeated (already deleted)
- **Usually returns confirmation**: Success message

### RESTful URL Design

#### Good RESTful URLs:
```
GET    /todos                 → Get all todos
POST   /todos                 → Create new todo
GET    /todos/123             → Get specific todo
PUT    /todos/123             → Replace todo
PATCH  /todos/123             → Update todo
DELETE /todos/123             → Delete todo

GET    /users/456/todos       → Get todos for user 456
POST   /users/456/todos       → Create todo for user 456
GET    /categories            → Get all categories
GET    /categories/789/todos  → Get todos in category 789
```

#### Bad URL Examples:
```
❌ GET /getTodos              → Verb in URL (use HTTP method instead)
❌ GET /todos/delete/123      → Action in URL (use DELETE method)
❌ POST /todos/123/update     → Wrong method and action in URL
❌ GET /todo                  → Inconsistent naming (singular vs plural)
❌ GET /todos?action=delete   → Action as parameter
```

## 📊 API Response Formats

### JSON (JavaScript Object Notation)
**Most common format** - human readable and lightweight:

```json
{
  "id": 123,
  "title": "Learn JSON",
  "completed": false,
  "priority": "high",
  "created_at": "2025-09-27T10:30:00Z",
  "user": {
    "id": 456,
    "username": "john_doe"
  },
  "tags": ["learning", "api", "json"]
}
```

### XML (Less common now)
```xml
<todo>
  <id>123</id>
  <title>Learn JSON</title>
  <completed>false</completed>
  <priority>high</priority>
</todo>
```

### Our API Response Structure:
```python
# Pydantic models define response structure
class Todo(BaseModel):
    id: int
    title: str
    description: Optional[str] = None
    completed: bool = False
    priority: str = "medium"
    created_at: datetime
    updated_at: Optional[datetime] = None
    user_id: int

# FastAPI automatically converts to JSON:
{
  "id": 123,
  "title": "Learn Pydantic",
  "description": null,
  "completed": false,
  "priority": "medium",
  "created_at": "2025-09-27T10:30:00.123456",
  "updated_at": null,
  "user_id": 456
}
```

## 🔐 API Authentication & Authorization

### 1. **Authentication** - "Who are you?"

#### JWT (JSON Web Tokens) - What we use:
```
Login Process:
1. User sends username/password
2. Server validates credentials
3. Server creates JWT token
4. Client stores token
5. Client sends token with each request
```

#### JWT Structure:
```
eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxMjMsImV4cCI6MTYzNzc2MjQwMH0.signature

Header.Payload.Signature

Header: {"typ": "JWT", "alg": "HS256"}
Payload: {"user_id": 123, "exp": 1637762400}
Signature: Cryptographic signature
```

#### Using JWT in Requests:
```http
GET /todos HTTP/1.1
Host: localhost:8001
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

### 2. **Authorization** - "What can you do?"

```python
# Different permission levels
@app.get("/todos")
async def get_todos(current_user: User = Depends(get_current_user)):
    # User can only see their own todos
    return get_user_todos(current_user.id)

@app.delete("/todos/{todo_id}")  
async def delete_todo(todo_id: int, current_user: User = Depends(get_current_user)):
    # User can only delete their own todos
    todo = get_todo(todo_id)
    if todo.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")
    delete_todo(todo_id)
```

### 3. **API Keys** (Alternative method):
```http
GET /todos HTTP/1.1
Host: api.example.com
X-API-Key: abc123def456ghi789
```

## 📚 API Documentation

### Why Documentation Matters:
- **Developers need to know**: What endpoints exist
- **How to use them**: Required parameters, expected responses
- **Error handling**: What can go wrong and how to handle it
- **Examples**: Real-world usage scenarios

### OpenAPI/Swagger (What FastAPI uses):
```python
@app.post("/todos", response_model=Todo, status_code=201,
         summary="Create a new todo",
         description="Create a new todo item for the authenticated user")
async def create_todo(
    todo: TodoCreate,
    current_user: User = Depends(get_current_user)
):
    """
    Create a new todo with the following information:
    
    - **title**: Todo title (required)
    - **description**: Detailed description (optional)
    - **priority**: Priority level (low/medium/high)
    - **due_date**: When the todo should be completed (optional)
    """
    return crud.create_todo(db=db, todo=todo, user_id=current_user.id)
```

**FastAPI automatically generates**:
- Interactive documentation at `/docs`
- Alternative docs at `/redoc`  
- OpenAPI schema at `/openapi.json`

### Documentation Structure:
```
API Documentation:
├── Overview
├── Authentication
├── Endpoints
│   ├── GET /todos
│   ├── POST /todos
│   ├── GET /todos/{id}
│   ├── PUT /todos/{id}
│   └── DELETE /todos/{id}
├── Error Codes
├── Rate Limits
└── Examples
```

## 🔄 API Request-Response Lifecycle

Let's trace a complete API request in our todo application:

### 1. Frontend Initiates Request
```javascript
// React component
const createTodo = async (todoData) => {
  try {
    const response = await fetch('http://localhost:8001/todos', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${localStorage.getItem('token')}`
      },
      body: JSON.stringify(todoData)
    });
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    
    const newTodo = await response.json();
    return newTodo;
  } catch (error) {
    console.error('Error creating todo:', error);
    throw error;
  }
};
```

### 2. FastAPI Receives and Processes Request
```python
@app.post("/todos", response_model=Todo)
async def create_todo(
    todo: TodoCreate,                              # 1. Validate request body
    current_user: User = Depends(get_current_user) # 2. Authenticate user
):
    # 3. Check authorization (user can create todos)
    if not current_user.is_active:
        raise HTTPException(status_code=403, detail="User account disabled")
    
    # 4. Process business logic
    try:
        # 5. Save to PostgreSQL
        db_todo = crud.create_todo(db, todo=todo, user_id=current_user.id)
        
        # 6. Create relationships in Neo4j
        neo4j_client.create_todo_node(db_todo.id, db_todo.title, current_user.id)
        
        # 7. Return response
        return db_todo
        
    except Exception as e:
        # 8. Handle errors
        raise HTTPException(status_code=500, detail="Failed to create todo")
```

### 3. Database Operations
```sql
-- PostgreSQL: Save structured data
BEGIN;
INSERT INTO todos (title, description, priority, user_id, created_at)
VALUES ($1, $2, $3, $4, NOW()) 
RETURNING id, title, description, priority, completed, user_id, created_at, updated_at;
COMMIT;
```

```cypher
-- Neo4j: Create relationships
MATCH (u:User {id: $user_id})
CREATE (t:Todo {id: $todo_id, title: $title})
CREATE (u)-[:OWNS]->(t)
RETURN t;
```

### 4. Response Generation
```python
# FastAPI automatically serializes response
{
  "id": 123,
  "title": "Learn API Design",
  "description": "Study REST principles and best practices",
  "priority": "high", 
  "completed": false,
  "user_id": 456,
  "created_at": "2025-09-27T10:30:00.123456",
  "updated_at": null
}
```

### 5. Frontend Handles Response
```javascript
createTodo({
  title: "Learn API Design",
  description: "Study REST principles",
  priority: "high"
})
.then(newTodo => {
  // Success: Update UI
  setTodos(prevTodos => [...prevTodos, newTodo]);
  showSuccessMessage("Todo created successfully!");
})
.catch(error => {
  // Error: Show user-friendly message
  showErrorMessage("Failed to create todo. Please try again.");
});
```

## ⚡ API Performance & Optimization

### 1. **Pagination**
Don't return all data at once:

```python
@app.get("/todos")
async def get_todos(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_user)
):
    todos = crud.get_todos(db, user_id=current_user.id, skip=skip, limit=limit)
    total = crud.count_todos(db, user_id=current_user.id)
    
    return {
        "todos": todos,
        "total": total,
        "skip": skip,
        "limit": limit
    }
```

```javascript
// Frontend pagination
const fetchTodos = async (page = 1, limit = 20) => {
  const skip = (page - 1) * limit;
  const response = await fetch(`/todos?skip=${skip}&limit=${limit}`);
  return response.json();
};
```

### 2. **Filtering & Searching**
```python
@app.get("/todos")
async def get_todos(
    completed: Optional[bool] = None,
    priority: Optional[str] = None,
    search: Optional[str] = None,
    current_user: User = Depends(get_current_user)
):
    return crud.get_todos_filtered(
        db, 
        user_id=current_user.id,
        completed=completed,
        priority=priority,
        search=search
    )
```

```javascript
// Frontend filtering
const fetchTodos = async (filters) => {
  const params = new URLSearchParams();
  if (filters.completed !== undefined) params.append('completed', filters.completed);
  if (filters.priority) params.append('priority', filters.priority);
  if (filters.search) params.append('search', filters.search);
  
  const response = await fetch(`/todos?${params}`);
  return response.json();
};
```

### 3. **Caching**
```python
from functools import lru_cache
import redis

# Memory caching
@lru_cache(maxsize=1000)
def get_user_by_id(user_id: int):
    return db.query(User).filter(User.id == user_id).first()

# Redis caching
async def get_todos_cached(user_id: int):
    cache_key = f"user:{user_id}:todos"
    cached = redis_client.get(cache_key)
    
    if cached:
        return json.loads(cached)
    
    todos = crud.get_todos(db, user_id=user_id)
    redis_client.setex(cache_key, 300, json.dumps(todos))  # Cache for 5 minutes
    return todos
```

### 4. **Rate Limiting**
```python
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@app.post("/todos")
@limiter.limit("10/minute")  # Max 10 todos per minute
async def create_todo(request: Request, todo: TodoCreate):
    return crud.create_todo(db, todo=todo)
```

## 🚨 Error Handling & HTTP Status Codes

### Comprehensive Error Handling:
```python
@app.post("/todos")
async def create_todo(todo: TodoCreate, current_user: User = Depends(get_current_user)):
    try:
        # Validate business rules
        if len(todo.title.strip()) == 0:
            raise HTTPException(
                status_code=422,  # Unprocessable Entity
                detail="Todo title cannot be empty"
            )
        
        # Check user permissions
        if not current_user.is_active:
            raise HTTPException(
                status_code=403,  # Forbidden
                detail="Account is disabled"
            )
        
        # Attempt to create todo
        db_todo = crud.create_todo(db, todo=todo, user_id=current_user.id)
        return db_todo
        
    except HTTPException:
        raise  # Re-raise HTTP exceptions
        
    except IntegrityError:
        raise HTTPException(
            status_code=409,  # Conflict
            detail="Todo with this title already exists"
        )
        
    except Exception as e:
        logger.error(f"Unexpected error creating todo: {e}")
        raise HTTPException(
            status_code=500,  # Internal Server Error
            detail="An unexpected error occurred"
        )
```

### Frontend Error Handling:
```javascript
const apiCall = async (url, options) => {
  try {
    const response = await fetch(url, options);
    
    // Check if response is ok
    if (!response.ok) {
      const errorData = await response.json();
      
      switch (response.status) {
        case 400:
          throw new Error(`Bad Request: ${errorData.detail}`);
        case 401:
          // Redirect to login
          window.location.href = '/login';
          return;
        case 403:
          throw new Error('You don\'t have permission to perform this action');
        case 404:
          throw new Error('Resource not found');
        case 422:
          throw new Error(`Validation Error: ${errorData.detail}`);
        case 429:
          throw new Error('Too many requests. Please wait before trying again.');
        case 500:
          throw new Error('Server error. Please try again later.');
        default:
          throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
    }
    
    return await response.json();
    
  } catch (error) {
    console.error('API Error:', error);
    throw error;
  }
};
```

## 🔄 API Versioning

### Why Version APIs?
- **Breaking changes**: New features might break existing clients
- **Backward compatibility**: Support old and new clients
- **Gradual migration**: Allow clients to upgrade at their own pace

### Versioning Strategies:

#### 1. URL Versioning (Common):
```
GET /v1/todos      → Version 1
GET /v2/todos      → Version 2
GET /v3/todos      → Version 3
```

#### 2. Header Versioning:
```http
GET /todos HTTP/1.1
Accept: application/vnd.api.v2+json
```

#### 3. Query Parameter:
```
GET /todos?version=2
```

### Our Implementation:
```python
# FastAPI versioning
app_v1 = FastAPI(title="Todo API v1")
app_v2 = FastAPI(title="Todo API v2")

# V1: Simple response
@app_v1.get("/todos")
async def get_todos_v1():
    return [{"id": 1, "title": "Todo 1"}]

# V2: Enhanced response with metadata
@app_v2.get("/todos")
async def get_todos_v2():
    return {
        "data": [{"id": 1, "title": "Todo 1", "created_at": "2025-09-27"}],
        "meta": {"total": 1, "version": "2.0"}
    }

# Mount both versions
app.mount("/v1", app_v1)
app.mount("/v2", app_v2)
```

## 🧪 API Testing

### 1. **Unit Testing**
```python
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_create_todo():
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Create test user and get token
        token = await get_test_token(client)
        
        # Test todo creation
        response = await client.post(
            "/todos",
            json={"title": "Test Todo", "priority": "high"},
            headers={"Authorization": f"Bearer {token}"}
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["title"] == "Test Todo"
        assert data["priority"] == "high"
        assert "id" in data
```

### 2. **Integration Testing**
```python
@pytest.mark.asyncio
async def test_todo_lifecycle():
    async with AsyncClient(app=app, base_url="http://test") as client:
        token = await get_test_token(client)
        headers = {"Authorization": f"Bearer {token}"}
        
        # Create todo
        create_response = await client.post("/todos", json={"title": "Test"}, headers=headers)
        todo_id = create_response.json()["id"]
        
        # Get todo
        get_response = await client.get(f"/todos/{todo_id}", headers=headers)
        assert get_response.status_code == 200
        
        # Update todo
        update_response = await client.patch(
            f"/todos/{todo_id}", 
            json={"completed": True}, 
            headers=headers
        )
        assert update_response.json()["completed"] is True
        
        # Delete todo
        delete_response = await client.delete(f"/todos/{todo_id}", headers=headers)
        assert delete_response.status_code == 200
```

### 3. **Load Testing**
```bash
# Using Apache Bench
ab -n 1000 -c 10 -H "Authorization: Bearer token123" http://localhost:8001/todos

# Using curl for quick tests
curl -X POST http://localhost:8001/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer token123" \
  -d '{"title": "Test Todo"}'
```

## 🎯 API Design Best Practices

### 1. **Consistent Naming**
```
✅ Good:
/users, /todos, /categories (plural nouns)
/users/123/todos (nested resources)

❌ Bad:
/getUsers, /createTodo (verbs in URLs)
/user, /todo (inconsistent singular/plural)
```

### 2. **Use HTTP Status Codes Correctly**
```python
# Success responses
return todo, 200           # OK (GET, PATCH)
return todo, 201           # Created (POST)
return None, 204           # No Content (DELETE)

# Error responses  
raise HTTPException(400)   # Bad Request (invalid input)
raise HTTPException(401)   # Unauthorized (authentication failed)
raise HTTPException(403)   # Forbidden (not allowed)
raise HTTPException(404)   # Not Found (resource doesn't exist)
raise HTTPException(422)   # Unprocessable Entity (validation failed)
raise HTTPException(500)   # Internal Server Error (server bug)
```

### 3. **Validate Input Data**
```python
from pydantic import BaseModel, Field, validator

class TodoCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    priority: str = Field("medium", regex="^(low|medium|high)$")
    
    @validator('title')
    def title_must_not_be_empty(cls, v):
        if not v.strip():
            raise ValueError('Title cannot be empty or just whitespace')
        return v.strip()
```

### 4. **Provide Meaningful Error Messages**
```python
# Bad
raise HTTPException(status_code=400, detail="Bad request")

# Good
raise HTTPException(
    status_code=422,
    detail={
        "message": "Validation failed",
        "errors": [
            {
                "field": "title",
                "message": "Title is required and cannot be empty"
            },
            {
                "field": "priority", 
                "message": "Priority must be one of: low, medium, high"
            }
        ]
    }
)
```

### 5. **Include Metadata in Responses**
```python
# List responses should include pagination info
{
    "data": [...],
    "meta": {
        "total": 150,
        "page": 1,
        "per_page": 20,
        "total_pages": 8
    },
    "links": {
        "first": "/todos?page=1",
        "last": "/todos?page=8",
        "next": "/todos?page=2",
        "prev": null
    }
}
```

## 🔮 Advanced API Concepts

### 1. **HATEOAS** (Hypermedia as the Engine of Application State)
```json
{
  "id": 123,
  "title": "Learn HATEOAS",
  "completed": false,
  "links": {
    "self": "/todos/123",
    "update": "/todos/123", 
    "delete": "/todos/123",
    "complete": "/todos/123/complete",
    "user": "/users/456"
  }
}
```

### 2. **API Gateway Pattern**
```
Client → API Gateway → User Service
                   → Todo Service  
                   → Auth Service
```

### 3. **Event-Driven APIs**
```python
# Webhook notifications
@app.post("/todos")
async def create_todo(todo: TodoCreate):
    db_todo = crud.create_todo(db, todo)
    
    # Notify other services
    await webhook_client.notify("todo.created", {
        "todo_id": db_todo.id,
        "user_id": db_todo.user_id
    })
    
    return db_todo
```

## 🎓 Key Takeaways

1. **APIs enable communication** between different software systems
2. **REST is a popular architectural style** for web APIs
3. **HTTP methods have specific meanings** - use them correctly
4. **Authentication and authorization** are crucial for API security
5. **Good documentation** makes APIs easy to use
6. **Error handling** should be comprehensive and user-friendly
7. **Performance optimization** is important for scalable APIs
8. **Testing ensures reliability** and prevents regressions
9. **Versioning enables evolution** without breaking existing clients
10. **Consistent design** makes APIs predictable and easy to learn

## 🛠️ Practical Exercise

Try these API operations with our todo app:

### 1. Test Authentication
```bash
# Login and get token
curl -X POST http://localhost:8001/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=your_username&password=your_password"
```

### 2. Create a Todo
```bash
# Use the token from step 1
curl -X POST http://localhost:8001/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"title": "API Testing", "priority": "high"}'
```

### 3. Get All Todos
```bash
curl -X GET http://localhost:8001/todos \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 4. Update a Todo
```bash
curl -X PATCH http://localhost:8001/todos/123 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"completed": true}'
```

### 5. Explore API Documentation
Visit: http://localhost:8001/docs

---

**Previous**: [Network & HTTP Basics](03-network-http-basics.md) | **Next**: [FastAPI Explained](05-fastapi-explained.md)