# Security Best Practices: Protecting Your Application

## 🔒 What is Application Security?

**Application security** is like **building multiple layers of protection around your valuable data**:

- **Authentication** - Who is this person? (Identity verification)
- **Authorization** - What can they do? (Permission management)
- **Data Protection** - Keep information safe in transit and at rest
- **Input Validation** - Never trust user input
- **Error Handling** - Don't leak sensitive information
- **Monitoring** - Detect and respond to threats

Think of it as **securing a bank** - you need ID checks, vault access controls, encryption, guards, and alarm systems.

## 🛡️ Security Threat Landscape

### Common Attack Vectors:
```
Web Application Attacks:
├── SQL Injection - Malicious database queries
├── XSS (Cross-Site Scripting) - Malicious client-side scripts
├── CSRF (Cross-Site Request Forgery) - Unauthorized actions
├── Authentication Bypass - Weak login mechanisms
├── Data Exposure - Sensitive information leaks
├── API Abuse - Unauthorized API usage
└── Dependency Vulnerabilities - Insecure libraries
```

### Real-World Impact:
```
Security Breach Consequences:
├── Data theft (customer information, passwords)
├── Financial loss (fraud, ransomware)
├── Reputation damage (customer trust)
├── Legal liability (GDPR, compliance violations)
├── Business disruption (downtime, recovery costs)
└── Competitive disadvantage (stolen IP)
```

## 🔐 Authentication & Authorization

### 1. **JWT Authentication Implementation**

#### Secure JWT Setup:
```python
# backend/app/auth/jwt_handler.py
import jwt
import secrets
from datetime import datetime, timedelta
from passlib.context import CryptContext
from fastapi import HTTPException, status

class JWTHandler:
    """Secure JWT token management."""
    
    def __init__(self):
        # Use strong, randomly generated secret key
        self.SECRET_KEY = secrets.token_urlsafe(32)  # Generate 32-byte key
        self.ALGORITHM = "HS256"
        self.ACCESS_TOKEN_EXPIRE_MINUTES = 15  # Short-lived access tokens
        self.REFRESH_TOKEN_EXPIRE_DAYS = 7     # Longer-lived refresh tokens
        
        # Strong password hashing
        self.pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
    
    def create_access_token(self, data: dict) -> str:
        """Create short-lived access token."""
        to_encode = data.copy()
        expire = datetime.utcnow() + timedelta(minutes=self.ACCESS_TOKEN_EXPIRE_MINUTES)
        
        to_encode.update({
            "exp": expire,
            "iat": datetime.utcnow(),  # Issued at
            "type": "access"
        })
        
        return jwt.encode(to_encode, self.SECRET_KEY, algorithm=self.ALGORITHM)
    
    def create_refresh_token(self, data: dict) -> str:
        """Create long-lived refresh token."""
        to_encode = data.copy()
        expire = datetime.utcnow() + timedelta(days=self.REFRESH_TOKEN_EXPIRE_DAYS)
        
        to_encode.update({
            "exp": expire,
            "iat": datetime.utcnow(),
            "type": "refresh"
        })
        
        return jwt.encode(to_encode, self.SECRET_KEY, algorithm=self.ALGORITHM)
    
    def verify_token(self, token: str, token_type: str = "access") -> dict:
        """Verify and decode JWT token."""
        try:
            payload = jwt.decode(token, self.SECRET_KEY, algorithms=[self.ALGORITHM])
            
            # Verify token type
            if payload.get("type") != token_type:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid token type"
                )
            
            # Check expiration
            if datetime.fromtimestamp(payload["exp"]) < datetime.utcnow():
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Token expired"
                )
            
            return payload
            
        except jwt.ExpiredSignatureError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token expired"
            )
        except jwt.InvalidTokenError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )
    
    def hash_password(self, password: str) -> str:
        """Hash password with bcrypt."""
        return self.pwd_context.hash(password)
    
    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """Verify password against hash."""
        return self.pwd_context.verify(plain_password, hashed_password)
```

