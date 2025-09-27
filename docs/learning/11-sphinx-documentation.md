# Sphinx Documentation: Professional Documentation for Developers

## 📚 What is Sphinx?

**Sphinx** is like a **professional publishing system for code documentation** that:

- **Generates beautiful documentation** from simple text files
- **Automatically extracts** docstrings from your Python code
- **Creates multiple output formats** (HTML, PDF, ePub)
- **Provides cross-references** and automatic linking
- **Supports extensions** for diagrams, code highlighting, and more

Think of it as **transforming your technical notes into professional documentation** that looks like it came from a major tech company.

## 🏗️ Why Sphinx for Our Todo App?

### Documentation Challenges:
```
Without Sphinx:
├── Scattered README files
├── Outdated API documentation  
├── Inconsistent formatting
├── No search functionality
├── Manual cross-referencing
└── Multiple sources of truth

With Sphinx:
├── Single source of truth
├── Auto-generated API docs
├── Consistent, professional look
├── Built-in search
├── Cross-referenced content
└── Multiple output formats
```

### Real-World Benefits:
```python
# Code with docstrings
class TodoService:
    """
    Service for managing todo items.
    
    This service handles CRUD operations for todos and integrates
    with both PostgreSQL and Neo4j databases.
    
    Example:
        >>> service = TodoService(db_session, neo4j_client)
        >>> todo = service.create_todo("Learn Sphinx", user_id=1)
        >>> print(todo.title)
        'Learn Sphinx'
    """
    
    def create_todo(self, title: str, user_id: int) -> Todo:
        """
        Create a new todo item.
        
        Args:
            title: The todo title (max 200 characters)
            user_id: ID of the user creating the todo
            
        Returns:
            The created todo object
            
        Raises:
            ValidationError: If title is empty or too long
            UserNotFoundError: If user_id doesn't exist
        """
        # Sphinx automatically generates beautiful docs from this!
```

## 🚀 Setting Up Sphinx

### 1. **Installation and Initialization**
```bash
# Install Sphinx and extensions
pip install sphinx
pip install sphinx-rtd-theme  # ReadTheDocs theme
pip install sphinx-autodoc-typehints  # Type hints support
pip install myst-parser  # Markdown support

# Create documentation directory
mkdir docs
cd docs

# Initialize Sphinx project
sphinx-quickstart

# Follow the prompts:
# - Separate source and build directories: y
# - Project name: Todo App
# - Author name: Your Name
# - Project version: 1.0
# - Project language: en
```

### 2. **Directory Structure**
```
docs/
├── source/
│   ├── conf.py          # Sphinx configuration
│   ├── index.rst        # Main documentation page
│   ├── api/             # Auto-generated API docs
│   ├── tutorials/       # User guides
│   ├── deployment/      # Deployment guides
│   └── _static/         # Custom CSS, images
├── build/               # Generated documentation
│   ├── html/           # HTML output
│   ├── latex/          # LaTeX output
│   └── epub/           # eBook output
├── Makefile            # Build commands
└── requirements.txt    # Documentation dependencies
```

