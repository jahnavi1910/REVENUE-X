SET search_path TO ecommerce, public;
SELECT setseed(0.314159);

INSERT INTO categories(category_name) VALUES
('Electronics'),('Fashion'),('Home & Kitchen'),('Beauty'),('Sports'),
('Books'),('Grocery'),('Accessories'),('Toys'),('Office');

INSERT INTO customers(first_name,last_name,email,city,state,country,signup_date,customer_status)
SELECT
    'Customer' || g,
    'User' || g,
    'customer' || g || '@example.com',
    (ARRAY['Hyderabad','Bengaluru','Mumbai','Delhi','Pune','Chennai','Kolkata','Ahmedabad','Jaipur','Kochi'])[1+floor(random()*10)::int],
    (ARRAY['Telangana','Karnataka','Maharashtra','Delhi','Maharashtra','Tamil Nadu','West Bengal','Gujarat','Rajasthan','Kerala'])[1+floor(random()*10)::int],
    'India',
    DATE '2022-01-01' + floor(random()*1500)::int,
    CASE WHEN random() < .92 THEN 'ACTIVE' WHEN random() < .97 THEN 'INACTIVE' ELSE 'SUSPENDED' END
FROM generate_series(1,10000) g;

INSERT INTO products(product_name,category_id,price,cost,stock_quantity,created_at)
SELECT
    'Product ' || g,
    1 + floor(random()*10)::bigint,
    p.price,
    round((p.price * (0.35 + random()*0.40))::numeric,2),
    floor(10+random()*500)::int,
    TIMESTAMP '2023-01-01' + (floor(random()*1000)::int || ' days')::interval
FROM generate_series(1,500) g
CROSS JOIN LATERAL (
    SELECT round((199 + random()*19801)::numeric,2) AS price
) p;

INSERT INTO orders(customer_id,order_date,order_status,total_amount)
SELECT
    1 + floor(random()*10000)::bigint,
    TIMESTAMP '2024-01-01' + (floor(random()*1000)::int || ' days')::interval,
    CASE
        WHEN random() < .72 THEN 'COMPLETED'
        WHEN random() < .84 THEN 'SHIPPED'
        WHEN random() < .91 THEN 'PENDING'
        WHEN random() < .97 THEN 'CANCELLED'
        ELSE 'RETURNED'
    END,
    0
FROM generate_series(1,50000);

INSERT INTO order_items(order_id,product_id,quantity,unit_price,discount)
SELECT
    o.order_id,
    1 + floor(random()*500)::bigint,
    1 + floor(random()*4)::int,
    p.price,
    round((random()*20)::numeric,2)
FROM orders o
CROSS JOIN LATERAL generate_series(1,1+floor(random()*3)::int) x
JOIN products p ON p.product_id = 1 + floor(random()*500)::bigint;

UPDATE orders o
SET total_amount = x.total
FROM (
    SELECT order_id,
           round(sum(quantity * unit_price * (1-discount/100.0))::numeric,2) AS total
    FROM order_items
    GROUP BY order_id
) x
WHERE o.order_id = x.order_id;

INSERT INTO payments(order_id,payment_date,amount,payment_method,payment_status)
SELECT
    order_id,
    order_date + (floor(random()*3)::int || ' hours')::interval,
    total_amount,
    (ARRAY['UPI','CARD','NET_BANKING','COD','WALLET'])[1+floor(random()*5)::int],
    CASE
        WHEN order_status='CANCELLED' THEN 'FAILED'
        WHEN order_status='RETURNED' THEN 'REFUNDED'
        WHEN random() < .96 THEN 'SUCCESS'
        ELSE 'PENDING'
    END
FROM orders;

INSERT INTO returns(order_id,order_item_id,return_date,return_reason,refund_amount,return_status)
SELECT
    oi.order_id,
    oi.order_item_id,
    o.order_date::date + 1 + floor(random()*30)::int,
    (ARRAY['Damaged','Wrong item','Size issue','Not as expected','Changed mind'])[1+floor(random()*5)::int],
    round((oi.quantity*oi.unit_price*(1-oi.discount/100.0))::numeric,2),
    CASE WHEN random() < .8 THEN 'REFUNDED' ELSE 'APPROVED' END
FROM order_items oi
JOIN orders o ON o.order_id=oi.order_id
WHERE random() < .035;

INSERT INTO reviews(customer_id,product_id,rating,review_date,review_text)
SELECT
    1+floor(random()*10000)::bigint,
    1+floor(random()*500)::bigint,
    1+floor(random()*5)::int,
    DATE '2024-01-01'+floor(random()*1000)::int,
    'Synthetic customer review'
FROM generate_series(1,12000);

INSERT INTO campaigns(campaign_name,campaign_type,start_date,end_date,budget)
VALUES
('Festival Mega Sale','DISCOUNT','2025-01-10','2025-01-20',500000),
('Summer Cashback','CASHBACK','2025-04-01','2025-04-30',350000),
('Monsoon Offers','DISCOUNT','2025-07-01','2025-07-31',420000),
('Year End Rewards','LOYALTY','2025-12-01','2025-12-31',600000),
('New Customer Welcome','ACQUISITION','2025-01-01','2025-12-31',300000);

INSERT INTO customer_campaigns(customer_id,campaign_id,joined_at)
SELECT
    1+floor(random()*10000)::bigint,
    1+floor(random()*5)::bigint,
    TIMESTAMP '2025-01-01'+(floor(random()*365)::int || ' days')::interval
FROM generate_series(1,15000)
ON CONFLICT DO NOTHING;

INSERT INTO customer_events(customer_id,event_type,event_timestamp)
SELECT
    1+floor(random()*10000)::bigint,
    (ARRAY['LOGIN','PRODUCT_VIEW','ADD_TO_CART','PURCHASE','REVIEW','WISHLIST'])[1+floor(random()*6)::int],
    TIMESTAMP '2025-01-01'+(floor(random()*365)::int || ' days')::interval
FROM generate_series(1,75000);

ANALYZE;