#### Secure Login Endpoint:
```python
# backend/app/routers/auth.py
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
import time
from datetime import datetime

router = APIRouter()

# Rate limiting for login attempts
login_attempts = {}  # In production, use Redis
MAX_LOGIN_ATTEMPTS = 5
LOCKOUT_DURATION = 300  # 5 minutes

@router.post("/login")
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    """
    Secure login with rate limiting and account lockout.
    
    Security measures:
    1. Rate limiting per IP
    2. Account lockout after failed attempts
    3. Secure password verification
    4. Token pair generation
    5. Audit logging
    """
    
    client_ip = request.client.host
    current_time = time.time()
    
    # Rate limiting check
    if client_ip in login_attempts:
        attempts = login_attempts[client_ip]
        if len(attempts) >= MAX_LOGIN_ATTEMPTS:
            # Check if lockout period has expired
            if current_time - attempts[-1] < LOCKOUT_DURATION:
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail="Too many login attempts. Please try again later."
                )
            else:
                # Reset attempts after lockout period
                login_attempts[client_ip] = []
    
    try:
        # Get user from database
        user = crud.get_user_by_email(db, form_data.username)
        if not user:
            # Don't reveal if user exists or not
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials"
            )
        
        # Verify password
        if not jwt_handler.verify_password(form_data.password, user.hashed_password):
            # Record failed attempt
            if client_ip not in login_attempts:
                login_attempts[client_ip] = []
            login_attempts[client_ip].append(current_time)
            
            # Log security event
            security_logger.warning(f"Failed login attempt for user {user.email} from {client_ip}")
            
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials"
            )
        
        # Check if user account is active
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Account disabled"
            )
        
        # Successful login - clear failed attempts
        if client_ip in login_attempts:
            del login_attempts[client_ip]
        
        # Generate tokens
        access_token = jwt_handler.create_access_token(data={"sub": user.email})
        refresh_token = jwt_handler.create_refresh_token(data={"sub": user.email})
        
        # Update last login time
        user.last_login = datetime.utcnow()
        db.commit()
        
        # Log successful login
        security_logger.info(f"Successful login for user {user.email} from {client_ip}")
        
        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "expires_in": jwt_handler.ACCESS_TOKEN_EXPIRE_MINUTES * 60
        }
        
    except HTTPException:
        raise
    except Exception as e:
        security_logger.error(f"Login error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Authentication service error"
        )
```

### 2. **Role-Based Access Control (RBAC)**

```python
# backend/app/auth/permissions.py
from enum import Enum
from typing import List, Set
from functools import wraps

class Permission(Enum):
    """Application permissions."""
    READ_OWN_TODOS = "read_own_todos"
    WRITE_OWN_TODOS = "write_own_todos"
    DELETE_OWN_TODOS = "delete_own_todos"
    READ_ALL_TODOS = "read_all_todos"
    WRITE_ALL_TODOS = "write_all_todos"
    DELETE_ALL_TODOS = "delete_all_todos"
    MANAGE_USERS = "manage_users"
    VIEW_ANALYTICS = "view_analytics"

class Role(Enum):
    """User roles with associated permissions."""
    USER = {
        Permission.READ_OWN_TODOS,
        Permission.WRITE_OWN_TODOS,
        Permission.DELETE_OWN_TODOS
    }
    
    MODERATOR = {
        Permission.READ_OWN_TODOS,
        Permission.WRITE_OWN_TODOS,
        Permission.DELETE_OWN_TODOS,
        Permission.READ_ALL_TODOS,
        Permission.VIEW_ANALYTICS
    }
    
    ADMIN = {
        Permission.READ_OWN_TODOS,
        Permission.WRITE_OWN_TODOS,
        Permission.DELETE_OWN_TODOS,
        Permission.READ_ALL_TODOS,
        Permission.WRITE_ALL_TODOS,
        Permission.DELETE_ALL_TODOS,
        Permission.MANAGE_USERS,
        Permission.VIEW_ANALYTICS
    }

class PermissionChecker:
    """Check user permissions for operations."""
    
    @staticmethod
    def has_permission(user_role: Role, required_permission: Permission) -> bool:
        """Check if user role has required permission."""
        return required_permission in user_role.value
    
    @staticmethod
    def require_permission(required_permission: Permission):
        """Decorator to enforce permission requirements."""
        def decorator(func):
            @wraps(func)
            async def wrapper(*args, **kwargs):
                # Get current user from dependency injection
                current_user = kwargs.get('current_user')
                if not current_user:
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail="Authentication required"
                    )
                
                # Check permission
                user_role = Role[current_user.role.upper()]
                if not PermissionChecker.has_permission(user_role, required_permission):
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="Insufficient permissions"
                    )
                
                return await func(*args, **kwargs)
            return wrapper
        return decorator

# Usage in routes
@router.delete("/todos/{todo_id}")
@PermissionChecker.require_permission(Permission.DELETE_OWN_TODOS)
async def delete_todo(
    todo_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete todo with permission check."""
    
    todo = crud.get_todo(db, todo_id)
    if not todo:
        raise HTTPException(status_code=404, detail="Todo not found")
    
    # Additional check: users can only delete their own todos
    # unless they have admin permissions
    if (todo.user_id != current_user.id and 
        not PermissionChecker.has_permission(Role[current_user.role.upper()], Permission.DELETE_ALL_TODOS)):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot delete other users' todos"
        )
    
    crud.delete_todo(db, todo_id)
    return {"message": "Todo deleted successfully"}
```

