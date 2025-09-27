# Database Fundamentals: Where Your Data Lives

## 🤔 What is a Database?

Think of a database like a **digital filing cabinet**:
- **Traditional Filing Cabinet**: Papers in folders, organized in drawers
- **Database**: Data in tables, organized in schemas

But databases are much more powerful:
- **Instant Search**: Find any piece of information in milliseconds
- **Concurrent Access**: Multiple people can use it simultaneously
- **Data Integrity**: Ensures data is consistent and valid
- **Backup & Recovery**: Automatic protection against data loss

## 🗄️ Why Not Just Use Files?

You might wonder: "Why not just save data in text files?" Here's why databases are essential:

### File-Based Problems:
```
users.txt:
john,john@email.com,password123
jane,jane@email.com,pass456

todos.txt:
1,Learn databases,john,false
2,Build app,jane,true
```

**Problems:**
- ❌ No data validation (what if email is invalid?)
- ❌ Difficult to search (find all todos by john)
- ❌ Concurrent access issues (two people editing simultaneously)
- ❌ No data relationships (hard to link users to todos)
- ❌ Security risks (passwords in plain text)
- ❌ No backup/recovery mechanisms

### Database Solutions:
```sql
-- Users table with validation
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Todos table with relationships
CREATE TABLE todos (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    user_id INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);
```

**Benefits:**
- ✅ Data validation (email format, required fields)
- ✅ Fast searches with indexes
- ✅ Concurrent access with transactions
- ✅ Relationships between data
- ✅ Security features (encryption, access control)
- ✅ Automatic backups and recovery

## 📊 Types of Databases

### 1. **Relational Databases (SQL)**
**Think**: Excel spreadsheets with relationships

**Examples**: PostgreSQL, MySQL, SQLite
**Best For**: Structured data, complex relationships, transactions

```sql
-- Users table
| id | username | email           |
|----|----------|-----------------|
| 1  | john     | john@email.com  |
| 2  | jane     | jane@email.com  |

-- Todos table  
| id | title        | user_id | completed |
|----|--------------|---------|-----------|
| 1  | Learn SQL    | 1       | false     |
| 2  | Build app    | 1       | true      |
| 3  | Deploy app   | 2       | false     |
```

**Advantages:**
- Strong data consistency
- Complex queries with SQL
- ACID properties (reliability)
- Mature ecosystem

**Disadvantages:**
- Rigid structure
- Harder to scale horizontally
- Complex for non-tabular data

### 2. **Graph Databases**
**Think**: Social network connections

**Examples**: Neo4j, Amazon Neptune
**Best For**: Relationships, recommendations, social networks

```cypher
// Nodes and relationships
(john:User {name: "John"})
(jane:User {name: "Jane"})
(todo1:Todo {title: "Learn Neo4j"})

(john)-[:OWNS]->(todo1)
(john)-[:FRIENDS_WITH]->(jane)
```

**Advantages:**
- Natural for connected data
- Fast relationship traversal
- Flexible schema
- Great for recommendations

**Disadvantages:**
- Limited aggregation capabilities
- Newer technology (smaller community)
- Different query language (Cypher)

### 3. **Document Databases (NoSQL)**
**Think**: JSON documents in folders

**Examples**: MongoDB, CouchDB
**Best For**: Flexible schemas, rapid development

```json
// User document
{
  "_id": "user123",
  "username": "john",
  "email": "john@email.com",
  "todos": [
    {
      "title": "Learn MongoDB",
      "completed": false,
      "tags": ["database", "learning"]
    }
  ],
  "preferences": {
    "theme": "dark",
    "notifications": true
  }
}
```

**Advantages:**
- Flexible schema
- Natural for JSON/JavaScript
- Easy horizontal scaling
- Rapid development

**Disadvantages:**
- Less consistency guarantees
- Complex queries can be difficult
- Potential data duplication

### 4. **Key-Value Stores**
**Think**: Giant dictionary/hash map

**Examples**: Redis, Amazon DynamoDB
**Best For**: Caching, session storage, simple lookups