### 3. **Configuration (conf.py)**
```python
# docs/source/conf.py
import os
import sys

# Add your project to Python path
sys.path.insert(0, os.path.abspath('../../backend'))

# Project information
project = 'Todo App'
copyright = '2025, Your Name'
author = 'Your Name'
version = '1.0'
release = '1.0.0'

# Extensions
extensions = [
    'sphinx.ext.autodoc',        # Auto-generate from docstrings
    'sphinx.ext.autosummary',    # Generate summary tables
    'sphinx.ext.viewcode',       # Add source code links
    'sphinx.ext.napoleon',       # Google/NumPy style docstrings
    'sphinx.ext.intersphinx',    # Link to other documentation
    'sphinx.ext.todo',           # TODO notes
    'sphinx_autodoc_typehints',  # Type hints in docs
    'myst_parser',               # Markdown support
]

# Theme configuration
html_theme = 'sphinx_rtd_theme'
html_theme_options = {
    'canonical_url': '',
    'analytics_id': '',
    'logo_only': False,
    'display_version': True,
    'prev_next_buttons_location': 'bottom',
    'style_external_links': False,
    'style_nav_header_background': '#2980B9',
    'collapse_navigation': True,
    'sticky_navigation': True,
    'navigation_depth': 4,
    'includehidden': True,
    'titles_only': False
}

# Static files
html_static_path = ['_static']
html_css_files = ['custom.css']

# Auto-generate API documentation
autodoc_default_options = {
    'members': True,
    'member-order': 'bysource',
    'special-members': '__init__',
    'undoc-members': True,
    'exclude-members': '__weakref__'
}

# Napoleon settings (for Google-style docstrings)
napoleon_google_docstring = True
napoleon_numpy_docstring = True
napoleon_include_init_with_doc = False
napoleon_include_private_with_doc = False

# Intersphinx mapping (link to external docs)
intersphinx_mapping = {
    'python': ('https://docs.python.org/3/', None),
    'fastapi': ('https://fastapi.tiangolo.com/', None),
    'sqlalchemy': ('https://docs.sqlalchemy.org/en/14/', None),
}
```

## 📖 Writing Documentation

### 1. **reStructuredText (RST) Basics**
```rst
Todo App Documentation
======================

Welcome to the Todo App documentation! This guide will help you understand,
deploy, and extend our todo application.

Quick Start
-----------

To get started quickly:

1. Clone the repository
2. Run ``docker-compose up``
3. Visit http://localhost:3000

.. note::
   Make sure you have Docker installed before proceeding.

API Overview
------------

Our API provides the following endpoints:

* ``GET /todos`` - List all todos
* ``POST /todos`` - Create a new todo
* ``PUT /todos/{id}`` - Update a todo
* ``DELETE /todos/{id}`` - Delete a todo

Code Example
~~~~~~~~~~~~

Here's how to create a todo using Python:

.. code-block:: python

   import requests
   
   response = requests.post(
       'http://localhost:8000/todos',
       json={'title': 'Learn Sphinx', 'completed': False}
   )
   todo = response.json()
   print(f"Created todo: {todo['title']}")

.. seealso::
   
   For more API details, see :doc:`api/index`
```

### 2. **Markdown Support (with MyST)**
```markdown
# Todo App User Guide

This guide explains how to use the Todo App effectively.

## Creating Your First Todo

1. Navigate to the main page
2. Click the "Add Todo" button
3. Enter your todo title
4. Press Enter or click Save

```{note}
Todos are automatically saved to the database.
```

## Features

### Basic Features
- Create, edit, and delete todos
- Mark todos as complete
- Filter by status

### Advanced Features
- Categories and tags
- Due dates and reminders
- Collaboration with other users

```{warning}
Deleting a todo cannot be undone!
```

## API Integration

You can integrate with our API using any HTTP client:

```python
import httpx

async def get_todos():
    async with httpx.AsyncClient() as client:
        response = await client.get("http://localhost:8000/todos")
        return response.json()
```
```

### 3. **Auto-Generated API Documentation**
```python
# backend/app/models.py
from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

class Todo(Base):
    """
    Todo model representing a task item.
    
    This model stores todo items with their metadata and relationships
    to users and categories.
    
    Attributes:
        id: Primary key identifier
        title: The todo title (required, max 200 chars)
        description: Optional detailed description
        completed: Whether the todo is completed (default False)
        created_at: When the todo was created
        user_id: Foreign key to the user who owns this todo
    """
    __tablename__ = "todos"
    
    id = Column(Integer, primary_key=True, index=True, doc="Unique identifier")
    title = Column(String(200), nullable=False, doc="Todo title")
    description = Column(String, nullable=True, doc="Optional description")
    completed = Column(Boolean, default=False, doc="Completion status")
    created_at = Column(DateTime, doc="Creation timestamp")
    user_id = Column(Integer, doc="Owner user ID")
```