## 🛡️ Input Validation & Sanitization

### 1. **Comprehensive Input Validation**

```python
# backend/app/schemas/validators.py
from pydantic import BaseModel, Field, validator, EmailStr
import re
from typing import Optional

class TodoCreate(BaseModel):
    """Secure todo creation schema with validation."""
    
    title: str = Field(
        ..., 
        min_length=1, 
        max_length=200,
        description="Todo title (1-200 characters)"
    )
    
    description: Optional[str] = Field(
        None, 
        max_length=1000,
        description="Optional description (max 1000 characters)"
    )
    
    @validator('title')
    def validate_title(cls, v):
        """Validate and sanitize title."""
        if not v or not v.strip():
            raise ValueError('Title cannot be empty')
        
        # Remove potentially dangerous characters
        cleaned_title = re.sub(r'[<>"\']', '', v.strip())
        
        # Check for SQL injection patterns
        sql_patterns = [
            r'\b(union|select|insert|update|delete|drop|exec|execute)\b',
            r'[;\'"\\]',
            r'--',
            r'/\*.*\*/'
        ]
        
        for pattern in sql_patterns:
            if re.search(pattern, cleaned_title, re.IGNORECASE):
                raise ValueError('Invalid characters in title')
        
        return cleaned_title
    
    @validator('description')
    def validate_description(cls, v):
        """Validate and sanitize description."""
        if v is None:
            return v
        
        # Remove script tags and potentially dangerous HTML
        cleaned_desc = re.sub(r'<script.*?</script>', '', v, flags=re.IGNORECASE | re.DOTALL)
        cleaned_desc = re.sub(r'<.*?>', '', cleaned_desc)  # Remove all HTML tags
        
        return cleaned_desc.strip() if cleaned_desc else None

class UserRegistration(BaseModel):
    """Secure user registration schema."""
    
    email: EmailStr = Field(..., description="Valid email address")
    password: str = Field(..., min_length=8, description="Password (min 8 characters)")
    confirm_password: str = Field(..., description="Password confirmation")
    
    @validator('password')
    def validate_password_strength(cls, v):
        """Enforce strong password requirements."""
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')
        
        # Check for uppercase, lowercase, digit, and special character
        checks = [
            (r'[A-Z]', 'uppercase letter'),
            (r'[a-z]', 'lowercase letter'),
            (r'\d', 'digit'),
            (r'[!@#$%^&*(),.?":{}|<>]', 'special character')
        ]
        
        for pattern, requirement in checks:
            if not re.search(pattern, v):
                raise ValueError(f'Password must contain at least one {requirement}')
        
        # Check for common weak passwords
        common_passwords = ['password', '12345678', 'qwerty123', 'admin123']
        if v.lower() in common_passwords:
            raise ValueError('Password is too common')
        
        return v
    
    @validator('confirm_password')
    def passwords_match(cls, v, values, **kwargs):
        """Ensure password confirmation matches."""
        if 'password' in values and v != values['password']:
            raise ValueError('Passwords do not match')
        return v
```

### 2. **SQL Injection Prevention**

