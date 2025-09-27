# PostgreSQL Deep Dive: Mastering Relational Databases

## 🐘 What is PostgreSQL?

**PostgreSQL** (often called "Postgres") is like a **highly organized digital filing system** that:

- **Stores data reliably** with ACID guarantees
- **Handles complex relationships** between different types of data
- **Scales to handle millions of records** efficiently
- **Provides advanced features** like JSON support, full-text search, and custom functions
- **Ensures data integrity** with constraints and transactions

Think of it as the **Swiss Army knife of databases** - powerful, reliable, and feature-rich.

## 🏛️ PostgreSQL Architecture

### Core Components:
```
PostgreSQL Instance
├── Databases (todoapp, testdb, etc.)
│   ├── Schemas (public, auth, analytics)
│   │   ├── Tables (users, todos, categories)
│   │   ├── Indexes (for fast queries)
│   │   ├── Views (virtual tables)
│   │   └── Functions (stored procedures)
│   └── Roles & Permissions
├── Connection Pool
├── Write-Ahead Log (WAL)
└── Buffer Cache
```

### Our Todo App Database:
```sql
-- Database: todoapp
-- Schema: public (default)

Tables:
├── users (id, username, email, password_hash, created_at)
├── todos (id, title, description, completed, priority, user_id, created_at)
└── categories (id, name, color, user_id, created_at)

Relationships:
├── users → todos (one-to-many)
├── users → categories (one-to-many)
└── todos ↔ categories (many-to-many via junction table)
```

## 📊 Data Types in PostgreSQL

### Basic Types:
```sql
-- Numeric types
id SERIAL PRIMARY KEY,              -- Auto-incrementing integer
age INTEGER,                        -- Whole numbers
price DECIMAL(10,2),               -- Exact decimal (money)
rating FLOAT,                      -- Approximate decimal

-- Text types  
username VARCHAR(50),              -- Variable length string
description TEXT,                  -- Unlimited text
status CHAR(1),                   -- Fixed length string

-- Date/Time types
created_at TIMESTAMP,             -- Date and time
birth_date DATE,                  -- Date only
meeting_time TIME,                -- Time only
updated_at TIMESTAMPTZ,           -- Timezone-aware timestamp

-- Boolean
is_active BOOLEAN DEFAULT TRUE,

-- JSON (PostgreSQL specialty!)
metadata JSONB,                   -- Binary JSON (faster)
settings JSON                     -- Text JSON
```

### Advanced Types:
```sql
-- Arrays
tags TEXT[],                      -- Array of text
scores INTEGER[],                 -- Array of integers

-- Custom types
CREATE TYPE priority_level AS ENUM ('low', 'medium', 'high');
priority priority_level DEFAULT 'medium',

-- UUID (Universally Unique Identifier)
uuid UUID DEFAULT gen_random_uuid(),

-- Network types
ip_address INET,                  -- IP address
mac_address MACADDR              -- MAC address
```

## 🗂️ Table Design Best Practices

### 1. **Primary Keys**
```sql
-- Auto-incrementing primary key (recommended)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,        -- PostgreSQL generates unique IDs
    username VARCHAR(50) NOT NULL
);

-- UUID primary key (for distributed systems)
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);
```

### 2. **Foreign Keys & Relationships**
```sql
-- One-to-Many: User has many todos
CREATE TABLE todos (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    user_id INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Many-to-Many: Todos can have multiple categories
CREATE TABLE todo_categories (
    todo_id INTEGER REFERENCES todos(id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES categories(id) ON DELETE CASCADE,
    PRIMARY KEY (todo_id, category_id)  -- Composite primary key
);
```

### 3. **Constraints for Data Integrity**
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,     -- Must be unique
    email VARCHAR(100) NOT NULL UNIQUE,       -- Must be unique  
    age INTEGER CHECK (age >= 0 AND age <= 150), -- Valid age range
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    
    -- Table-level constraints
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);
```

### 4. **Indexes for Performance**
```sql
-- Single column indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_todos_user_id ON todos(user_id);

-- Composite indexes (order matters!)
CREATE INDEX idx_todos_user_created ON todos(user_id, created_at DESC);

-- Partial indexes (only index certain rows)
CREATE INDEX idx_active_todos ON todos(user_id) WHERE completed = FALSE;