Create API documentation automatically:
```rst
.. docs/source/api/models.rst

Database Models
===============

This section documents our database models and their relationships.

.. automodule:: app.models
   :members:
   :undoc-members:
   :show-inheritance:

Todo Model
----------

.. autoclass:: app.models.Todo
   :members:
   :inherited-members:
   :show-inheritance:
```

### 4. **Service Documentation**
```python
# backend/app/services/todo_service.py
from typing import List, Optional
from sqlalchemy.orm import Session
from app.models import Todo
from app.schemas import TodoCreate, TodoUpdate

class TodoService:
    """
    Service layer for todo operations.
    
    This service handles business logic for todo management,
    including validation, database operations, and integration
    with external services.
    """
    
    def __init__(self, db: Session):
        """
        Initialize the todo service.
        
        Args:
            db: Database session for operations
        """
        self.db = db
    
    def get_todos(self, user_id: int, skip: int = 0, limit: int = 100) -> List[Todo]:
        """
        Retrieve todos for a specific user.
        
        Args:
            user_id: ID of the user whose todos to retrieve
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
            
        Returns:
            List of todo objects
            
        Example:
            >>> service = TodoService(db)
            >>> todos = service.get_todos(user_id=1, limit=10)
            >>> len(todos)
            10
        """
        return self.db.query(Todo).filter(
            Todo.user_id == user_id
        ).offset(skip).limit(limit).all()
    
    def create_todo(self, todo: TodoCreate, user_id: int) -> Todo:
        """
        Create a new todo item.
        
        Args:
            todo: Todo creation data
            user_id: ID of the user creating the todo
            
        Returns:
            The created todo object
            
        Raises:
            ValidationError: If todo data is invalid
            DatabaseError: If database operation fails
            
        Example:
            >>> from app.schemas import TodoCreate
            >>> todo_data = TodoCreate(title="Learn Sphinx")
            >>> todo = service.create_todo(todo_data, user_id=1)
            >>> todo.title
            'Learn Sphinx'
        """
        db_todo = Todo(**todo.dict(), user_id=user_id)
        self.db.add(db_todo)
        self.db.commit()
        self.db.refresh(db_todo)
        return db_todo
```

## 🎨 Customizing Appearance

### 1. **Custom CSS**
```css
/* docs/source/_static/custom.css */

/* Custom color scheme */
.wy-side-nav-search {
    background-color: #3498db !important;
}

.wy-nav-top {
    background-color: #2980b9 !important;
}

/* Code blocks */
.highlight {
    background-color: #f8f9fa;
    border-left: 4px solid #3498db;
    padding: 1em;
    margin: 1em 0;
}

/* Custom admonitions */
.admonition.tip {
    border-left-color: #28a745;
}

.admonition.warning {
    border-left-color: #ffc107;
}

.admonition.danger {
    border-left-color: #dc3545;
}

/* API documentation styling */
.py.class > dt {
    background-color: #e8f4f8;
    border-left: 4px solid #3498db;
}

.py.method > dt {
    background-color: #f0f8e8;
    border-left: 4px solid #28a745;
}
```

### 2. **Custom Templates**
```html
<!-- docs/source/_templates/layout.html -->
{% extends "!layout.html" %}

{% block extrahead %}
    {{ super() }}
    <link rel="shortcut icon" href="{{ pathto('_static/favicon.ico', 1) }}">
    <meta name="description" content="Todo App - Complete documentation for our modern todo application">
    <meta name="keywords" content="todo, fastapi, postgresql, neo4j, documentation">
{% endblock %}

{% block footer %}
    {{ super() }}
    <div class="footer-custom">
        <p>&copy; 2025 Todo App. Built with ❤️ and Sphinx.</p>
    </div>
{% endblock %}
```

## 📋 Documentation Structure