```python
# backend/app/crud/secure_queries.py
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List, Optional

class SecureTodoQueries:
    """Secure database queries using parameterized statements."""
    
    @staticmethod
    def get_user_todos_secure(db: Session, user_id: int, search_term: Optional[str] = None) -> List[Todo]:
        """
        Secure todo retrieval with parameterized queries.
        
        NEVER do this (vulnerable to SQL injection):
        query = f"SELECT * FROM todos WHERE user_id = {user_id}"
        
        Always use parameterized queries:
        """
        
        base_query = db.query(Todo).filter(Todo.user_id == user_id)
        
        if search_term:
            # Use SQLAlchemy's built-in parameterization
            safe_search = f"%{search_term}%"
            base_query = base_query.filter(Todo.title.ilike(safe_search))
        
        return base_query.all()
    
    @staticmethod
    def bulk_update_todos_secure(db: Session, todo_ids: List[int], user_id: int, completed: bool):
        """
        Secure bulk update with parameter validation.
        """
        
        # Validate input parameters
        if not todo_ids or len(todo_ids) > 100:  # Limit batch size
            raise ValueError("Invalid todo_ids list")
        
        if not all(isinstance(tid, int) and tid > 0 for tid in todo_ids):
            raise ValueError("All todo IDs must be positive integers")
        
        # Use SQLAlchemy's secure query building
        updated_count = db.query(Todo).filter(
            Todo.id.in_(todo_ids),
            Todo.user_id == user_id  # Ensure user can only update their todos
        ).update(
            {Todo.completed: completed},
            synchronize_session=False
        )
        
        db.commit()
        return updated_count

    @staticmethod
    def search_todos_secure(db: Session, user_id: int, query_params: dict) -> List[Todo]:
        """
        Secure search with multiple filters.
        """
        
        base_query = db.query(Todo).filter(Todo.user_id == user_id)
        
        # Safely handle search parameters
        if 'title' in query_params and query_params['title']:
            title_search = query_params['title'][:100]  # Limit search length
            base_query = base_query.filter(Todo.title.ilike(f"%{title_search}%"))
        
        if 'completed' in query_params:
            if query_params['completed'] in ['true', 'false']:
                completed_val = query_params['completed'] == 'true'
                base_query = base_query.filter(Todo.completed == completed_val)
        
        if 'created_after' in query_params:
            try:
                created_after = datetime.fromisoformat(query_params['created_after'])
                base_query = base_query.filter(Todo.created_at >= created_after)
            except ValueError:
                # Invalid date format - ignore this filter
                pass
        
        # Limit results to prevent large data dumps
        return base_query.limit(1000).all()
```

## 🔐 Data Encryption & Protection

### 1. **Encryption at Rest**

```python
# backend/app/security/encryption.py
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
import base64
import os

class DataEncryption:
    """Handle encryption of sensitive data."""
    
    def __init__(self):
        # Generate or load encryption key
        self.key = self._get_or_create_key()
        self.cipher_suite = Fernet(self.key)
    
    def _get_or_create_key(self) -> bytes:
        """Get encryption key from environment or create new one."""
        key_str = os.getenv('ENCRYPTION_KEY')
        
        if key_str:
            return base64.urlsafe_b64decode(key_str)
        else:
            # In production, this should be stored securely
            key = Fernet.generate_key()
            print(f"Generated new encryption key: {base64.urlsafe_b64encode(key).decode()}")
            return key
    
    def encrypt_sensitive_data(self, data: str) -> str:
        """Encrypt sensitive string data."""
        if not data:
            return data
        
        encrypted_bytes = self.cipher_suite.encrypt(data.encode())
        return base64.urlsafe_b64encode(encrypted_bytes).decode()
    
    def decrypt_sensitive_data(self, encrypted_data: str) -> str:
        """Decrypt sensitive string data."""
        if not encrypted_data:
            return encrypted_data
        
        try:
            encrypted_bytes = base64.urlsafe_b64decode(encrypted_data.encode())
            decrypted_bytes = self.cipher_suite.decrypt(encrypted_bytes)
            return decrypted_bytes.decode()
        except Exception as e:
            raise ValueError(f"Failed to decrypt data: {str(e)}")

# Usage in models
class User(Base):
    """User model with encrypted sensitive fields."""
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    
    # Encrypted sensitive fields
    _phone_number = Column("phone_number", String, nullable=True)
    _social_security = Column("social_security", String, nullable=True)
    
    # Encryption instance
    _encryption = DataEncryption()
    
    @property
    def phone_number(self) -> Optional[str]:
        """Decrypt phone number when accessed."""
        if self._phone_number:
            return self._encryption.decrypt_sensitive_data(self._phone_number)
        return None
    
    @phone_number.setter
    def phone_number(self, value: Optional[str]):
        """Encrypt phone number when set."""
        if value:
            self._phone_number = self._encryption.encrypt_sensitive_data(value)
        else:
            self._phone_number = None
```

### 2. **HTTPS and Transport Security**

