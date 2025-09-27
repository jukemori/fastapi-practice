# Neo4j Graph Database: Understanding Connected Data

## 🕸️ What is Neo4j?

**Neo4j** is like a **social network for your data** where:

- **Nodes** are entities (users, todos, categories)
- **Relationships** are connections between entities (OWNS, BELONGS_TO, SIMILAR_TO)
- **Queries traverse paths** rather than joining tables
- **Patterns emerge naturally** from connected data

Think of it as **mapping the relationships** in your data, just like how LinkedIn maps professional connections or Facebook maps social relationships.

## 🧠 Graph vs Relational: A Mental Model

### Relational Database (PostgreSQL):
```
Think: Filing cabinet with cross-references

Users Table:     Todos Table:
[id][name]       [id][title][user_id]
[1 ][John]       [1 ][Learn][1      ]
[2 ][Jane]       [2 ][Code ][1      ]
                 [3 ][Test ][2      ]

To find John's todos: JOIN users and todos on user_id
```

### Graph Database (Neo4j):
```
Think: Mind map with direct connections

    (John)─[:OWNS]→(Learn)
      │             ↓
      └─[:OWNS]→(Code)
      
    (Jane)─[:OWNS]→(Test)

To find John's todos: Follow OWNS relationships from John
```

## 🏗️ Graph Database Concepts

### 1. **Nodes (Entities)**
```cypher
// User node
(u:User {
    id: 123,
    username: "john_doe", 
    email: "john@example.com"
})

// Todo node  
(t:Todo {
    id: 456,
    title: "Learn Neo4j",
    priority: "high"
})

// Category node
(c:Category {
    id: 789,
    name: "Learning",
    color: "#3B82F6"
})
```

### 2. **Relationships (Connections)**
```cypher
// User owns todos
(user)-[:OWNS]->(todo)

// Todo belongs to category
(todo)-[:BELONGS_TO]->(category)

// Users are similar (for recommendations)
(user1)-[:SIMILAR_TO {score: 0.85}]->(user2)

// Users follow each other
(user1)-[:FOLLOWS]->(user2)
```

### 3. **Properties on Relationships**
```cypher
// Relationships can have properties too!
(john)-[:COMPLETED {completed_at: "2025-09-27", time_taken: 120}]->(todo)
(alice)-[:RATED {score: 5, review: "Great tutorial!"}]->(course)
```

## 🎯 Why Use Neo4j in Our Todo App?

### 1. **Recommendations**
```cypher
// Find todos that similar users have created
MATCH (me:User {id: 123})-[:OWNS]->(my_todo:Todo)-[:BELONGS_TO]->(category:Category)
MATCH (category)<-[:BELONGS_TO]-(recommended_todo:Todo)<-[:OWNS]-(other_user:User)
WHERE other_user.id <> 123
RETURN recommended_todo.title, category.name, COUNT(*) as relevance
ORDER BY relevance DESC
LIMIT 5
```

### 2. **Social Features**
```cypher
// Find friends of friends who have similar interests
MATCH (me:User {id: 123})-[:FOLLOWS]->(friend:User)-[:FOLLOWS]->(fof:User)
MATCH (me)-[:OWNS]->(my_todo:Todo)-[:BELONGS_TO]->(category:Category)
MATCH (fof)-[:OWNS]->(their_todo:Todo)-[:BELONGS_TO]->(category)
WHERE fof.id <> 123
RETURN fof.username, COUNT(DISTINCT category) as shared_interests
ORDER BY shared_interests DESC
```

### 3. **Analytics & Insights**
```cypher
// Find the most connected categories (network analysis)
MATCH (c:Category)<-[:BELONGS_TO]-(t:Todo)<-[:OWNS]-(u:User)
RETURN c.name, COUNT(DISTINCT u) as user_count, COUNT(t) as todo_count
ORDER BY user_count DESC
```

## 🔧 Neo4j in Our Application