-- Full-text search indexes
CREATE INDEX idx_todos_search ON todos USING gin(to_tsvector('english', title || ' ' || COALESCE(description, '')));
```

## 🔍 Advanced Queries

### 1. **JOIN Operations**
```sql
-- Inner JOIN (only matching records)
SELECT u.username, t.title, t.completed
FROM users u
INNER JOIN todos t ON u.id = t.user_id;

-- LEFT JOIN (all users, even without todos)
SELECT u.username, COUNT(t.id) as todo_count
FROM users u
LEFT JOIN todos t ON u.id = t.user_id
GROUP BY u.id, u.username;

-- Complex JOIN with categories
SELECT 
    u.username,
    t.title,
    ARRAY_AGG(c.name) as categories
FROM users u
JOIN todos t ON u.id = t.user_id
LEFT JOIN todo_categories tc ON t.id = tc.todo_id
LEFT JOIN categories c ON tc.category_id = c.id
GROUP BY u.id, u.username, t.id, t.title;
```

### 2. **Aggregations & Window Functions**
```sql
-- Basic aggregations
SELECT 
    user_id,
    COUNT(*) as total_todos,
    COUNT(*) FILTER (WHERE completed = TRUE) as completed_todos,
    AVG(CASE WHEN priority = 'high' THEN 3 
             WHEN priority = 'medium' THEN 2 
             ELSE 1 END) as avg_priority
FROM todos
GROUP BY user_id;

-- Window functions (advanced!)
SELECT 
    id,
    title,
    user_id,
    created_at,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at) as todo_sequence,
    LAG(created_at) OVER (PARTITION BY user_id ORDER BY created_at) as prev_todo_time
FROM todos;
```

### 3. **Common Table Expressions (CTEs)**
```sql
-- Recursive CTE for hierarchical data
WITH RECURSIVE category_tree AS (
    -- Base case: top-level categories
    SELECT id, name, parent_id, 1 as level
    FROM categories 
    WHERE parent_id IS NULL
    
    UNION ALL
    
    -- Recursive case: child categories
    SELECT c.id, c.name, c.parent_id, ct.level + 1
    FROM categories c
    JOIN category_tree ct ON c.parent_id = ct.id
)
SELECT * FROM category_tree ORDER BY level, name;

-- Regular CTE for complex queries
WITH user_stats AS (
    SELECT 
        user_id,
        COUNT(*) as total_todos,
        AVG(EXTRACT(EPOCH FROM (completed_at - created_at))/3600) as avg_completion_hours
    FROM todos
    WHERE completed = TRUE
    GROUP BY user_id
)
SELECT u.username, us.total_todos, us.avg_completion_hours
FROM users u
JOIN user_stats us ON u.id = us.user_id
WHERE us.total_todos > 10;
```

## 🔧 Performance Optimization

### 1. **Query Analysis with EXPLAIN**
```sql
-- See query execution plan
EXPLAIN (ANALYZE, BUFFERS) 
SELECT t.title, u.username 
FROM todos t 
JOIN users u ON t.user_id = u.id 
WHERE t.created_at > '2025-01-01';

-- Look for:
-- • Sequential Scans (bad for large tables)
-- • Index Scans (good)
-- • Hash Joins vs Nested Loops
-- • High cost numbers
```

### 2. **Index Optimization**
```sql
-- Check index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- Find unused indexes
SELECT 
    schemaname,
    tablename,
    indexname
FROM pg_stat_user_indexes
WHERE idx_scan = 0;

-- Index size
SELECT 
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) as size
FROM pg_stat_user_indexes
ORDER BY pg_relation_size(indexrelid) DESC;
```

### 3. **Query Optimization Techniques**
```sql
-- Bad: Inefficient query
SELECT * FROM todos WHERE LOWER(title) LIKE '%urgent%';

-- Good: Use functional index
CREATE INDEX idx_todos_title_lower ON todos(LOWER(title));
SELECT * FROM todos WHERE LOWER(title) LIKE '%urgent%';

-- Better: Use full-text search
CREATE INDEX idx_todos_search ON todos USING gin(to_tsvector('english', title));
SELECT * FROM todos WHERE to_tsvector('english', title) @@ to_tsquery('urgent');

-- Bad: N+1 query problem
-- (Multiple queries in a loop)