```python
# backend/app/security/tls_config.py
from fastapi import FastAPI, Request
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.middleware.httpsredirect import HTTPSRedirectMiddleware

def configure_transport_security(app: FastAPI):
    """Configure HTTPS and transport security."""
    
    # Force HTTPS in production
    if os.getenv('ENVIRONMENT') == 'production':
        app.add_middleware(HTTPSRedirectMiddleware)
    
    # Trusted hosts
    app.add_middleware(
        TrustedHostMiddleware, 
        allowed_hosts=["todoapp.com", "*.todoapp.com", "localhost"]
    )
    
    # Security headers middleware
    @app.middleware("http")
    async def add_security_headers(request: Request, call_next):
        response = await call_next(request)
        
        # HSTS (HTTP Strict Transport Security)
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        
        # Prevent content type sniffing
        response.headers["X-Content-Type-Options"] = "nosniff"
        
        # XSS protection
        response.headers["X-XSS-Protection"] = "1; mode=block"
        
        # Frame options (prevent clickjacking)
        response.headers["X-Frame-Options"] = "DENY"
        
        # Content Security Policy
        response.headers["Content-Security-Policy"] = "default-src 'self'; script-src 'self' 'unsafe-inline'"
        
        # Remove server info
        if "server" in response.headers:
            del response.headers["server"]
        
        return response
```

## 🚨 Security Monitoring & Incident Response

### 1. **Security Event Logging**

```python
# backend/app/security/security_logger.py
import logging
import json
from datetime import datetime
from typing import Dict, Any
from enum import Enum

class SecurityEventType(Enum):
    """Types of security events to monitor."""
    LOGIN_SUCCESS = "login_success"
    LOGIN_FAILURE = "login_failure"
    PASSWORD_CHANGE = "password_change"
    PERMISSION_DENIED = "permission_denied"
    SUSPICIOUS_ACTIVITY = "suspicious_activity"
    DATA_ACCESS = "data_access"
    ADMIN_ACTION = "admin_action"

class SecurityLogger:
    """Centralized security event logging."""
    
    def __init__(self):
        self.logger = logging.getLogger('security')
        self.logger.setLevel(logging.INFO)
        
        # Console handler for development
        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.INFO)
        
        # File handler for production
        file_handler = logging.FileHandler('security.log')
        file_handler.setLevel(logging.INFO)
        
        # Structured logging format
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        console_handler.setFormatter(formatter)
        file_handler.setFormatter(formatter)
        
        self.logger.addHandler(console_handler)
        self.logger.addHandler(file_handler)
    
    def log_security_event(
        self, 
        event_type: SecurityEventType, 
        user_id: int = None,
        ip_address: str = None,
        user_agent: str = None,
        additional_data: Dict[str, Any] = None
    ):
        """Log a security event with structured data."""
        
        event_data = {
            'timestamp': datetime.utcnow().isoformat(),
            'event_type': event_type.value,
            'user_id': user_id,
            'ip_address': ip_address,
            'user_agent': user_agent,
            'additional_data': additional_data or {}
        }
        
        self.logger.info(json.dumps(event_data))
    
    def log_suspicious_activity(
        self, 
        description: str,
        user_id: int = None,
        ip_address: str = None,
        severity: str = "medium"
    ):
        """Log suspicious activity for investigation."""
        
        self.log_security_event(
            SecurityEventType.SUSPICIOUS_ACTIVITY,
            user_id=user_id,
            ip_address=ip_address,
            additional_data={
                'description': description,
                'severity': severity,
                'requires_investigation': True
            }
        )

# Security monitoring middleware
security_logger = SecurityLogger()

@app.middleware("http")
async def security_monitoring(request: Request, call_next):
    """Monitor requests for security threats."""
    
    client_ip = request.client.host
    user_agent = request.headers.get('user-agent', '')
    
    # Check for common attack patterns
    suspicious_patterns = [
        r'union.*select',  # SQL injection
        r'<script',        # XSS attempts
        r'\.\./',          # Directory traversal
        r'eval\(',         # Code injection
        r'exec\(',         # Command injection
    ]
    
    # Check URL and parameters
    full_url = str(request.url)
    for pattern in suspicious_patterns:
        if re.search(pattern, full_url, re.IGNORECASE):
            security_logger.log_suspicious_activity(
                f"Suspicious pattern in URL: {pattern}",
                ip_address=client_ip,
                severity="high"
            )
    
    # Check for unusual request patterns
    if request.method in ['PUT', 'DELETE', 'PATCH']:
        security_logger.log_security_event(
            SecurityEventType.DATA_ACCESS,
            ip_address=client_ip,
            user_agent=user_agent,
            additional_data={
                'method': request.method,
                'path': request.url.path
            }
        )
    
    response = await call_next(request)
    
    # Log failed authentication attempts
    if response.status_code == 401:
        security_logger.log_security_event(
            SecurityEventType.LOGIN_FAILURE,
            ip_address=client_ip,
            user_agent=user_agent,
            additional_data={'path': request.url.path}
        )
    
    return response
```