### Complete Documentation Layout:
```
docs/source/
├── index.rst                 # Main landing page
├── quickstart.rst            # Getting started guide
├── installation.rst          # Installation instructions
├── tutorials/
│   ├── index.rst            # Tutorial index
│   ├── basic-usage.rst      # Basic application usage
│   ├── api-integration.rst  # API integration guide
│   └── advanced-features.rst # Advanced features
├── api/
│   ├── index.rst            # API documentation index
│   ├── models.rst           # Database models
│   ├── services.rst         # Service layer
│   ├── routes.rst           # API endpoints
│   └── schemas.rst          # Pydantic schemas
├── deployment/
│   ├── index.rst            # Deployment overview
│   ├── docker.rst           # Docker deployment
│   ├── aws.rst              # AWS deployment
│   └── monitoring.rst       # Monitoring setup
├── architecture/
│   ├── index.rst            # Architecture overview
│   ├── database-design.rst  # Database design
│   ├── api-design.rst       # API design principles
│   └── security.rst         # Security considerations
├── contributing/
│   ├── index.rst            # Contributing guidelines
│   ├── development.rst      # Development setup
│   ├── testing.rst          # Testing guidelines
│   └── code-style.rst       # Code style guide
└── changelog.rst            # Version history
```

### Main Index Page:
```rst
.. docs/source/index.rst

Todo App Documentation
======================

Welcome to the Todo App documentation! This comprehensive guide covers
everything you need to know about building, deploying, and extending
our modern todo application.

.. toctree::
   :maxdepth: 2
   :caption: Getting Started

   quickstart
   installation
   tutorials/index

.. toctree::
   :maxdepth: 2
   :caption: API Reference

   api/index

.. toctree::
   :maxdepth: 2
   :caption: Deployment

   deployment/index

.. toctree::
   :maxdepth: 2
   :caption: Architecture

   architecture/index

.. toctree::
   :maxdepth: 1
   :caption: Contributing

   contributing/index
   changelog

Quick Links
-----------

* :ref:`genindex` - General Index
* :ref:`modindex` - Module Index
* :ref:`search` - Search Page

Overview
--------

The Todo App is a modern web application built with:

* **Backend**: FastAPI with Python
* **Frontend**: Next.js with TypeScript  
* **Databases**: PostgreSQL + Neo4j
* **Deployment**: Docker containers on AWS
* **Documentation**: Sphinx (this site!)

Key Features
~~~~~~~~~~~~

.. hlist::
   :columns: 2

   * RESTful API design
   * Dual database architecture
   * Real-time updates
   * User authentication
   * Role-based permissions
   * Container deployment
   * Comprehensive testing
   * Auto-generated docs

Architecture Diagram
~~~~~~~~~~~~~~~~~~~~

.. figure:: _static/architecture-diagram.png
   :alt: Todo App Architecture
   :align: center
   :width: 80%

   High-level architecture of the Todo App

Getting Help
------------

* Check our :doc:`tutorials/index` for step-by-step guides
* Browse the :doc:`api/index` for technical reference
* Read :doc:`deployment/index` for deployment options
* Visit our `GitHub repository <https://github.com/yourorg/todo-app>`_ for source code

.. note::
   This documentation is automatically generated from code comments
   and maintained alongside the source code to ensure accuracy.
```

## 🔧 Build and Deployment

### 1. **Local Development**
```bash
# Install dependencies
pip install -r docs/requirements.txt

# Build documentation
cd docs
make html

# Serve locally
python -m http.server 8080 -d build/html

# Auto-rebuild on changes (sphinx-autobuild)
pip install sphinx-autobuild
sphinx-autobuild source build/html --host 0.0.0.0 --port 8080
```

### 2. **GitHub Actions for Auto-Deploy**
```yaml
# .github/workflows/docs.yml
name: Build and Deploy Documentation

on:
  push:
    branches: [main]
    paths: ['docs/**', 'backend/**/*.py']
  pull_request:
    branches: [main]
    paths: ['docs/**', 'backend/**/*.py']

jobs:
  docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
          
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r docs/requirements.txt
          pip install -r backend/requirements.txt
          
      - name: Build documentation
        run: |
          cd docs
          make html
          
      - name: Deploy to GitHub Pages
        if: github.ref == 'refs/heads/main'
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./docs/build/html
```

### 3. **Read the Docs Integration**
```yaml
# .readthedocs.yml
version: 2