-- Good: Single query with JOIN
SELECT u.username, ARRAY_AGG(t.title) as todo_titles
FROM users u
LEFT JOIN todos t ON u.id = t.user_id
GROUP BY u.id, u.username;
```

## 🔒 Transactions & ACID Properties

### 1. **Basic Transactions**
```sql
-- Explicit transaction
BEGIN;
    INSERT INTO users (username, email) VALUES ('john', 'john@example.com');
    INSERT INTO todos (title, user_id) VALUES ('Learn PostgreSQL', LASTVAL());
COMMIT;  -- Make changes permanent

-- Rollback on error
BEGIN;
    INSERT INTO users (username, email) VALUES ('jane', 'jane@example.com');
    -- If this fails, everything rolls back
    INSERT INTO todos (title, user_id) VALUES ('', LASTVAL());  -- Invalid data
ROLLBACK;  -- Undo all changes
```

### 2. **Isolation Levels**
```sql
-- Read Committed (default)
BEGIN ISOLATION LEVEL READ COMMITTED;
    -- Can see committed changes from other transactions
COMMIT;

-- Repeatable Read
BEGIN ISOLATION LEVEL REPEATABLE READ;
    -- Consistent snapshot throughout transaction
COMMIT;

-- Serializable (strongest isolation)
BEGIN ISOLATION LEVEL SERIALIZABLE;
    -- Prevents all anomalies
COMMIT;
```

### 3. **Savepoints**
```sql
BEGIN;
    INSERT INTO users (username, email) VALUES ('bob', 'bob@example.com');
    SAVEPOINT user_created;
    
    -- Try something risky
    INSERT INTO todos (title, user_id) VALUES ('Risky todo', CURRVAL('users_id_seq'));
    
    -- If we need to undo just this part:
    ROLLBACK TO SAVEPOINT user_created;
    
    -- User still exists, but todo was rolled back
COMMIT;
```

## 📊 Advanced PostgreSQL Features

### 1. **JSON Support**
```sql
-- Store JSON data
CREATE TABLE user_preferences (
    user_id INTEGER REFERENCES users(id),
    settings JSONB  -- JSONB is faster than JSON
);

-- Insert JSON
INSERT INTO user_preferences (user_id, settings) VALUES 
(1, '{"theme": "dark", "notifications": {"email": true, "push": false}}');

-- Query JSON data
SELECT settings->>'theme' as theme
FROM user_preferences 
WHERE user_id = 1;

-- Complex JSON queries
SELECT user_id
FROM user_preferences
WHERE settings->'notifications'->>'email' = 'true';

-- JSON path queries
SELECT user_id, jsonb_path_query(settings, '$.notifications.email') as email_enabled
FROM user_preferences;
```

### 2. **Full-Text Search**
```sql
-- Create search index
CREATE INDEX idx_todos_fts ON todos USING gin(to_tsvector('english', title || ' ' || COALESCE(description, '')));

-- Simple search
SELECT id, title, 
       ts_rank(to_tsvector('english', title || ' ' || COALESCE(description, '')), 
               to_tsquery('english', 'important & task')) as rank
FROM todos
WHERE to_tsvector('english', title || ' ' || COALESCE(description, '')) 
      @@ to_tsquery('english', 'important & task')
ORDER BY rank DESC;

-- Phrase search
SELECT * FROM todos
WHERE to_tsvector('english', title) @@ phraseto_tsquery('english', 'urgent task');
```

### 3. **Custom Functions**
```sql
-- Create a function to calculate todo completion rate
CREATE OR REPLACE FUNCTION user_completion_rate(user_id_param INTEGER)
RETURNS DECIMAL(5,2) AS $$
DECLARE
    total_todos INTEGER;
    completed_todos INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_todos
    FROM todos WHERE user_id = user_id_param;
    
    SELECT COUNT(*) INTO completed_todos
    FROM todos WHERE user_id = user_id_param AND completed = TRUE;
    
    IF total_todos = 0 THEN
        RETURN 0;
    END IF;
    
    RETURN (completed_todos::DECIMAL / total_todos) * 100;
END;
$$ LANGUAGE plpgsql;