### 2. **Intrusion Detection**

```python
# backend/app/security/intrusion_detection.py
import asyncio
from collections import defaultdict, deque
from datetime import datetime, timedelta
from typing import Dict, List

class IntrusionDetectionSystem:
    """Real-time intrusion detection and response."""
    
    def __init__(self):
        # Track request patterns per IP
        self.request_counts = defaultdict(deque)  # IP -> timestamps
        self.failed_logins = defaultdict(deque)   # IP -> failed attempts
        self.blocked_ips = set()                  # Currently blocked IPs
        
        # Detection thresholds
        self.MAX_REQUESTS_PER_MINUTE = 60
        self.MAX_FAILED_LOGINS = 5
        self.BLOCK_DURATION = 300  # 5 minutes
        
        # Start cleanup task
        asyncio.create_task(self._cleanup_old_data())
    
    def check_rate_limit(self, ip_address: str) -> bool:
        """Check if IP is making too many requests."""
        current_time = datetime.utcnow()
        
        # Clean old entries
        while (self.request_counts[ip_address] and 
               current_time - self.request_counts[ip_address][0] > timedelta(minutes=1)):
            self.request_counts[ip_address].popleft()
        
        # Add current request
        self.request_counts[ip_address].append(current_time)
        
        # Check if over limit
        if len(self.request_counts[ip_address]) > self.MAX_REQUESTS_PER_MINUTE:
            self._block_ip(ip_address, "Rate limit exceeded")
            return False
        
        return True
    
    def record_failed_login(self, ip_address: str) -> bool:
        """Record failed login attempt and check for brute force."""
        current_time = datetime.utcnow()
        
        # Clean old entries (last 15 minutes)
        while (self.failed_logins[ip_address] and 
               current_time - self.failed_logins[ip_address][0] > timedelta(minutes=15)):
            self.failed_logins[ip_address].popleft()
        
        # Add current failure
        self.failed_logins[ip_address].append(current_time)
        
        # Check for brute force attack
        if len(self.failed_logins[ip_address]) >= self.MAX_FAILED_LOGINS:
            self._block_ip(ip_address, "Brute force attack detected")
            return False
        
        return True
    
    def is_ip_blocked(self, ip_address: str) -> bool:
        """Check if IP is currently blocked."""
        return ip_address in self.blocked_ips
    
    def _block_ip(self, ip_address: str, reason: str):
        """Block an IP address and log the event."""
        self.blocked_ips.add(ip_address)
        
        security_logger.log_security_event(
            SecurityEventType.SUSPICIOUS_ACTIVITY,
            ip_address=ip_address,
            additional_data={
                'action': 'ip_blocked',
                'reason': reason,
                'block_duration': self.BLOCK_DURATION
            }
        )
        
        # Schedule unblock
        asyncio.create_task(self._schedule_unblock(ip_address))
    
    async def _schedule_unblock(self, ip_address: str):
        """Unblock IP after timeout."""
        await asyncio.sleep(self.BLOCK_DURATION)
        if ip_address in self.blocked_ips:
            self.blocked_ips.remove(ip_address)
            
            security_logger.log_security_event(
                SecurityEventType.SUSPICIOUS_ACTIVITY,
                ip_address=ip_address,
                additional_data={'action': 'ip_unblocked'}
            )
    
    async def _cleanup_old_data(self):
        """Periodically clean up old tracking data."""
        while True:
            await asyncio.sleep(300)  # Clean every 5 minutes
            
            current_time = datetime.utcnow()
            
            # Clean request counts
            for ip in list(self.request_counts.keys()):
                while (self.request_counts[ip] and 
                       current_time - self.request_counts[ip][0] > timedelta(hours=1)):
                    self.request_counts[ip].popleft()
                
                if not self.request_counts[ip]:
                    del self.request_counts[ip]
            
            # Clean failed login attempts
            for ip in list(self.failed_logins.keys()):
                while (self.failed_logins[ip] and 
                       current_time - self.failed_logins[ip][0] > timedelta(hours=1)):
                    self.failed_logins[ip].popleft()
                
                if not self.failed_logins[ip]:
                    del self.failed_logins[ip]

# Global IDS instance
ids = IntrusionDetectionSystem()

# Middleware integration
@app.middleware("http")
async def intrusion_detection_middleware(request: Request, call_next):
    """Integrate intrusion detection into request pipeline."""
    
    client_ip = request.client.host
    
    # Check if IP is blocked
    if ids.is_ip_blocked(client_ip):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="IP address is temporarily blocked"
        )
    
    # Check rate limits
    if not ids.check_rate_limit(client_ip):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Rate limit exceeded"
        )
    
    response = await call_next(request)
    
    # Record failed authentication attempts
    if response.status_code == 401 and request.url.path == "/auth/login":
        ids.record_failed_login(client_ip)
    
    return response
```