```python
# Redis example
cache = {
    "user:123:session": "abc123token",
    "user:123:preferences": '{"theme": "dark"}',
    "todo:456:cache": '{"title": "Learn Redis", "completed": false}'
}
```

**Advantages:**
- Extremely fast
- Simple to use
- Great for caching
- Horizontal scaling

**Disadvantages:**
- Limited query capabilities
- No relationships
- Simple data model only

## 🏗️ Our Database Architecture

In our todo application, we use **two different databases** for different purposes:

### PostgreSQL (Relational Database)
**Purpose**: Store structured, consistent data

```sql
-- What we store in PostgreSQL
Users Table:
- id (primary key)
- username (unique)
- email (unique, validated)
- hashed_password (encrypted)
- created_at (timestamp)

Todos Table:
- id (primary key)
- title (required)
- description (optional)
- completed (boolean)
- priority (enum: low/medium/high)
- user_id (foreign key to users)
- created_at (timestamp)
- updated_at (timestamp)

Categories Table:
- id (primary key)
- name (required)
- color (hex color code)
- user_id (foreign key to users)
```

### Neo4j (Graph Database)
**Purpose**: Store relationships and enable recommendations

```cypher
// What we store in Neo4j
User Nodes:
- id (matches PostgreSQL)
- username
- email

Todo Nodes:
- id (matches PostgreSQL)
- title

Category Nodes:
- id (matches PostgreSQL)
- name

Relationships:
- (User)-[:OWNS]->(Todo)
- (User)-[:CREATED]->(Category)
- (Todo)-[:BELONGS_TO]->(Category)
- (User)-[:SIMILAR_TO]->(User) // For recommendations
```

## 🔄 Why Use Two Databases?

### PostgreSQL Strengths:
- **ACID Transactions**: Ensure data consistency
- **Complex Queries**: Join multiple tables efficiently
- **Data Validation**: Enforce business rules
- **Mature Ecosystem**: Well-tested, reliable

### Neo4j Strengths:
- **Relationship Queries**: "Find friends of friends" in milliseconds
- **Recommendations**: "Users with similar todos might like..."
- **Pattern Matching**: Complex relationship patterns
- **Visualization**: See data connections graphically

### Combined Power:
```python
# Example: Create a new todo
def create_todo(todo_data, user_id):
    # 1. Save structured data to PostgreSQL
    db_todo = save_to_postgresql(todo_data, user_id)
    
    # 2. Create relationships in Neo4j
    create_neo4j_relationships(db_todo.id, user_id)
    
    # 3. Update recommendations
    update_user_similarities(user_id)
    
    return db_todo
```

## 🛠️ Database Operations (CRUD)

### Create (INSERT)
```sql
-- PostgreSQL
INSERT INTO todos (title, description, user_id, priority)
VALUES ('Learn Databases', 'Study PostgreSQL and Neo4j', 1, 'high');
```

```cypher
-- Neo4j
CREATE (t:Todo {id: 123, title: 'Learn Databases'})
MATCH (u:User {id: 1})
CREATE (u)-[:OWNS]->(t)
```

### Read (SELECT)
```sql
-- PostgreSQL: Get all todos for a user
SELECT t.*, u.username 
FROM todos t 
JOIN users u ON t.user_id = u.id 
WHERE u.id = 1
ORDER BY t.created_at DESC;
```

```cypher
-- Neo4j: Get todo recommendations
MATCH (u:User {id: 1})-[:OWNS]->(t:Todo)-[:BELONGS_TO]->(c:Category)
MATCH (c)<-[:BELONGS_TO]-(rec_todo:Todo)<-[:OWNS]-(other_user:User)
WHERE other_user.id <> 1
RETURN rec_todo.title as recommendation, c.name as category
LIMIT 5;
```

### Update (UPDATE)
```sql
-- PostgreSQL
UPDATE todos 
SET completed = true, updated_at = NOW()
WHERE id = 123;
```

```cypher
-- Neo4j
MATCH (t:Todo {id: 123})
SET t.completed = true;
```

### Delete (DELETE)
```sql
-- PostgreSQL
DELETE FROM todos WHERE id = 123;
```