-- Use the function
SELECT username, user_completion_rate(id) as completion_percentage
FROM users;
```

### 4. **Triggers**
```sql
-- Create trigger function
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER update_todos_modtime
    BEFORE UPDATE ON todos
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

-- Now updated_at is automatically set on every update
UPDATE todos SET completed = TRUE WHERE id = 1;
```

## 🔄 Database Migrations with Alembic

### 1. **Setting up Alembic**
```python
# alembic/env.py
from sqlalchemy import engine_from_config
from alembic import context
from app.models import Base  # Import your models

target_metadata = Base.metadata

# In our FastAPI app
from alembic.config import Config
from alembic import command

def run_migrations():
    alembic_cfg = Config("alembic.ini")
    command.upgrade(alembic_cfg, "head")
```

### 2. **Creating Migrations**
```bash
# Create a new migration
alembic revision --autogenerate -m "Add todo categories table"

# Generated migration file
def upgrade():
    op.create_table(
        'categories',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('color', sa.String(7), nullable=True),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )

def downgrade():
    op.drop_table('categories')
```

### 3. **Complex Migrations**
```python
# Data migration example
def upgrade():
    # Create new column
    op.add_column('todos', sa.Column('priority_level', sa.Integer(), nullable=True))
    
    # Migrate existing data
    connection = op.get_bind()
    connection.execute("""
        UPDATE todos 
        SET priority_level = CASE 
            WHEN priority = 'high' THEN 3
            WHEN priority = 'medium' THEN 2
            WHEN priority = 'low' THEN 1
            ELSE 2
        END
    """)
    
    # Make column non-nullable
    op.alter_column('todos', 'priority_level', nullable=False)
    
    # Drop old column
    op.drop_column('todos', 'priority')
```

## 🔧 Connection Management

### 1. **Connection Pooling with SQLAlchemy**
```python
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

# Create engine with connection pool
engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=10,              # Number of persistent connections
    max_overflow=20,           # Additional connections when needed
    pool_timeout=30,           # Wait time for connection
    pool_recycle=3600,         # Recycle connections after 1 hour
    pool_pre_ping=True         # Validate connections before use
)

# Monitor connection pool
def get_pool_status():
    pool = engine.pool
    return {
        "pool_size": pool.size(),
        "checked_in": pool.checkedin(),
        "checked_out": pool.checkedout(),
        "overflow": pool.overflow(),
        "total": pool.size() + pool.overflow()
    }
```

### 2. **Async Connection Management**
```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession

# Async engine
async_engine = create_async_engine(
    "postgresql+asyncpg://user:pass@localhost/db",
    pool_size=20,
    max_overflow=30
)

# Async session dependency
async def get_async_db():
    async with AsyncSession(async_engine) as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
```

## 📊 Monitoring & Maintenance

### 1. **Performance Monitoring**
```sql
-- Active queries
SELECT 
    pid,
    now() - pg_stat_activity.query_start AS duration,
    query 
FROM pg_stat_activity 
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';

-- Database size
SELECT 
    pg_database.datname,
    pg_size_pretty(pg_database_size(pg_database.datname)) AS size
FROM pg_database;

-- Table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS index_size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### 2. **Index Maintenance**
```sql
-- Find bloated indexes
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE idx_scan < 50 AND pg_relation_size(indexrelid) > 1024*1024;  -- Unused indexes > 1MB

-- Rebuild index if needed
REINDEX INDEX CONCURRENTLY idx_todos_user_created;
```

### 3. **Backup & Recovery**
```bash
# Full database backup
pg_dump -h localhost -U postgres -d todoapp > backup_$(date +%Y%m%d).sql

# Compressed backup
pg_dump -h localhost -U postgres -d todoapp | gzip > backup_$(date +%Y%m%d).sql.gz

# Restore database
psql -h localhost -U postgres -d todoapp_restored < backup_20250927.sql

# Point-in-time recovery (requires WAL archiving)
pg_basebackup -D /backup/base -Ft -z -P -h localhost -U postgres
```

## 🛡️ Security Best Practices

### 1. **User Management**
```sql
-- Create application user with limited privileges
CREATE USER todoapp_user WITH PASSWORD 'secure_password';

-- Grant only necessary permissions
GRANT CONNECT ON DATABASE todoapp TO todoapp_user;
GRANT USAGE ON SCHEMA public TO todoapp_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO todoapp_user;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO todoapp_user;

-- Row Level Security (RLS)
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;

CREATE POLICY todos_user_policy ON todos
    FOR ALL TO todoapp_user
    USING (user_id = current_setting('app.current_user_id')::INTEGER);
```