build:
  os: ubuntu-22.04
  tools:
    python: "3.11"

sphinx:
  configuration: docs/source/conf.py

formats:
  - pdf
  - epub

python:
  install:
    - requirements: docs/requirements.txt
    - requirements: backend/requirements.txt
    - method: pip
      path: .
```

## 📊 Advanced Features

### 1. **API Documentation with OpenAPI**
```python
# Generate OpenAPI docs alongside Sphinx
from fastapi.openapi.utils import get_openapi
import json

def generate_openapi_spec():
    """Generate OpenAPI specification for Sphinx inclusion."""
    openapi_schema = get_openapi(
        title="Todo App API",
        version="1.0.0",
        description="RESTful API for todo management",
        routes=app.routes,
    )
    
    with open('docs/source/_static/openapi.json', 'w') as f:
        json.dump(openapi_schema, f, indent=2)

# In docs/source/api/endpoints.rst
"""
.. raw:: html
   
   <div id="swagger-ui"></div>
   <script src="https://unpkg.com/swagger-ui-dist@3/swagger-ui-bundle.js"></script>
   <script>
   SwaggerUIBundle({
     url: '_static/openapi.json',
     dom_id: '#swagger-ui',
     presets: [
       SwaggerUIBundle.presets.apis,
       SwaggerUIBundle.presets.standalone
     ]
   })
   </script>
"""
```

### 2. **Jupyter Notebook Integration**
```python
# Include interactive examples
# docs/source/tutorials/api-examples.ipynb

{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# API Usage Examples\n",
    "\n",
    "This notebook shows interactive examples of using the Todo App API."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "import requests\n",
    "import json\n",
    "\n",
    "# Configure API client\n",
    "BASE_URL = 'http://localhost:8000'\n",
    "headers = {'Content-Type': 'application/json'}\n",
    "\n",
    "def create_todo(title, description=''):\n",
    "    \"\"\"Create a new todo item.\"\"\"\n",
    "    response = requests.post(\n",
    "        f'{BASE_URL}/todos',\n",
    "        json={'title': title, 'description': description},\n",
    "        headers=headers\n",
    "    )\n",
    "    return response.json()\n",
    "\n",
    "# Example usage\n",
    "todo = create_todo('Learn Sphinx Documentation')\n",
    "print(json.dumps(todo, indent=2))"
   ]
  }
 ]
}

# Include in RST with nbsphinx
pip install nbsphinx

# In conf.py
extensions.append('nbsphinx')
```

### 3. **Diagrams and Visualizations**
```rst
.. Using Mermaid for diagrams
.. mermaid::

   graph TD
       A[User Request] --> B[FastAPI Router]
       B --> C[Service Layer]
       C --> D[Database Layer]
       D --> E[PostgreSQL]
       D --> F[Neo4j]
       C --> G[Response]
       G --> A

.. Using PlantUML
.. uml::

   @startuml
   actor User
   participant Frontend
   participant Backend
   database PostgreSQL
   database Neo4j
   
   User -> Frontend: Create Todo
   Frontend -> Backend: POST /todos
   Backend -> PostgreSQL: INSERT todo
   Backend -> Neo4j: CREATE relationships
   Backend -> Frontend: Todo created
   Frontend -> User: Success message
   @enduml
