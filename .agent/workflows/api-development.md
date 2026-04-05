---
description: API development and testing guide
---

# API Development

Develop and test GridTokenX REST APIs.

## Quick Commands

// turbo

```bash
# Run API Gateway
cd gridtokenx-api && cargo run

# Run with auto-reload
cargo watch -x run

# Run tests
cargo test

# Format code
cargo fmt

# Lint code
cargo clippy
```

## API Structure

### Project Layout

```
gridtokenx-api/
├── src/
│   ├── main.rs              # Application entry
│   ├── config.rs            # Configuration
│   ├── routes/              # Route handlers
│   │   ├── mod.rs
│   │   ├── users.rs         # User endpoints
│   │   ├── orders.rs        # Trading orders
│   │   ├── markets.rs       # Market endpoints
│   │   └── admin.rs         # Admin endpoints
│   ├── services/            # Business logic
│   ├── models/              # Data models
│   ├── db/                  # Database layer
│   └── middleware/          # Request middleware
├── migrations/              # SQL migrations
└── tests/                   # Integration tests
```

## Creating Endpoints

### Basic Route Handler

```rust
// src/routes/users.rs
use axum::{
    extract::State,
    http::StatusCode,
    Json,
};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
pub struct CreateUserRequest {
    pub email: String,
    pub username: String,
    pub password: String,
}

#[derive(Serialize)]
pub struct UserResponse {
    pub id: String,
    pub email: String,
    pub username: String,
}

pub async fn create_user(
    State(state): State<AppState>,
    Json(payload): Json<CreateUserRequest>,
) -> Result<Json<UserResponse>, StatusCode> {
    let user = state.db.create_user(&payload).await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(UserResponse {
        id: user.id.to_string(),
        email: user.email,
        username: user.username,
    }))
}
```

### Register Route

```rust
// src/routes/mod.rs
use axum::{Router, routing::post};

pub fn users_router(state: AppState) -> Router {
    Router::new()
        .route("/api/v1/users", post(create_user))
        .route("/api/v1/users/:id", get(get_user))
        .route("/api/v1/users/:id", put(update_user))
        .route("/api/v1/users/:id", delete(delete_user))
        .with_state(state)
}
```

## Database Operations

### Using SQLx

```rust
// src/db/users.rs
use sqlx::PgPool;
use uuid::Uuid;

pub struct UserRepository {
    pool: PgPool,
}

impl UserRepository {
    pub async fn create(&self, email: &str, username: &str) -> Result<Uuid, sqlx::Error> {
        let id = Uuid::new_v4();
        
        sqlx::query!(
            "INSERT INTO users (id, email, username) VALUES ($1, $2, $3)",
            id,
            email,
            username
        )
        .execute(&self.pool)
        .await?;

        Ok(id)
    }

    pub async fn find_by_email(&self, email: &str) -> Result<Option<User>, sqlx::Error> {
        let user = sqlx::query_as!(
            User,
            "SELECT * FROM users WHERE email = $1",
            email
        )
        .fetch_optional(&self.pool)
        .await?;

        Ok(user)
    }
}
```

## Authentication

### JWT Middleware

```rust
// src/middleware/auth.rs
use axum::{
    extract::State,
    http::{Request, StatusCode},
    middleware::Next,
    response::Response,
};

pub async fn auth_middleware<B>(
    State(state): State<AppState>,
    mut request: Request<B>,
    next: Next<B>,
) -> Result<Response, StatusCode> {
    let auth_header = request.headers()
        .get(http::header::AUTHORIZATION)
        .and_then(|h| h.to_str().ok());

    let token = auth_header
        .and_then(|h| h.strip_prefix("Bearer "))
        .ok_or(StatusCode::UNAUTHORIZED)?;

    let claims = state.verify_token(token)
        .map_err(|_| StatusCode::UNAUTHORIZED)?;

    request.extensions_mut().insert(claims);

    Ok(next.run(request).await)
}
```

### Protected Route

```rust
use axum::extract::Extension;

pub async fn protected_endpoint(
    Extension(claims): Extension<Claims>,
) -> Json<UserResponse> {
    Json(UserResponse {
        id: claims.user_id,
        email: claims.email,
    })
}
```

## API Testing

### Unit Tests

```rust
// tests/user_tests.rs
#[cfg(test)]
mod tests {
    use super::*;
    use axum::body::Body;
    use http::Request;
    use tower::ServiceExt;

    #[tokio::test]
    async fn test_create_user() {
        let app = create_app();

        let response = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/api/v1/users")
                    .header("Content-Type", "application/json")
                    .body(Body::from(r#"{"email":"test@example.com","username":"test","password":"pass123"}"#))
                    .unwrap()
            )
            .await
            .unwrap();

        assert_eq!(response.status(), StatusCode::CREATED);
    }
}
```

### Integration Tests

```bash
# Run integration tests
./gridtokenx-api/tests/scripts/test_api_integration.sh

# Or with curl
curl -X POST http://localhost:4000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","username":"test","password":"pass123"}'
```

## Error Handling

### Custom Error Type

```rust
// src/error.rs
use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde_json::json;

pub enum AppError {
    NotFound(String),
    BadRequest(String),
    Unauthorized,
    InternalError(String),
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, message) = match self {
            AppError::NotFound(msg) => (StatusCode::NOT_FOUND, msg),
            AppError::BadRequest(msg) => (StatusCode::BAD_REQUEST, msg),
            AppError::Unauthorized => (StatusCode::UNAUTHORIZED, "Unauthorized".to_string()),
            AppError::InternalError(msg) => (StatusCode::INTERNAL_SERVER_ERROR, msg),
        };

        let body = Json(json!({
            "error": message,
        }));

        (status, body).into_response()
    }
}
```

## API Documentation

### OpenAPI/Swagger

```rust
// Use utoipa for OpenAPI generation
use utoipa::OpenApi;

#[derive(OpenApi)]
#[openapi(
    paths(
        create_user,
        get_user,
        update_user,
        delete_user,
    ),
    components(
        schemas(
            CreateUserRequest,
            UserResponse,
        )
    )
)]
pub struct ApiDoc;
```

Access at: http://localhost:4000/api/docs

## Rate Limiting

### Configure Rate Limits

```rust
// src/middleware/rate_limit.rs
use governor::{Quota, RateLimiter};
use std::num::NonZeroU32;

pub fn create_rate_limiter() -> RateLimiter {
    let quota = Quota::per_minute(NonZeroU32::new(60).unwrap());
    RateLimiter::direct(quota)
}
```

## Logging

### Structured Logging

```rust
use tracing::{info, error, warn};

pub async fn create_user(...) -> Result<..., AppError> {
    info!(email = %payload.email, "Creating new user");

    match state.db.create_user(&payload).await {
        Ok(user) => {
            info!(user_id = %user.id, "User created successfully");
            Ok(user)
        }
        Err(e) => {
            error!(error = %e, "Failed to create user");
            Err(AppError::InternalError(e.to_string()))
        }
    }
}
```

## Related Workflows

- [Testing](./testing.md) - Run API tests
- [Debugging](./debugging.md) - Debug API issues
- [Monitoring](./monitoring.md) - Monitor API metrics
