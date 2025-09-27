# Network & HTTP Basics: How Computers Talk to Each Other

## 🌐 What is Networking?

Imagine the **postal system**:
- You write a letter (data)
- Put it in an envelope with an address (packet with IP address)
- Mail carrier delivers it through various routes (routers)
- Recipient receives and reads the letter (destination computer)

Computer networking works similarly, but **much faster**!

## 🏠 IP Addresses: Digital Addresses

Every device on a network has an **IP address** - like a home address:

### IPv4 Examples:
- `192.168.1.1` - Your home router
- `127.0.0.1` - Your own computer (localhost)
- `8.8.8.8` - Google's DNS server
- `172.217.12.142` - Google.com

### Special IP Addresses:
- **localhost/127.0.0.1**: Your own computer
- **192.168.x.x**: Private network (your home/office)
- **0.0.0.0**: All available interfaces

## 🚪 Ports: Apartment Numbers

If IP addresses are like building addresses, **ports** are like apartment numbers:

```
Computer (Building): 192.168.1.100
├── Port 80  (Apartment 80)  → Web Server (HTTP)
├── Port 443 (Apartment 443) → Secure Web Server (HTTPS)  
├── Port 22  (Apartment 22)  → SSH Server
├── Port 5432 (Apartment 5432) → PostgreSQL Database
└── Port 3000 (Apartment 3000) → Our React App
```

### Common Ports:
- **80**: HTTP (web traffic)
- **443**: HTTPS (secure web traffic)
- **22**: SSH (secure shell)
- **5432**: PostgreSQL database
- **7687**: Neo4j database
- **3000**: Development web servers
- **8000**: Alternative web servers

### Our Todo App Ports:
```
localhost:3001 → Next.js Frontend
localhost:8001 → FastAPI Backend  
localhost:5433 → PostgreSQL Database
localhost:7474 → Neo4j Browser
localhost:7687 → Neo4j Database
```

## 📦 How Data Travels: The Protocol Stack

### The Journey of a Web Request:

```
1. Application Layer (HTTP)
   ↓ "GET /todos"
   
2. Transport Layer (TCP)  
   ↓ Breaks into packets, adds port numbers
   
3. Network Layer (IP)
   ↓ Adds IP addresses for routing
   
4. Physical Layer
   ↓ Electrical signals over cables/WiFi
   
[Internet routing through multiple routers]
   
5. Destination receives packets
   ↓ Reassembles data
   
6. Server processes request
   ↓ Sends response back
```

### Real Example:
```
Your Browser → Router → ISP → Internet → Server's ISP → Server's Router → Server
```

## 🌐 HTTP: The Language of the Web

**HTTP (HyperText Transfer Protocol)** is how web browsers and servers communicate.

### HTTP Request Structure:
```http
POST /todos HTTP/1.1
Host: localhost:8001
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
Content-Type: application/json
Content-Length: 58

{"title": "Learn HTTP", "priority": "high", "completed": false}
```

**Breaking it down:**
- **Method**: POST (what action to perform)
- **Path**: /todos (what resource)
- **Headers**: Metadata about the request
- **Body**: The actual data being sent

### HTTP Response Structure:
```http
HTTP/1.1 201 Created
Content-Type: application/json
Content-Length: 156
Set-Cookie: session_id=abc123

{
  "id": 123,
  "title": "Learn HTTP",
  "priority": "high", 
  "completed": false,
  "created_at": "2025-09-27T10:30:00Z",
  "user_id": 1
}
```

**Breaking it down:**
- **Status Code**: 201 (Created - success)
- **Headers**: Metadata about the response
- **Body**: The actual data being returned

## 🛠️ HTTP Methods (Verbs)

