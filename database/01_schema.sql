DROP SCHEMA IF EXISTS ecommerce CASCADE;
CREATE SCHEMA ecommerce;
SET search_path TO ecommerce, public;

CREATE TABLE categories (
    category_id BIGSERIAL PRIMARY KEY,
    category_name VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE customers (
    customer_id BIGSERIAL PRIMARY KEY,
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    country VARCHAR(100) DEFAULT 'India',
    signup_date DATE NOT NULL,
    customer_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    CHECK (customer_status IN ('ACTIVE','INACTIVE','SUSPENDED'))
);

CREATE TABLE products (
    product_id BIGSERIAL PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    category_id BIGINT NOT NULL REFERENCES categories(category_id),
    price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
    cost NUMERIC(12,2) NOT NULL CHECK (cost >= 0),
    stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (price >= cost)
);

CREATE TABLE orders (
    order_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(customer_id),
    order_date TIMESTAMP NOT NULL,
    order_status VARCHAR(20) NOT NULL,
    total_amount NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    CHECK (order_status IN ('COMPLETED','CANCELLED','PENDING','SHIPPED','RETURNED'))
);

CREATE TABLE order_items (
    order_item_id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES products(product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    discount NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (discount BETWEEN 0 AND 100)
);

CREATE TABLE payments (
    payment_id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    payment_date TIMESTAMP NOT NULL,
    amount NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
    payment_method VARCHAR(30) NOT NULL,
    payment_status VARCHAR(20) NOT NULL,
    CHECK (payment_method IN ('UPI','CARD','NET_BANKING','COD','WALLET')),
    CHECK (payment_status IN ('SUCCESS','FAILED','REFUNDED','PENDING'))
);

CREATE TABLE returns (
    return_id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(order_id),
    order_item_id BIGINT REFERENCES order_items(order_item_id),
    return_date DATE NOT NULL,
    return_reason VARCHAR(100) NOT NULL,
    refund_amount NUMERIC(14,2) NOT NULL CHECK (refund_amount >= 0),
    return_status VARCHAR(20) NOT NULL,
    CHECK (return_status IN ('REQUESTED','APPROVED','REFUNDED','REJECTED'))
);

CREATE TABLE reviews (
    review_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(customer_id),
    product_id BIGINT NOT NULL REFERENCES products(product_id),
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_date DATE NOT NULL,
    review_text VARCHAR(500)
);

CREATE TABLE campaigns (
    campaign_id BIGSERIAL PRIMARY KEY,
    campaign_name VARCHAR(150) NOT NULL,
    campaign_type VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    budget NUMERIC(14,2) NOT NULL CHECK (budget >= 0),
    CHECK (end_date >= start_date)
);

CREATE TABLE customer_campaigns (
    customer_id BIGINT REFERENCES customers(customer_id) ON DELETE CASCADE,
    campaign_id BIGINT REFERENCES campaigns(campaign_id) ON DELETE CASCADE,
    joined_at TIMESTAMP NOT NULL,
    PRIMARY KEY (customer_id, campaign_id)
);

CREATE TABLE customer_events (
    event_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    event_type VARCHAR(40) NOT NULL,
    event_timestamp TIMESTAMP NOT NULL,
    CHECK (event_type IN ('LOGIN','PRODUCT_VIEW','ADD_TO_CART','PURCHASE','REVIEW','WISHLIST'))
);

CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);
CREATE INDEX idx_orders_status_date ON orders(order_status, order_date);
CREATE INDEX idx_order_items_product ON order_items(product_id);
CREATE INDEX idx_payments_order_status ON payments(order_id, payment_status);
CREATE INDEX idx_returns_order ON returns(order_id);
CREATE INDEX idx_reviews_product ON reviews(product_id);
CREATE INDEX idx_events_customer_time ON customer_events(customer_id, event_timestamp);