### 1. **Data Model Design**
```cypher
// Our graph schema
(:User)-[:OWNS]->(:Todo)-[:BELONGS_TO]->(:Category)
(:User)-[:CREATED]->(:Category)
(:User)-[:SIMILAR_TO]->(:User)
(:Todo)-[:TAGGED_WITH]->(:Tag)
(:User)-[:FOLLOWS]->(:User)
```

### 2. **Python Integration**
```python
from neo4j import GraphDatabase

class Neo4jClient:
    def __init__(self, uri, user, password):
        self.driver = GraphDatabase.driver(uri, auth=(user, password))
    
    def close(self):
        self.driver.close()
    
    def create_user_node(self, user_id, username, email):
        with self.driver.session() as session:
            session.run("""
                MERGE (u:User {id: $user_id})
                SET u.username = $username, u.email = $email
                """, user_id=user_id, username=username, email=email)
    
    def create_todo_with_relationships(self, todo_id, title, user_id, category_ids=None):
        with self.driver.session() as session:
            # Create todo node
            session.run("""
                MERGE (t:Todo {id: $todo_id})
                SET t.title = $title
                """, todo_id=todo_id, title=title)
            
            # Link to user
            session.run("""
                MATCH (u:User {id: $user_id}), (t:Todo {id: $todo_id})
                MERGE (u)-[:OWNS]->(t)
                """, user_id=user_id, todo_id=todo_id)
            
            # Link to categories
            if category_ids:
                for cat_id in category_ids:
                    session.run("""
                        MATCH (t:Todo {id: $todo_id}), (c:Category {id: $cat_id})
                        MERGE (t)-[:BELONGS_TO]->(c)
                        """, todo_id=todo_id, cat_id=cat_id)
```

### 3. **Cypher Queries for Our App**
```python
class Neo4jQueries:
    @staticmethod
    def get_user_recommendations(user_id):
        return """
        MATCH (u:User {id: $user_id})-[:OWNS]->(t:Todo)-[:BELONGS_TO]->(c:Category)
        MATCH (c)<-[:BELONGS_TO]-(rec:Todo)<-[:OWNS]-(other:User)
        WHERE other.id <> $user_id AND NOT (u)-[:OWNS]->(rec)
        RETURN rec.title as recommendation, 
               c.name as category,
               COUNT(*) as score
        ORDER BY score DESC
        LIMIT 10
        """
    
    @staticmethod
    def find_similar_users(user_id):
        return """
        MATCH (u:User {id: $user_id})-[:OWNS]->(t:Todo)-[:BELONGS_TO]->(c:Category)
        MATCH (other:User)-[:OWNS]->(other_todo:Todo)-[:BELONGS_TO]->(c)
        WHERE other.id <> $user_id
        WITH other, COUNT(DISTINCT c) as shared_categories
        WHERE shared_categories >= 2
        RETURN other.username, shared_categories
        ORDER BY shared_categories DESC
        """
```

## 📊 Cypher Query Language

### 1. **Basic Patterns**
```cypher
// Find all nodes
MATCH (n) RETURN n

// Find specific nodes
MATCH (u:User {username: "john_doe"}) RETURN u

// Find relationships
MATCH (u:User)-[:OWNS]->(t:Todo) RETURN u.username, t.title

// Filter with WHERE
MATCH (u:User)-[:OWNS]->(t:Todo)
WHERE t.priority = "high"
RETURN u.username, t.title
```

### 2. **Complex Patterns**
```cypher
// Variable length paths
MATCH (start:User)-[:FOLLOWS*1..3]->(end:User)
WHERE start.id = 123
RETURN end.username, LENGTH(path) as degrees_of_separation

// Optional matches (like LEFT JOIN)
MATCH (u:User)
OPTIONAL MATCH (u)-[:OWNS]->(t:Todo)
RETURN u.username, COUNT(t) as todo_count

// Multiple patterns
MATCH (u:User)-[:OWNS]->(t:Todo)-[:BELONGS_TO]->(c:Category)
MATCH (u)-[:CREATED]->(c)
RETURN u.username, c.name, COUNT(t) as todos_in_own_category
```