```cypher
-- Neo4j
MATCH (t:Todo {id: 123})
DETACH DELETE t;
```

## 🔒 Database Security & Integrity

### 1. **Authentication & Authorization**
```sql
-- Create database user with limited permissions
CREATE USER todo_app WITH PASSWORD 'secure_password';
GRANT SELECT, INSERT, UPDATE, DELETE ON todos TO todo_app;
GRANT USAGE ON SEQUENCE todos_id_seq TO todo_app;
```

### 2. **Data Validation**
```sql
-- Constraints ensure data quality
ALTER TABLE users ADD CONSTRAINT valid_email 
CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

ALTER TABLE todos ADD CONSTRAINT valid_priority 
CHECK (priority IN ('low', 'medium', 'high'));
```

### 3. **Relationships & Foreign Keys**
```sql
-- Ensure referential integrity
ALTER TABLE todos ADD CONSTRAINT fk_user
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
```

### 4. **Transactions**
```python
# Ensure atomic operations
async def create_todo_with_relationship(todo_data, user_id):
    async with database.transaction():
        # If either operation fails, both are rolled back
        todo = await create_todo_in_postgres(todo_data, user_id)
        await create_relationship_in_neo4j(todo.id, user_id)
        return todo
```

## 📈 Database Performance

### 1. **Indexes**
Speed up data retrieval:

```sql
-- Speed up user lookups
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);

-- Speed up todo queries
CREATE INDEX idx_todos_user_id ON todos(user_id);
CREATE INDEX idx_todos_created_at ON todos(created_at DESC);
```

### 2. **Query Optimization**
```sql
-- Bad: Slow query
SELECT * FROM todos WHERE title LIKE '%learn%';

-- Good: Faster with index
SELECT * FROM todos WHERE user_id = 1 ORDER BY created_at DESC;

-- Better: Even faster with compound index
CREATE INDEX idx_todos_user_created ON todos(user_id, created_at DESC);
```

### 3. **Connection Pooling**
```python
# Instead of creating new connections for each request
# Use a connection pool
from sqlalchemy.pool import QueuePool

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=10,          # 10 persistent connections
    max_overflow=20,       # 20 additional connections if needed
    pool_timeout=30        # Wait 30s for available connection
)
```

## 🔄 Database Relationships

### One-to-Many (1:N)
```sql
-- One user has many todos
users (1) -----> (N) todos
```

### Many-to-Many (N:N)
```sql
-- Todos can belong to multiple categories
-- Categories can have multiple todos
todos (N) <-----> (N) categories

-- Implemented with junction table
CREATE TABLE todo_categories (
    todo_id INTEGER REFERENCES todos(id),
    category_id INTEGER REFERENCES categories(id),
    PRIMARY KEY (todo_id, category_id)
);
```

### One-to-One (1:1)
```sql
-- Each user has one profile
users (1) -----> (1) user_profiles
```

## 🧪 Database Design Best Practices

### 1. **Normalization**
Organize data to reduce redundancy:

```sql
-- Bad: Denormalized (data duplication)
CREATE TABLE todos (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200),
    username VARCHAR(50),    -- Duplicated data
    user_email VARCHAR(100), -- Duplicated data
    completed BOOLEAN
);

-- Good: Normalized (no duplication)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50),
    email VARCHAR(100)
);

CREATE TABLE todos (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200),
    user_id INTEGER REFERENCES users(id), -- Reference instead
    completed BOOLEAN
);
```

### 2. **Naming Conventions**
```sql
-- Use consistent, descriptive names
Tables: users, todos, categories (plural nouns)
Columns: user_id, created_at, is_active (descriptive)
Indexes: idx_users_email, idx_todos_user_id (prefixed)
```

### 3. **Data Types**
```sql
-- Choose appropriate data types
id SERIAL,                    -- Auto-incrementing integer
title VARCHAR(200),           -- Variable length string
completed BOOLEAN,            -- True/false
created_at TIMESTAMP,         -- Date and time
priority VARCHAR(10) CHECK... -- Constrained values
```

## 🔍 Database Monitoring