### GET - Retrieve Data
```http
GET /todos HTTP/1.1
Host: localhost:8001
Authorization: Bearer token...
```
**Purpose**: Get all todos for the current user
**Safe**: Yes (doesn't change server state)
**Idempotent**: Yes (same result every time)

### POST - Create New Data
```http
POST /todos HTTP/1.1
Host: localhost:8001
Content-Type: application/json

{"title": "New Todo", "priority": "medium"}
```
**Purpose**: Create a new todo
**Safe**: No (changes server state)
**Idempotent**: No (creates new resource each time)

### PUT - Update/Replace Data
```http
PUT /todos/123 HTTP/1.1
Host: localhost:8001
Content-Type: application/json

{"title": "Updated Todo", "priority": "high", "completed": true}
```
**Purpose**: Replace entire todo with new data
**Safe**: No (changes server state)
**Idempotent**: Yes (same result if repeated)

### PATCH - Partially Update Data
```http
PATCH /todos/123 HTTP/1.1
Host: localhost:8001
Content-Type: application/json

{"completed": true}
```
**Purpose**: Update only specific fields
**Safe**: No (changes server state)
**Idempotent**: Yes (same result if repeated)

### DELETE - Remove Data
```http
DELETE /todos/123 HTTP/1.1
Host: localhost:8001
Authorization: Bearer token...
```
**Purpose**: Delete the todo
**Safe**: No (changes server state)
**Idempotent**: Yes (same result if repeated)

## 📊 HTTP Status Codes: Server Responses

### 2xx Success
- **200 OK**: Request successful
- **201 Created**: New resource created
- **204 No Content**: Success, but no data to return

### 3xx Redirection  
- **301 Moved Permanently**: Resource moved to new URL
- **302 Found**: Temporary redirect
- **304 Not Modified**: Use cached version

### 4xx Client Errors
- **400 Bad Request**: Invalid request data
- **401 Unauthorized**: Authentication required
- **403 Forbidden**: Access denied
- **404 Not Found**: Resource doesn't exist
- **422 Unprocessable Entity**: Validation failed

### 5xx Server Errors
- **500 Internal Server Error**: Server bug
- **502 Bad Gateway**: Upstream server error
- **503 Service Unavailable**: Server overloaded

### Our Todo App Examples:
```python
# FastAPI automatically returns appropriate status codes
@app.post("/todos", status_code=201)  # Created
async def create_todo(todo: TodoCreate):
    return {"id": 123, "title": todo.title}

@app.get("/todos/{todo_id}")
async def get_todo(todo_id: int):
    todo = find_todo(todo_id)
    if not todo:
        raise HTTPException(status_code=404, detail="Todo not found")  # Not Found
    return todo
```

## 🔒 HTTP Headers: Metadata

Headers provide additional information about requests and responses:

### Common Request Headers:
```http
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
Content-Type: application/json
Accept: application/json
User-Agent: Mozilla/5.0 (Chrome/91.0.4472.124)
Host: localhost:8001
```

### Common Response Headers:
```http
Content-Type: application/json
Content-Length: 1234
Set-Cookie: session_id=abc123; HttpOnly; Secure
Access-Control-Allow-Origin: *
Cache-Control: no-cache
```

### Security Headers:
```http
Access-Control-Allow-Origin: http://localhost:3001
Access-Control-Allow-Methods: GET, POST, PUT, DELETE
Access-Control-Allow-Headers: Authorization, Content-Type
Content-Security-Policy: default-src 'self'
```

## 🔐 HTTPS: Secure HTTP

**HTTPS = HTTP + TLS/SSL Encryption**

### HTTP (Insecure):
```
Browser → [Plain Text] → Router → [Anyone Can Read] → Server
```

### HTTPS (Secure):
```
Browser → [Encrypted] → Router → [Encrypted Data] → Server
                ↑                        ↑
           SSL Certificate         Only Server Can Decrypt
```

### Why HTTPS Matters:
- **Privacy**: Data can't be read by others
- **Integrity**: Data can't be modified in transit
- **Authentication**: Verify you're talking to the right server

### Our Development Setup:
```
http://localhost:3001  ← Development (HTTP is OK)
https://myapp.com      ← Production (HTTPS required)
```

## 🌍 DNS: Domain Name System

**DNS translates human-readable names to IP addresses:**

```
User types: api.myapp.com
     ↓
DNS Lookup: api.myapp.com → 172.217.12.142
     ↓  
Browser connects to: 172.217.12.142:443
```

### DNS Record Types:
- **A Record**: Domain → IPv4 address
- **AAAA Record**: Domain → IPv6 address  
- **CNAME Record**: Domain → Another domain
- **MX Record**: Email server information

### Our App's DNS Setup:
```
myapp.com          → 1.2.3.4 (Frontend server)
api.myapp.com      → 1.2.3.5 (Backend API server)
db.myapp.com       → 1.2.3.6 (Database server)
```

## 🔄 Request-Response Lifecycle

Let's trace a complete request through our todo app:

### 1. User Action
```javascript
// User clicks "Add Todo" button
fetch('http://localhost:8001/todos', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + localStorage.getItem('token')
  },
  body: JSON.stringify({
    title: 'Learn Networking',
    priority: 'high'
  })
});
```

### 2. Browser Processing
```
1. Parse URL: http://localhost:8001/todos
   - Protocol: http
   - Host: localhost  
   - Port: 8001
   - Path: /todos

2. DNS Resolution: localhost → 127.0.0.1

3. Create HTTP request:
   POST /todos HTTP/1.1
   Host: localhost:8001
   Content-Type: application/json
   Authorization: Bearer eyJ...
   
   {"title": "Learn Networking", "priority": "high"}
```

### 3. Network Transport
```
1. TCP Connection to 127.0.0.1:8001
2. Send HTTP request over TCP
3. Wait for response
```

### 4. Server Processing (FastAPI)
```python
@app.post("/todos")
async def create_todo(
    todo: TodoCreate,
    current_user: User = Depends(get_current_user)
):
    # 1. Validate JWT token
    # 2. Validate todo data with Pydantic
    # 3. Save to PostgreSQL
    # 4. Create Neo4j relationships
    # 5. Return response
    return {"id": 123, "title": todo.title, "priority": todo.priority}
```

### 5. Server Response
```http
HTTP/1.1 201 Created
Content-Type: application/json
Content-Length: 98
Access-Control-Allow-Origin: http://localhost:3001

{
  "id": 123,
  "title": "Learn Networking",
  "priority": "high",
  "completed": false,
  "created_at": "2025-09-27T10:30:00Z"
}
```

### 6. Browser Processing
```javascript
// JavaScript receives response
.then(response => response.json())
.then(todo => {
    // Update UI with new todo
    addTodoToList(todo);
})
.catch(error => {
    console.error('Error:', error);
});
```

## 🔗 WebSockets: Real-time Communication

While HTTP is request-response, **WebSockets** enable real-time communication:

### HTTP (Traditional):
```
Client → Request  → Server
Client ← Response ← Server
Client → Request  → Server  
Client ← Response ← Server
```

### WebSocket (Real-time):
```
Client ↔ Persistent Connection ↔ Server
       ↑ Data flows both ways ↑
```

### Use Cases:
- Chat applications
- Live notifications
- Real-time collaboration
- Live data feeds

### Example Implementation:
```python
# FastAPI WebSocket
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    while True:
        # Send real-time todo updates
        data = await websocket.receive_text()
        await websocket.send_text(f"Todo updated: {data}")
```

## 🚀 Performance & Optimization

### 1. HTTP/2 Benefits:
- **Multiplexing**: Multiple requests over one connection
- **Header Compression**: Smaller headers
- **Server Push**: Server sends resources before requested

### 2. Caching Strategies:
```http
# Browser caching
Cache-Control: max-age=3600  # Cache for 1 hour
ETag: "abc123"              # Version identifier

# CDN caching  
Cache-Control: public, max-age=86400  # Cache for 1 day
```

### 3. Compression:
```http
# Request
Accept-Encoding: gzip, deflate, br

# Response  
Content-Encoding: gzip
Content-Length: 1234  # Compressed size
```

### 4. Keep-Alive Connections:
```http
Connection: keep-alive
Keep-Alive: timeout=5, max=1000
```

## 🛡️ Security Considerations

### 1. CORS (Cross-Origin Resource Sharing)
```python
# FastAPI CORS setup
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3001"],  # Frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### 2. Rate Limiting:
```python
# Limit requests per user
@app.middleware("http")
async def rate_limit(request: Request, call_next):
    client_ip = request.client.host
    if too_many_requests(client_ip):
        return Response(status_code=429)  # Too Many Requests
    return await call_next(request)
```

### 3. Input Validation:
```python
# Pydantic automatically validates
class TodoCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    priority: str = Field(..., regex="^(low|medium|high)$")
```

## 🏗️ Network Infrastructure

### Development Setup:
```
Your Computer:
├── localhost:3001 (Next.js Frontend)
├── localhost:8001 (FastAPI Backend)
├── localhost:5433 (PostgreSQL)
└── localhost:7474 (Neo4j)
```

### Production Setup:
```
Internet
    ↓
Load Balancer (AWS ALB)
    ↓
Multiple Web Servers
    ↓
Database Cluster
```

### Docker Networking:
```yaml
# docker-compose.yml
networks:
  todo_network:
    driver: bridge

services:
  backend:
    networks:
      - todo_network
    # Can reach other services by name
    # postgresql://postgres:5432/todoapp
```

## 📊 Network Monitoring & Debugging

### 1. Browser Developer Tools:
```
F12 → Network Tab
- See all HTTP requests
- Check response times
- Inspect headers and bodies
- Monitor WebSocket connections
```

### 2. Command Line Tools:
```bash
# Test HTTP endpoints
curl -X POST http://localhost:8001/todos \
  -H "Content-Type: application/json" \
  -d '{"title": "Test Todo"}'

# Check if port is open
telnet localhost 8001

# Trace network route
traceroute google.com

# DNS lookup
nslookup api.myapp.com
```

### 3. Application Monitoring:
```python
# FastAPI request logging
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    logger.info(f"{request.method} {request.url} - {response.status_code} - {process_time:.3f}s")
    return response
```

## 🌐 Network Types & Topologies

### 1. Network Types:
- **LAN (Local Area Network)**: Your home/office network
- **WAN (Wide Area Network)**: Internet, connects LANs
- **VPN (Virtual Private Network)**: Secure tunnel over internet

### 2. Cloud Networking:
```
Internet Gateway
    ↓
VPC (Virtual Private Cloud)
    ├── Public Subnet (Web Servers)
    └── Private Subnet (Databases)
```

## 🎯 Practical Exercise

Let's monitor network traffic in our todo app:

### 1. Open Browser Dev Tools
```
1. Open http://localhost:3001
2. Press F12 → Network tab
3. Clear existing requests
4. Try to login
5. Watch the network requests
```

### 2. Analyze the Requests:
```
POST /token
- Request: username/password
- Response: JWT token

GET /users/me  
- Request: Authorization header with token
- Response: User information

GET /todos
- Request: Authorization header
- Response: List of todos
```

### 3. Test Error Conditions:
```bash
# Test with invalid token
curl -H "Authorization: Bearer invalid_token" \
     http://localhost:8001/users/me

# Expected: 401 Unauthorized
```

### 4. Monitor Database Connections:
```bash
# Check active connections to PostgreSQL
docker exec todo_postgres_local psql -U postgres -c "SELECT * FROM pg_stat_activity;"
```

## 🔮 Advanced Networking Concepts

### 1. Load Balancing:
```
Client Requests
       ↓
Load Balancer
   ↙     ↓     ↘
Server1 Server2 Server3
```

### 2. CDN (Content Delivery Network):
```
User in Tokyo → Tokyo CDN Server (cached content)
User in NYC   → NYC CDN Server (cached content)
Origin Server → Only serves dynamic content
```

### 3. Microservices Communication:
```
API Gateway
    ↓
User Service ← HTTP → Auth Service
    ↓                     ↓
Todo Service ← HTTP → Category Service
```

## 🎓 Key Takeaways

1. **Networking enables communication** between computers
2. **IP addresses and ports** identify specific services
3. **HTTP is the foundation** of web communication
4. **Status codes communicate** the result of operations
5. **Headers provide metadata** about requests and responses
6. **HTTPS encrypts** communication for security
7. **Different protocols** serve different purposes (HTTP vs WebSocket)
8. **Performance and security** must be considered in network design

## 🔍 Common Network Issues & Solutions

### Issue: CORS Errors
```
Access to fetch at 'http://localhost:8001' from origin 'http://localhost:3001' 
has been blocked by CORS policy
```
**Solution**: Configure CORS in FastAPI
```python
app.add_middleware(CORSMiddleware, allow_origins=["http://localhost:3001"])
```

### Issue: Connection Refused
```
Error: connect ECONNREFUSED 127.0.0.1:8001
```
**Solution**: Check if backend server is running on correct port

### Issue: Timeout Errors
```
Error: timeout of 5000ms exceeded
```
**Solution**: Optimize database queries, add caching, or increase timeout

---

**Previous**: [Database Fundamentals](02-database-fundamentals.md) | **Next**: [API Concepts](04-api-concepts.md)