### 3. **Aggregations & Functions**
```cypher
// Counting and grouping
MATCH (u:User)-[:OWNS]->(t:Todo)
RETURN u.username, 
       COUNT(t) as total_todos,
       COUNT(CASE WHEN t.completed = true THEN 1 END) as completed_todos

// Statistical functions
MATCH (u:User)-[:OWNS]->(t:Todo)
RETURN u.username,
       AVG(t.priority_score) as avg_priority,
       MIN(t.created_at) as first_todo,
       MAX(t.created_at) as latest_todo

// String functions
MATCH (t:Todo)
WHERE toLower(t.title) CONTAINS "learn"
RETURN t.title, size(t.title) as title_length
```

## 🔄 Creating and Updating Data

### 1. **Creating Nodes and Relationships**
```cypher
// Create single node
CREATE (u:User {id: 123, username: "alice", email: "alice@example.com"})

// Create multiple nodes and relationships in one go
CREATE (u:User {id: 124, username: "bob"})-[:OWNS]->(t:Todo {id: 456, title: "Learn Cypher"})

// MERGE (create if not exists, update if exists)
MERGE (u:User {id: 123})
ON CREATE SET u.created_at = timestamp()
ON MATCH SET u.last_login = timestamp()

// Create relationship between existing nodes
MATCH (u:User {id: 123}), (c:Category {id: 789})
MERGE (u)-[:CREATED]->(c)
```

### 2. **Updating Data**
```cypher
// Update node properties
MATCH (t:Todo {id: 456})
SET t.completed = true, t.completed_at = timestamp()

// Add new properties
MATCH (u:User {id: 123})
SET u.preferences = {theme: "dark", notifications: true}

// Remove properties
MATCH (u:User {id: 123})
REMOVE u.temporary_flag

// Update relationship properties
MATCH (u:User)-[r:OWNS]->(t:Todo {id: 456})
SET r.marked_important = true
```

### 3. **Deleting Data**
```cypher
// Delete nodes (must delete relationships first)
MATCH (t:Todo {id: 456})
DETACH DELETE t  // DETACH deletes all relationships automatically

// Delete specific relationships
MATCH (u:User)-[r:OWNS]->(t:Todo {id: 456})
DELETE r

// Conditional deletion
MATCH (t:Todo)
WHERE t.created_at < date("2024-01-01")
DETACH DELETE t
```

## 🎯 Advanced Graph Algorithms

### 1. **Shortest Path**
```cypher
// Find shortest path between users through follows
MATCH path = shortestPath((start:User {id: 123})-[:FOLLOWS*]-(end:User {id: 456}))
RETURN path, length(path) as degrees_of_separation

// All shortest paths
MATCH paths = allShortestPaths((start:User {id: 123})-[:FOLLOWS*]-(end:User {id: 456}))
RETURN paths
```

### 2. **PageRank (with APOC procedures)**
```cypher
// Find most influential users
CALL gds.pageRank.stream('user_network')
YIELD nodeId, score
MATCH (u:User) WHERE id(u) = nodeId
RETURN u.username, score
ORDER BY score DESC
```

### 3. **Community Detection**
```cypher
// Find communities of users with similar interests
CALL gds.louvain.stream('user_similarity_graph')
YIELD nodeId, communityId
MATCH (u:User) WHERE id(u) = nodeId
RETURN communityId, collect(u.username) as community_members
```

## 📈 Performance Optimization

### 1. **Indexes**
```cypher
// Create indexes for faster lookups
CREATE INDEX FOR (u:User) ON (u.id)
CREATE INDEX FOR (t:Todo) ON (t.id)
CREATE INDEX FOR (c:Category) ON (c.id)

// Composite indexes
CREATE INDEX FOR (t:Todo) ON (t.user_id, t.created_at)

// Full-text indexes
CREATE FULLTEXT INDEX todo_search FOR (t:Todo) ON EACH [t.title, t.description]

// Use full-text search
CALL db.index.fulltext.queryNodes("todo_search", "learn database") 
YIELD node, score
RETURN node.title, score
```