### 1. **Query Performance**
```sql
-- PostgreSQL: Find slow queries
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;
```

### 2. **Database Size**
```sql
-- Check database size
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### 3. **Connection Monitoring**
```python
# Monitor connection pool status
pool_status = engine.pool.status()
print(f"Pool size: {pool_status}")
```

## 🎯 Practical Exercise

Let's trace through a complete database operation:

### Scenario: User creates a todo with category

1. **Frontend Request**:
```javascript
const todo = {
    title: "Learn Database Design",
    description: "Study PostgreSQL and Neo4j",
    priority: "high",
    category: "Learning"
};
```

2. **Backend Processing**:
```python
async def create_todo_with_category(todo_data, user_id):
    # Start transaction
    async with database.transaction():
        # 1. Create or find category in PostgreSQL
        category = await get_or_create_category(todo_data.category, user_id)
        
        # 2. Create todo in PostgreSQL
        todo = Todo(
            title=todo_data.title,
            description=todo_data.description,
            priority=todo_data.priority,
            user_id=user_id
        )
        await todo.save()
        
        # 3. Link todo to category
        await link_todo_category(todo.id, category.id)
        
        # 4. Create nodes and relationships in Neo4j
        await neo4j_client.create_todo_node(todo.id, todo.title, user_id)
        await neo4j_client.link_todo_to_category(todo.id, category.id)
        
        return todo
```

3. **Database Operations**:
```sql
-- PostgreSQL operations
BEGIN;

-- Find or create category
INSERT INTO categories (name, user_id) 
VALUES ('Learning', 1) 
ON CONFLICT (name, user_id) DO NOTHING;

-- Create todo
INSERT INTO todos (title, description, priority, user_id)
VALUES ('Learn Database Design', 'Study PostgreSQL and Neo4j', 'high', 1)
RETURNING id;

-- Link todo to category  
INSERT INTO todo_categories (todo_id, category_id)
VALUES (123, 456);

COMMIT;
```

```cypher
-- Neo4j operations
CREATE (t:Todo {id: 123, title: 'Learn Database Design'})
MATCH (u:User {id: 1}), (c:Category {id: 456})
CREATE (u)-[:OWNS]->(t)-[:BELONGS_TO]->(c)
```

## 📚 Advanced Database Concepts

### 1. **Database Transactions (ACID)**
- **Atomicity**: All operations succeed or all fail
- **Consistency**: Data remains in valid state
- **Isolation**: Concurrent transactions don't interfere
- **Durability**: Committed data survives system failures

### 2. **Database Replication**
```
Master Database (Write)
    ↓ Replicate
Slave Database 1 (Read)
Slave Database 2 (Read)
```

### 3. **Database Sharding**
```
Users A-H → Database Shard 1
Users I-P → Database Shard 2  
Users Q-Z → Database Shard 3
```

### 4. **Caching Layers**
```
Application → Cache (Redis) → Database (PostgreSQL)
```

## 🔮 Database Evolution

### Schema Migrations
```python
# Alembic migration example
def upgrade():
    op.add_column('todos', sa.Column('due_date', sa.DateTime(), nullable=True))
    op.create_index('idx_todos_due_date', 'todos', ['due_date'])

def downgrade():
    op.drop_index('idx_todos_due_date', 'todos')
    op.drop_column('todos', 'due_date')
```

### Backup & Recovery
```bash
# PostgreSQL backup
pg_dump todoapp > backup.sql

# Restore
psql todoapp < backup.sql

# Neo4j backup
neo4j-admin dump --database=neo4j --to=backup.dump
```

## 🎓 Key Takeaways

1. **Databases are essential** for any application that stores data
2. **Different database types** solve different problems
3. **Relational databases** (PostgreSQL) excel at structured data and consistency
4. **Graph databases** (Neo4j) excel at relationships and recommendations
5. **Database design** impacts performance, scalability, and maintainability
6. **Security and performance** must be considered from the beginning
7. **Multiple databases** can work together in one application

---

**Previous**: [Backend Basics](01-backend-basics.md) | **Next**: [Network & HTTP Basics](03-network-http-basics.md)