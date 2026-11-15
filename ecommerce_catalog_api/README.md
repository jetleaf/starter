# E-Commerce Catalog & Checkout REST API

A real-world e-commerce backend built with **Jetleaf 2.0**, showcasing RESTful controllers, deep request validation, constructor-injected service pods, domain error handling, and clean architecture.

---

## 🍃 Jetleaf Features Showcased

* **`@RestController` Routing**: Declarative route definitions with `@GetMapping`, `@PostMapping`, and `@DeleteMapping`.
* **Parameter Resolvers**: Type-safe extraction of path variables (`@PathVariable`), query parameters (`@RequestParam`), and JSON bodies (`@RequestBody`).
* **Inversion of Control (IoC)**: Decoupled service pods (`@Service`) wired via constructor dependency injection (`OrderService` $\to$ `ProductService`, `CartService`).
* **Deep Request Validation**: Hibernate-style constraint validation with `jetleaf_validation` (`@NotBlank`, `@Size`, `@Positive`, `@Min`, `@Email`).
* **Centralized Error Advice**: `@RestControllerAdvice` and `@ExceptionHandler` mapping domain exceptions (`ProductNotFoundException`, `InsufficientStockException`, `EmptyCartException`) to RFC 7807 problem details.
* **Declarative Responses**: `ResponseBody.ok()`, `ResponseBody.created()`, and `ResponseBody.notFound()`.

---

## 📂 Project Structure

```text
ecommerce_catalog_api/
├── pubspec.yaml
├── resources/
│   └── application.yaml              # Server port & application metadata
├── lib/
│   ├── main.dart                     # @JetleafApplicationStarter & main()
│   └── src/
│       ├── models/
│       │   ├── product.dart          # Product domain entity
│       │   ├── cart_item.dart        # Shopping cart item
│       │   ├── cart.dart             # Cart session
│       │   └── customer_order.dart   # Finalized order model
│       ├── dto/
│       │   ├── create_product_dto.dart # Product creation payload with constraints
│       │   ├── add_to_cart_dto.dart    # Cart item addition payload
│       │   └── checkout_dto.dart       # Checkout payload with @Email & @Size
│       ├── exceptions/
│       │   └── ecommerce_exceptions.dart # Typed domain exceptions
│       ├── services/
│       │   ├── product_service.dart   # Product inventory & stock reservation
│       │   ├── cart_service.dart      # Cart state management
│       │   └── order_service.dart     # Checkout coordination & stock decrement
│       ├── controllers/
│       │   ├── product_controller.dart # /api/v1/products endpoints
│       │   ├── cart_controller.dart    # /api/v1/cart endpoints
│       │   └── order_controller.dart   # /api/v1/orders endpoints
│       └── advice/
│           └── ecommerce_exception_advice.dart # Global REST exception handlers
└── test/
    └── services/
        ├── product_service_test.dart
        └── order_service_test.dart
```

---

## 🚀 Running the Project

### 1. Install Dependencies
```bash
dart pub get
```

### 2. Start the Development Server (with Hot Reload)
```bash
jl dev
```
The server will boot on `http://localhost:8080`.

---

## 📡 API Endpoints & cURL Examples

### 🛍️ Products (`/api/v1/products`)

#### 1. List Products (with optional search/category filters)
```bash
curl -X GET "http://localhost:8080/api/v1/products?category=Peripherals"
```

#### 2. Get Product by ID
```bash
curl -X GET "http://localhost:8080/api/v1/products/prod-1"
```

#### 3. Create a New Product
```bash
curl -X POST "http://localhost:8080/api/v1/products" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Noise-Cancelling Studio Headphones",
    "description": "Wireless over-ear headphones with active noise cancellation.",
    "price": 249.99,
    "stockQuantity": 30,
    "category": "Audio"
  }'
```

---

### 🛒 Shopping Cart (`/api/v1/cart`)

#### 1. Inspect Current Cart
```bash
curl -X GET "http://localhost:8080/api/v1/cart?cartId=user-123"
```

#### 2. Add Item to Cart
```bash
curl -X POST "http://localhost:8080/api/v1/cart/items?cartId=user-123" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": "prod-1",
    "quantity": 2
  }'
```

#### 3. Remove Item from Cart
```bash
curl -X DELETE "http://localhost:8080/api/v1/cart/items/prod-1?cartId=user-123"
```

---

### 💳 Orders & Checkout (`/api/v1/orders`)

#### 1. Checkout Cart
```bash
curl -X POST "http://localhost:8080/api/v1/orders/checkout?cartId=user-123" \
  -H "Content-Type: application/json" \
  -d '{
    "customerEmail": "alex.dev@example.com",
    "shippingAddress": "742 Evergreen Terrace, Springfield, OR"
  }'
```

#### 2. Get Order Details
```bash
curl -X GET "http://localhost:8080/api/v1/orders/ORD-1001"
```

---

## 🧪 Running Tests

```bash
dart test
```
All unit tests verify inventory reservation, cart calculation, exception escalation, and checkout stock bounds.