### 2. **Query Optimization**
```cypher
// Bad: Cartesian product
MATCH (u:User), (t:Todo)
WHERE u.id = t.user_id
RETURN u.username, t.title

// Good: Use relationships
MATCH (u:User)-[:OWNS]->(t:Todo)
RETURN u.username, t.title

// Use PROFILE to analyze queries
PROFILE 
MATCH (u:User)-[:OWNS]->(t:Todo)
WHERE t.priority = "high"
RETURN u.username, t.title
```

### 3. **Memory Management**
```cypher
// Use LIMIT to avoid large result sets
MATCH (u:User)-[:OWNS]->(t:Todo)
RETURN u.username, t.title
ORDER BY t.created_at DESC
LIMIT 100

// Use WITH for intermediate processing
MATCH (u:User)-[:OWNS]->(t:Todo)
WITH u, COUNT(t) as todo_count
WHERE todo_count > 10
MATCH (u)-[:OWNS]->(recent:Todo)
WHERE recent.created_at > date("2025-01-01")
RETURN u.username, COUNT(recent) as recent_todos
```

## 🔄 Data Synchronization

### 1. **Keeping Neo4j in Sync with PostgreSQL**
```python
# Event-driven synchronization
async def create_todo_with_sync(todo_data, user_id):
    # 1. Create in PostgreSQL (source of truth)
    postgres_todo = await crud.create_todo(postgres_db, todo_data, user_id)
    
    # 2. Sync to Neo4j
    try:
        await neo4j_client.create_todo_node(
            postgres_todo.id, 
            postgres_todo.title, 
            user_id
        )
    except Exception as e:
        # Log error but don't fail the main operation
        logger.error(f"Failed to sync todo to Neo4j: {e}")
    
    return postgres_todo

# Batch synchronization for data consistency
async def sync_postgres_to_neo4j():
    # Get all users from PostgreSQL
    users = await crud.get_all_users(postgres_db)
    
    for user in users:
        # Ensure user exists in Neo4j
        await neo4j_client.create_user_node(user.id, user.username, user.email)
        
        # Get user's todos
        todos = await crud.get_user_todos(postgres_db, user.id)
        
        for todo in todos:
            await neo4j_client.create_todo_with_relationships(
                todo.id, todo.title, user.id
            )
```

### 2. **Handling Conflicts**
```python
# Conflict resolution strategy
async def reconcile_data_conflicts():
    # Check for orphaned nodes in Neo4j
    orphaned_todos = await neo4j_client.find_orphaned_todos()
    
    for todo_id in orphaned_todos:
        # Check if todo exists in PostgreSQL
        postgres_todo = await crud.get_todo(postgres_db, todo_id)
        
        if not postgres_todo:
            # Remove from Neo4j
            await neo4j_client.delete_todo_node(todo_id)
        else:
            # Recreate relationships
            await neo4j_client.create_user_todo_relationship(
                postgres_todo.user_id, todo_id
            )
```

## 🎭 Real-World Use Cases

### 1. **Recommendation Engine**
```cypher
// Content-based recommendations
MATCH (u:User {id: $user_id})-[:OWNS]->(t:Todo)-[:BELONGS_TO]->(c:Category)
WITH u, c, COUNT(t) as category_interest
ORDER BY category_interest DESC
LIMIT 3

MATCH (c)<-[:BELONGS_TO]-(recommended:Todo)<-[:OWNS]-(other:User)
WHERE other.id <> $user_id 
  AND NOT (u)-[:OWNS]->(recommended)
WITH recommended, SUM(category_interest) as relevance_score
RETURN recommended.title, relevance_score
ORDER BY relevance_score DESC
LIMIT 10
```