## 🔍 Vulnerability Assessment

### 1. **Dependency Security Scanning**

```bash
# requirements-security.txt
# Add security scanning tools to your project

safety==2.3.1           # Check for known vulnerabilities
bandit==1.7.4           # Python security linting
semgrep==1.45.0         # Static analysis security scanner
```

```python
# scripts/security_check.py
#!/usr/bin/env python3
"""
Security vulnerability scanner for the todo app.
"""

import subprocess
import sys
import json
from typing import List, Dict

class SecurityScanner:
    """Automated security vulnerability scanner."""
    
    def __init__(self):
        self.vulnerabilities = []
    
    def scan_dependencies(self) -> List[Dict]:
        """Scan dependencies for known vulnerabilities."""
        print("🔍 Scanning dependencies for vulnerabilities...")
        
        try:
            # Run safety check
            result = subprocess.run(
                ['safety', 'check', '--json'],
                capture_output=True,
                text=True,
                check=False
            )
            
            if result.stdout:
                vulnerabilities = json.loads(result.stdout)
                for vuln in vulnerabilities:
                    self.vulnerabilities.append({
                        'type': 'dependency',
                        'severity': 'high',
                        'package': vuln.get('package', 'unknown'),
                        'vulnerability': vuln.get('vulnerability', 'unknown'),
                        'affected_versions': vuln.get('affected_versions', []),
                        'recommendation': f"Update {vuln.get('package', 'package')} to safe version"
                    })
            
            return self.vulnerabilities
            
        except Exception as e:
            print(f"❌ Dependency scan failed: {e}")
            return []
    
    def scan_code_security(self) -> List[Dict]:
        """Scan code for security issues using Bandit."""
        print("🔍 Scanning code for security issues...")
        
        try:
            result = subprocess.run(
                ['bandit', '-r', 'backend/', '-f', 'json'],
                capture_output=True,
                text=True,
                check=False
            )
            
            if result.stdout:
                bandit_results = json.loads(result.stdout)
                
                for issue in bandit_results.get('results', []):
                    self.vulnerabilities.append({
                        'type': 'code',
                        'severity': issue.get('issue_severity', 'medium').lower(),
                        'file': issue.get('filename', 'unknown'),
                        'line': issue.get('line_number', 0),
                        'issue': issue.get('issue_text', 'Unknown issue'),
                        'recommendation': issue.get('issue_cwe', {}).get('name', 'Review code')
                    })
            
            return self.vulnerabilities
            
        except Exception as e:
            print(f"❌ Code security scan failed: {e}")
            return []
    
    def generate_security_report(self):
        """Generate comprehensive security report."""
        
        # Run all scans
        self.scan_dependencies()
        self.scan_code_security()
        
        # Generate report
        print("\n" + "="*60)
        print("🛡️  SECURITY VULNERABILITY REPORT")
        print("="*60)
        
        if not self.vulnerabilities:
            print("✅ No vulnerabilities found!")
            return True
        
        # Group by severity
        high_severity = [v for v in self.vulnerabilities if v['severity'] == 'high']
        medium_severity = [v for v in self.vulnerabilities if v['severity'] == 'medium']
        low_severity = [v for v in self.vulnerabilities if v['severity'] == 'low']
        
        print(f"🔴 High Severity: {len(high_severity)}")
        print(f"🟡 Medium Severity: {len(medium_severity)}")
        print(f"🟢 Low Severity: {len(low_severity)}")
        print()
        
        # Print high severity issues
        if high_severity:
            print("🔴 HIGH SEVERITY ISSUES:")
            for vuln in high_severity:
                print(f"  - {vuln['type'].upper()}: {vuln.get('issue', vuln.get('vulnerability', 'Unknown'))}")
                if 'file' in vuln:
                    print(f"    File: {vuln['file']}:{vuln.get('line', '')}")
                print(f"    Recommendation: {vuln['recommendation']}")
                print()
        
        # Return False if high severity issues found
        return len(high_severity) == 0

if __name__ == "__main__":
    scanner = SecurityScanner()
    safe = scanner.generate_security_report()
    
    if not safe:
        print("❌ Security vulnerabilities found! Please address before deployment.")
        sys.exit(1)
    else:
        print("✅ Security scan passed!")
        sys.exit(0)
```

