from neo4j import GraphDatabase
import os
from dotenv import load_dotenv

load_dotenv()

class Neo4jClient:
    def __init__(self):
        self.uri = os.getenv("NEO4J_URI", "bolt://localhost:7687")
        self.user = os.getenv("NEO4J_USER", "neo4j")
        self.password = os.getenv("NEO4J_PASSWORD", "password")
        self.driver = GraphDatabase.driver(self.uri, auth=(self.user, self.password))
    
    def close(self):
        self.driver.close()
    
    def create_user_node(self, user_id: int, username: str, email: str):
        with self.driver.session() as session:
            session.run(
                "MERGE (u:User {id: $user_id}) "
                "SET u.username = $username, u.email = $email",
                user_id=user_id, username=username, email=email
            )
    
    def create_todo_node(self, todo_id: int, title: str, user_id: int):
        with self.driver.session() as session:
            session.run(
                "MERGE (t:Todo {id: $todo_id}) "
                "SET t.title = $title "
                "WITH t "
                "MATCH (u:User {id: $user_id}) "
                "MERGE (u)-[:OWNS]->(t)",
                todo_id=todo_id, title=title, user_id=user_id
            )
    
    def create_category_node(self, category_id: int, name: str, user_id: int):
        with self.driver.session() as session:
            session.run(
                "MERGE (c:Category {id: $category_id}) "
                "SET c.name = $name "
                "WITH c "
                "MATCH (u:User {id: $user_id}) "
                "MERGE (u)-[:CREATED]->(c)",
                category_id=category_id, name=name, user_id=user_id
            )
    
    def link_todo_to_category(self, todo_id: int, category_id: int):
        with self.driver.session() as session:
            session.run(
                "MATCH (t:Todo {id: $todo_id}), (c:Category {id: $category_id}) "
                "MERGE (t)-[:BELONGS_TO]->(c)",
                todo_id=todo_id, category_id=category_id
            )
    
    def get_user_todo_graph(self, user_id: int):
        with self.driver.session() as session:
            result = session.run(
                "MATCH (u:User {id: $user_id})-[:OWNS]->(t:Todo) "
                "OPTIONAL MATCH (t)-[:BELONGS_TO]->(c:Category) "
                "RETURN u, t, c",
                user_id=user_id
            )
            return [record for record in result]
    
    def get_todo_recommendations(self, user_id: int):
        with self.driver.session() as session:
            result = session.run(
                "MATCH (u:User {id: $user_id})-[:OWNS]->(t:Todo)-[:BELONGS_TO]->(c:Category) "
                "MATCH (c)<-[:BELONGS_TO]-(other_todo:Todo)<-[:OWNS]-(other_user:User) "
                "WHERE other_user.id <> $user_id "
                "RETURN other_todo.title as recommendation, c.name as category "
                "LIMIT 5",
                user_id=user_id
            )
            return [{"recommendation": record["recommendation"], "category": record["category"]} for record in result]

neo4j_client = Neo4jClient()