### 2. **Social Network Analysis**
```cypher
// Find influencers in the todo community
MATCH (u:User)-[:OWNS]->(t:Todo)<-[:FAVORITED]-(fan:User)
WITH u, COUNT(DISTINCT fan) as followers, COUNT(DISTINCT t) as todos_created
WHERE followers > 10
RETURN u.username, followers, todos_created, 
       (followers * 1.0 / todos_created) as influence_ratio
ORDER BY influence_ratio DESC
```

### 3. **Collaboration Patterns**
```cypher
// Find users who work on similar projects
MATCH (u1:User)-[:OWNS]->(t1:Todo)-[:BELONGS_TO]->(c:Category)<-[:BELONGS_TO]-(t2:Todo)<-[:OWNS]-(u2:User)
WHERE u1.id < u2.id  // Avoid duplicates
WITH u1, u2, COUNT(DISTINCT c) as shared_categories
WHERE shared_categories >= 3
RETURN u1.username, u2.username, shared_categories
ORDER BY shared_categories DESC
```

## 🔧 Monitoring & Maintenance

### 1. **Database Statistics**
```cypher
// Node counts by label
MATCH (n) 
RETURN labels(n) as node_type, COUNT(n) as count
ORDER BY count DESC

// Relationship counts by type
MATCH ()-[r]->()
RETURN type(r) as relationship_type, COUNT(r) as count
ORDER BY count DESC

// Database size information
CALL dbms.queryJmx("org.neo4j:instance=kernel#0,name=Store file sizes")
YIELD attributes
RETURN attributes
```

### 2. **Query Performance**
```cypher
// Show query execution plan
EXPLAIN 
MATCH (u:User)-[:OWNS]->(t:Todo)
WHERE t.priority = "high"
RETURN u.username, COUNT(t)

// Profile query with actual execution stats
PROFILE
MATCH (u:User)-[:OWNS]->(t:Todo)
WHERE t.priority = "high"
RETURN u.username, COUNT(t)
```

### 3. **Data Quality Checks**
```cypher
// Find orphaned todos (todos without owners)
MATCH (t:Todo)
WHERE NOT (t)<-[:OWNS]-(:User)
RETURN t.id, t.title

// Find users without todos
MATCH (u:User)
WHERE NOT (u)-[:OWNS]->(:Todo)
RETURN u.username

// Check for duplicate relationships
MATCH (u:User)-[r:OWNS]->(t:Todo)
WITH u, t, COUNT(r) as relationship_count
WHERE relationship_count > 1
RETURN u.username, t.title, relationship_count
```

## 🛡️ Security Considerations

### 1. **Access Control**
```cypher
// Create roles
CREATE ROLE read_only_user
CREATE ROLE todo_admin

// Grant permissions
GRANT READ {*} ON GRAPH * TO read_only_user
GRANT ALL GRAPH PRIVILEGES ON GRAPH * TO todo_admin

// Row-level security (with procedures)
CREATE USER todo_user SET PASSWORD 'secure_password'
GRANT ROLE read_only_user TO todo_user
```

### 2. **Input Sanitization**
```python
# Always use parameterized queries
def get_user_todos(user_id):
    # Safe: parameters are properly escaped
    query = """
    MATCH (u:User {id: $user_id})-[:OWNS]->(t:Todo)
    RETURN t.title, t.completed
    """
    return session.run(query, user_id=user_id)

# Never do this (SQL injection equivalent)
def unsafe_query(user_input):
    query = f"MATCH (u:User {{name: '{user_input}'}}) RETURN u"  # Dangerous!
    return session.run(query)
```

## 🎯 Integration with FastAPI