### 2. **SQL Injection Prevention**
```python
# Bad: SQL injection vulnerable
def get_user_todos(user_id, status):
    query = f"SELECT * FROM todos WHERE user_id = {user_id} AND status = '{status}'"
    return db.execute(query)

# Good: Parameterized queries
def get_user_todos(user_id, status):
    query = "SELECT * FROM todos WHERE user_id = %s AND status = %s"
    return db.execute(query, (user_id, status))

# SQLAlchemy way (even better)
def get_user_todos(db: Session, user_id: int, status: str):
    return db.query(Todo).filter(
        Todo.user_id == user_id,
        Todo.status == status
    ).all()
```

## 🎯 Real-World Scenarios

### 1. **Handling High Concurrency**
```sql
-- Use advisory locks for critical sections
SELECT pg_advisory_lock(12345);
-- Critical section: update counters, etc.
SELECT pg_advisory_unlock(12345);

-- Optimistic locking with version columns
ALTER TABLE todos ADD COLUMN version INTEGER DEFAULT 1;

-- In application code:
UPDATE todos 
SET title = %s, version = version + 1
WHERE id = %s AND version = %s;  -- Only update if version matches
```

### 2. **Data Archiving**
```sql
-- Partition large tables by date
CREATE TABLE todos_2025 PARTITION OF todos
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- Archive old data
CREATE TABLE todos_archived AS 
SELECT * FROM todos WHERE created_at < '2024-01-01';

DELETE FROM todos WHERE created_at < '2024-01-01';
```

### 3. **Performance at Scale**
```sql
-- Materialized views for expensive queries
CREATE MATERIALIZED VIEW user_todo_stats AS
SELECT 
    user_id,
    COUNT(*) as total_todos,
    COUNT(*) FILTER (WHERE completed = TRUE) as completed_todos,
    AVG(EXTRACT(EPOCH FROM (completed_at - created_at))/3600) as avg_completion_hours
FROM todos
GROUP BY user_id;

-- Refresh periodically
REFRESH MATERIALIZED VIEW CONCURRENTLY user_todo_stats;
```

## 🎓 Key Takeaways

1. **PostgreSQL is incredibly powerful** - way beyond basic CRUD operations
2. **Proper indexing is crucial** - monitor and optimize regularly
3. **Transactions ensure data integrity** - use them for multi-step operations
4. **JSON support bridges SQL and NoSQL** - best of both worlds
5. **Performance tuning requires measurement** - always EXPLAIN your queries
6. **Security must be built-in** - parameterized queries, proper permissions
7. **Scaling requires planning** - partitioning, archiving, read replicas
8. **Maintenance is ongoing** - backups, monitoring, index management

## 🛠️ Practical Exercise

Let's optimize a real query from our todo app:

### 1. Start with a Slow Query:
```sql
-- This might be slow with lots of data
SELECT u.username, t.title, t.created_at
FROM users u
JOIN todos t ON u.id = t.user_id
WHERE t.title ILIKE '%important%'
ORDER BY t.created_at DESC
LIMIT 20;
```

### 2. Analyze Performance:
```sql
EXPLAIN (ANALYZE, BUFFERS) 
SELECT u.username, t.title, t.created_at
FROM users u
JOIN todos t ON u.id = t.user_id
WHERE t.title ILIKE '%important%'
ORDER BY t.created_at DESC
LIMIT 20;
```

### 3. Add Optimizations:
```sql
-- Add indexes
CREATE INDEX idx_todos_title_gin ON todos USING gin(title gin_trgm_ops);
CREATE INDEX idx_todos_created_desc ON todos(created_at DESC);

-- Rewrite query if needed
SELECT u.username, t.title, t.created_at
FROM todos t
JOIN users u ON u.id = t.user_id
WHERE t.title % 'important'  -- Use similarity operator with trigram index
ORDER BY t.created_at DESC
LIMIT 20;
```

---

**Previous**: [FastAPI Explained](05-fastapi-explained.md) | **Next**: [Neo4j Graph Database](07-neo4j-graph-database.md)