```

## 📈 Documentation Analytics

### Track Documentation Usage:
```html
<!-- docs/source/_templates/layout.html -->
{% block extrahead %}
    {{ super() }}
    <!-- Google Analytics -->
    <script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
    <script>
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());
      gtag('config', 'GA_MEASUREMENT_ID');
    </script>
{% endblock %}
```

## 🎓 Best Practices

### 1. **Documentation Standards**
```python
def calculate_completion_rate(user_id: int) -> float:
    """
    Calculate the completion rate for a user's todos.
    
    This function computes the percentage of completed todos
    for a given user. It handles edge cases like users with
    no todos and provides accurate floating-point results.
    
    Args:
        user_id: The ID of the user to calculate for.
            Must be a positive integer corresponding to
            an existing user in the database.
    
    Returns:
        The completion rate as a percentage (0.0 to 100.0).
        Returns 0.0 if the user has no todos.
    
    Raises:
        UserNotFoundError: If the user_id doesn't exist.
        DatabaseError: If there's an issue querying the database.
    
    Example:
        Calculate completion rate for user 1:
        
        >>> rate = calculate_completion_rate(1)
        >>> print(f"Completion rate: {rate:.1f}%")
        Completion rate: 75.0%
        
    Note:
        This function queries both the todos table for total
        count and filters for completed todos. For better
        performance with large datasets, consider using
        aggregate queries.
        
    See Also:
        - :func:`get_user_stats` for comprehensive user statistics
        - :class:`TodoService` for related todo operations
    """
```

### 2. **Content Organization**
```rst
# Use consistent headings
# = for main titles
# - for major sections  
# ~ for subsections
# ^ for sub-subsections

# Use proper cross-references
See :doc:`installation` for setup instructions.
Check out :func:`app.services.create_todo` for implementation.
Refer to :class:`app.models.Todo` for the data model.

# Include examples everywhere
.. code-block:: python
   :caption: Creating a todo
   :linenos:
   :emphasize-lines: 3,4
   
   from app.services import TodoService
   
   service = TodoService(db)
   todo = service.create_todo("Learn Sphinx", user_id=1)

# Use admonitions effectively
.. note::
   This feature requires authentication.

.. warning::
   Deleting a user will also delete all their todos.

.. tip::
   Use the search function to quickly find topics.
```

## 🎯 Real-World Integration

### Documentation in Your Development Workflow:
```python
# pre-commit hook to update docs
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: update-docs
        name: Update API documentation
        entry: python scripts/update_docs.py
        language: python
        pass_filenames: false
        files: ^backend/.*\.py$

# scripts/update_docs.py
import subprocess
import sys

def update_docs():
    """Update Sphinx documentation when code changes."""
    try:
        # Generate API docs
        subprocess.run(['sphinx-apidoc', '-f', '-o', 'docs/source/api', 'backend/app'])
        
        # Build docs to check for errors
        subprocess.run(['make', '-C', 'docs', 'html'], check=True)
        
        print("Documentation updated successfully!")
    except subprocess.CalledProcessError:
        print("Documentation build failed!")
        sys.exit(1)

if __name__ == '__main__':
    update_docs()
```

## 🎓 Key Takeaways

1. **Sphinx generates professional documentation** from simple text and code
2. **Docstrings become beautiful API docs** automatically
3. **Multiple output formats** serve different needs (web, PDF, mobile)
4. **Cross-references and search** make large docs navigable
5. **Automation keeps docs current** with code changes
6. **Themes and customization** create branded experiences
7. **Integration with CI/CD** ensures docs are always updated
8. **Examples and tutorials** make technical docs accessible

## 🛠️ Practical Exercise

Set up Sphinx for the todo app:

### 1. **Initialize Documentation**:
```bash
cd /path/to/todo-app
mkdir docs
cd docs
sphinx-quickstart
```

### 2. **Configure for Auto-Generation**:
```python
# Edit docs/source/conf.py
# Add the configuration from examples above
```

### 3. **Generate API Docs**:
```bash
# Auto-generate API documentation
sphinx-apidoc -f -o source/api ../backend/app

# Build documentation
make html
```

### 4. **View Results**:
```bash
# Serve locally
python -m http.server 8080 -d build/html

# Open http://localhost:8080 in browser
```

### 5. **Add Custom Content**:
```rst
# Create docs/source/tutorials/quickstart.rst
# Add examples, guides, and explanations
```

---

**Previous**: [AWS Cloud Services](10-aws-cloud-services.md) | **Next**: [How Everything Connects](12-how-everything-connects.md)