### 2. **Automated Security Testing**

```python
# tests/security/test_security.py
import pytest
import requests
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

class TestSecurityBasics:
    """Test basic security features."""
    
    def test_sql_injection_prevention(self):
        """Test that SQL injection attempts are blocked."""
        
        # Attempt SQL injection in search parameter
        malicious_payloads = [
            "'; DROP TABLE todos; --",
            "' UNION SELECT * FROM users --",
            "1' OR '1'='1",
            "admin'--",
            "' OR 1=1#"
        ]
        
        for payload in malicious_payloads:
            response = client.get(f"/todos?search={payload}")
            
            # Should not return sensitive data or cause errors
            assert response.status_code in [400, 422, 404]
            if response.status_code == 200:
                # Ensure no sensitive data leaked
                assert "users" not in response.text.lower()
                assert "password" not in response.text.lower()
    
    def test_xss_prevention(self):
        """Test that XSS attempts are sanitized."""
        
        xss_payloads = [
            "<script>alert('xss')</script>",
            "<img src=x onerror=alert('xss')>",
            "javascript:alert('xss')",
            "<svg onload=alert('xss')>",
        ]
        
        for payload in xss_payloads:
            response = client.post(
                "/todos",
                json={"title": payload, "description": payload},
                headers={"Authorization": "Bearer valid-token"}
            )
            
            if response.status_code == 201:
                # Check that dangerous scripts were removed
                todo_data = response.json()
                assert "<script>" not in todo_data["title"]
                assert "javascript:" not in todo_data["title"]
                assert "onerror=" not in todo_data["title"]
    
    def test_authentication_required(self):
        """Test that protected endpoints require authentication."""
        
        protected_endpoints = [
            ("GET", "/todos"),
            ("POST", "/todos"),
            ("PUT", "/todos/1"),
            ("DELETE", "/todos/1"),
        ]
        
        for method, endpoint in protected_endpoints:
            response = client.request(method, endpoint)
            assert response.status_code == 401
    
    def test_rate_limiting(self):
        """Test that rate limiting works."""
        
        # Make many requests quickly
        responses = []
        for i in range(100):
            response = client.get("/health")
            responses.append(response.status_code)
        
        # Should eventually get rate limited
        assert 429 in responses  # Too Many Requests
    
    def test_security_headers(self):
        """Test that security headers are present."""
        
        response = client.get("/health")
        
        # Check for important security headers
        headers = response.headers
        assert "x-content-type-options" in headers
        assert headers["x-content-type-options"] == "nosniff"
        assert "x-frame-options" in headers
        assert "strict-transport-security" in headers
    
    def test_password_requirements(self):
        """Test password strength requirements."""
        
        weak_passwords = [
            "123",
            "password",
            "abc123",
            "qwerty",
            "admin"
        ]
        
        for weak_password in weak_passwords:
            response = client.post("/auth/register", json={
                "email": "test@example.com",
                "password": weak_password,
                "confirm_password": weak_password
            })
            
            assert response.status_code == 422  # Validation error
```

## 🎓 Key Takeaways

1. **Authentication is the foundation** - strong passwords, JWT tokens, rate limiting
2. **Authorization controls access** - role-based permissions, resource ownership
3. **Input validation prevents attacks** - sanitize all user data, parameterized queries
4. **Encryption protects data** - at rest and in transit
5. **Monitoring detects threats** - security logging, intrusion detection
6. **Testing finds vulnerabilities** - automated scanning, security tests
7. **Headers provide defense** - HTTPS, CSP, frame protection
8. **Regular updates are critical** - dependency patches, security reviews

## 🛠️ Practical Exercise

Implement security measures in your todo app:

### 1. **Add Authentication**:
```bash
# Install security dependencies
pip install python-jose[cryptography] passlib[bcrypt] python-multipart

# Implement JWT authentication
# Add password hashing
# Create login/register endpoints
```

### 2. **Run Security Scans**:
```bash
# Install security tools
pip install safety bandit

# Scan for vulnerabilities
safety check
bandit -r backend/

# Fix any issues found
```

### 3. **Test Security**:
```bash
# Run security tests
pytest tests/security/

# Try manual penetration testing
# Test with OWASP ZAP or similar tools
```

---

**Previous**: [Data Flow Architecture](13-data-flow-architecture.md) | **Complete Learning Guide**: [Index](index.md)