### 1. **FastAPI Endpoints Using Neo4j**
```python
@app.get("/recommendations")
async def get_recommendations(
    current_user: User = Depends(get_current_user)
):
    recommendations = neo4j_client.get_user_recommendations(current_user.id)
    return {"recommendations": recommendations}

@app.get("/similar-users")
async def get_similar_users(
    current_user: User = Depends(get_current_user)
):
    similar_users = neo4j_client.find_similar_users(current_user.id)
    return {"similar_users": similar_users}

@app.post("/todos/{todo_id}/favorite")
async def favorite_todo(
    todo_id: int,
    current_user: User = Depends(get_current_user)
):
    # Update PostgreSQL
    await crud.favorite_todo(db, todo_id, current_user.id)
    
    # Update Neo4j relationships
    await neo4j_client.create_favorite_relationship(current_user.id, todo_id)
    
    return {"message": "Todo favorited successfully"}
```

### 2. **Background Tasks for Graph Updates**
```python
from fastapi import BackgroundTasks

@app.post("/todos", response_model=Todo)
async def create_todo(
    todo: TodoCreate,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user)
):
    # Create in PostgreSQL immediately
    db_todo = crud.create_todo(db, todo=todo, user_id=current_user.id)
    
    # Update Neo4j in background
    background_tasks.add_task(
        neo4j_client.create_todo_with_relationships,
        db_todo.id,
        db_todo.title,
        current_user.id
    )
    
    return db_todo
```

## 🎓 Key Takeaways

1. **Graph databases excel at relationships** - use them when connections matter
2. **Cypher is intuitive** - matches how we think about connected data
3. **Performance depends on good modeling** - design your graph schema carefully
4. **Neo4j complements PostgreSQL** - use both for different strengths
5. **Recommendations become natural** - graph algorithms make this easy
6. **Keep data in sync** - have a strategy for maintaining consistency
7. **Monitor and optimize** - use PROFILE and indexes effectively
8. **Security matters** - parameterize queries and control access

## 🛠️ Practical Exercise

Let's build a recommendation system:

### 1. Set up the Graph Structure:
```cypher
// Create sample data
CREATE (alice:User {id: 1, username: "alice"})
CREATE (bob:User {id: 2, username: "bob"})
CREATE (charlie:User {id: 3, username: "charlie"})

CREATE (learning:Category {id: 1, name: "Learning"})
CREATE (work:Category {id: 2, name: "Work"})
CREATE (personal:Category {id: 3, name: "Personal"})

CREATE (alice)-[:OWNS]->(t1:Todo {id: 1, title: "Learn Neo4j"})
CREATE (alice)-[:OWNS]->(t2:Todo {id: 2, title: "Practice Cypher"})
CREATE (bob)-[:OWNS]->(t3:Todo {id: 3, title: "Learn Databases"})
CREATE (charlie)-[:OWNS]->(t4:Todo {id: 4, title: "Graph Algorithms"})

CREATE (t1)-[:BELONGS_TO]->(learning)
CREATE (t2)-[:BELONGS_TO]->(learning)
CREATE (t3)-[:BELONGS_TO]->(learning)
CREATE (t4)-[:BELONGS_TO]->(learning)
```

### 2. Generate Recommendations:
```cypher
// Find recommendations for Alice
MATCH (alice:User {username: "alice"})-[:OWNS]->(my_todo:Todo)-[:BELONGS_TO]->(category:Category)
MATCH (category)<-[:BELONGS_TO]-(recommended:Todo)<-[:OWNS]-(other:User)
WHERE other.username <> "alice" AND NOT (alice)-[:OWNS]->(recommended)
RETURN recommended.title as recommendation, 
       other.username as suggested_by,
       category.name as category
```

### 3. Find Similar Users:
```cypher
// Find users with similar interests to Alice
MATCH (alice:User {username: "alice"})-[:OWNS]->(todo:Todo)-[:BELONGS_TO]->(category:Category)
MATCH (other:User)-[:OWNS]->(other_todo:Todo)-[:BELONGS_TO]->(category)
WHERE other.username <> "alice"
RETURN other.username, 
       COUNT(DISTINCT category) as shared_interests,
       COLLECT(DISTINCT category.name) as common_categories
ORDER BY shared_interests DESC
```

---

**Previous**: [PostgreSQL Deep Dive](06-postgresql-deep-dive.md) | **Next**: [Docker & Containers](08-docker-containers.md)