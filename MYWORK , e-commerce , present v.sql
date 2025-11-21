-- https://www.db-fiddle.com/f/mC6SUufiptQvU47ag8CwtV/16

/*
This PostgreSQL-based service implements an e-commerce backend
that manages products, categories, suppliers, customers, orders
with items, payments, shipments, reviews, warehouse inventory,
sales reporting views, and automatic order change logging via triggers.
*/

BEGIN;

CREATE SCHEMA IF NOT EXISTS e_shop;

CREATE TABLE IF NOT EXISTS e_shop.category (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS e_shop.supplier (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    website TEXT NOT NULL,
    address TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS e_shop.product (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    price NUMERIC(10, 2) NOT NULL CHECK (price > 0),
    fk_supplier INT NOT NULL,
    fk_category INT NOT NULL,
    FOREIGN KEY (fk_supplier) REFERENCES e_shop.supplier(id) ON DELETE CASCADE,
    FOREIGN KEY (fk_category) REFERENCES e_shop.category(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS e_shop.customer (
    id SERIAL PRIMARY KEY,
    firstname TEXT NOT NULL,
    lastname TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    city TEXT NOT NULL,
    country TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS e_shop.order (
    id SERIAL PRIMARY KEY,
    fk_customer INT NOT NULL,
    orderDate DATE NOT NULL DEFAULT CURRENT_DATE,
    totalAmount NUMERIC(10, 2) NOT NULL CHECK (totalAmount >= 0),
    paymentStatus TEXT NOT NULL,
    shippingStatus TEXT NOT NULL,
    FOREIGN KEY (fk_customer) REFERENCES e_shop.customer(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS e_shop.order_item (
    fk_order INT NOT NULL,
    fk_product INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (fk_order, fk_product),
    FOREIGN KEY (fk_order) REFERENCES e_shop.order(id) ON DELETE CASCADE,
    FOREIGN KEY (fk_product) REFERENCES e_shop.product(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS e_shop.shipment (
    id SERIAL PRIMARY KEY,
    fk_order INT NOT NULL,
    courier TEXT NOT NULL,
    shippedDate DATE NOT NULL DEFAULT '3000-01-01',
    deliveredDate DATE NOT NULL DEFAULT '3000-01-01',
    FOREIGN KEY (fk_order) REFERENCES e_shop.order(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS e_shop.payment (
    id SERIAL PRIMARY KEY,
    fk_order INT NOT NULL,
    amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    paymentDate DATE NOT NULL DEFAULT CURRENT_DATE,
    paymentMethod TEXT NOT NULL,
    FOREIGN KEY (fk_order) REFERENCES e_shop.order(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS e_shop.review (
    id SERIAL PRIMARY KEY,
    fk_customer INT NOT NULL,
    fk_product INT NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT NOT NULL,
    reviewDate DATE NOT NULL DEFAULT CURRENT_DATE,
    FOREIGN KEY (fk_customer) REFERENCES e_shop.customer(id) ON DELETE CASCADE,
    FOREIGN KEY (fk_product) REFERENCES e_shop.product(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS e_shop.warehouse (
    fk_product INT PRIMARY KEY,
    quantity INT NOT NULL CHECK (quantity >= 0),
    location TEXT NOT NULL,
    FOREIGN KEY (fk_product) REFERENCES e_shop.product(id) ON DELETE CASCADE
);

CREATE INDEX idx_customer_email ON e_shop.customer(email);

CREATE INDEX idx_product_supplier ON e_shop.product(fk_supplier);
CREATE INDEX idx_product_category ON e_shop.product(fk_category);

CREATE INDEX idx_order_customer ON e_shop.order(fk_customer);

CREATE INDEX idx_order_item_order ON e_shop.order_item(fk_order);

CREATE INDEX idx_warehouse_product ON e_shop.warehouse(fk_product);

CREATE TABLE e_shop.order_logs (
    log_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    action_type TEXT NOT NULL,
    log_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    new_data JSONB NOT NULL
);

CREATE OR REPLACE FUNCTION log_order_changes()
RETURNS TRIGGER AS
$$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO e_shop.order_logs (order_id, action_type, new_data)
        VALUES (
            NEW.id,
            'INSERT',
            jsonb_build_object(
                'customer_id', NEW.fk_customer,
                'total_amount', NEW.totalAmount,
                'payment_status', NEW.paymentStatus,
                'shipping_status', NEW.shippingStatus,
                'order_date', NEW.orderDate
            )
        );
    
    ELSEIF TG_OP = 'UPDATE' THEN
        INSERT INTO e_shop.order_logs (order_id, action_type, new_data)
        VALUES (
            NEW.id,
            'UPDATE',
            jsonb_build_object(
                'customer_id', NEW.fk_customer,
                'total_amount', NEW.totalAmount,
                'payment_status', NEW.paymentStatus,
                'shipping_status', NEW.shippingStatus,
                'order_date', NEW.orderDate
            )
        );

    ELSEIF TG_OP = 'DELETE' THEN
        INSERT INTO e_shop.order_logs (order_id, action_type, new_data)
        VALUES (
            OLD.id,
            'DELETE',
            jsonb_build_object(
                'customer_id', OLD.fk_customer,
                'total_amount', OLD.totalAmount,
                'payment_status', OLD.paymentStatus,
                'shipping_status', OLD.shippingStatus,
                'order_date', OLD.orderDate
            )
        );
    END IF;

    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER after_order_insert
AFTER INSERT ON e_shop.order
FOR EACH ROW
EXECUTE FUNCTION log_order_changes();

CREATE OR REPLACE TRIGGER after_order_update
AFTER UPDATE ON e_shop.order
FOR EACH ROW
EXECUTE FUNCTION log_order_changes();

CREATE OR REPLACE TRIGGER after_order_delete
AFTER DELETE ON e_shop.order
FOR EACH ROW
EXECUTE FUNCTION log_order_changes();



-- ROLLBACK;
COMMIT;


BEGIN;

INSERT INTO e_shop.category (name)
VALUES
      ('Clothes'),
      ('Books'),
      ('Food'),
      ('Computers'),
      ('Phones'),
      ('Furniture'),
      ('Cars'),
      ('Medicines');
      
INSERT INTO e_shop.supplier (name, website, address)
VALUES ('Huawei', 'huawei.com', 'China: Shenchzhen'),
	   ('Ozon', 'ozon.ru', 'Russia: Moscow'),
       ('Auchan', 'auchan.ru', 'France: Krua'),
       ('Mercedes-Benz', 'mercedes-benz.de', 'Germany: Shtutgart'),
       ('Stolichki', 'stolichki.ru', 'Russia: Moscow'),
       ('Stroygigant', 'stroygigant.ru', 'Russia: Kursk'),
       ('Chitai-Gorod', 'chitai-gorod.ru', 'Russia: Moscow');

INSERT INTO e_shop.product (name, description, price, fk_supplier, fk_category)
VALUES
    ('Huawei P50', 'High-performance smartphone with OLED display', 699.99, 1, 5),
    ('MacBook Pro', 'Apple laptop with M1 chip', 1299.99, 2, 4),
    ('War and Peace', 'Classic novel by Leo Tolstoy', 19.99, 7, 2),
    ('Fresh Apples', 'Organic apples, fresh from the farm', 3.49, 3, 3),
    ('Office Desk', 'Modern wooden office desk', 149.99, 6, 6),
    ('Mercedes S63 AMG', 'Luxury sedan with advanced features', 49999.00, 4, 7),
    ('Ibuprofen Tablets', 'Pain relief tablets, 200mg', 4.99, 5, 8),
    ('Screwdriver Set', 'Professional set of screwdrivers', 15.99, 6, 6);

INSERT INTO e_shop.customer (firstname, lastname, email, city, country)
VALUES
    ('Bogdan', 'Butakov', 'bogdan.butakov@gmail.com', 'Kursk', 'Russia'),
    ('Anna', 'Petrova', 'annaPEEetrova@yandex.ru', 'Saint Petersburg', 'Russia'),
    ('John', 'Doe', 'john.doe@example.com', 'New York', 'USA'),
    ('Eugene', 'Aristov', 'aristov-tech@mail.ru', 'Moscow', 'Russia'),
    ('Satoshi', 'Nakamoto', 'kuakduiikakdauidwdq@qwjkjk.com', 'Tokyo', 'Japan'),
    ('Alexander', 'Bykov', 'alexandryanka-200414@yandex.ru', 'Vladimir', 'Russia');
    
INSERT INTO e_shop.order (fk_customer, orderDate, totalAmount, paymentStatus, shippingStatus)
VALUES
    (1, '2024-10-15', 50002.49, 'Paid', 'Shipped'),  -- Bogdan Butakov - S63 and fresh apples
    (2, '2024-05-02', 19.99, 'Paid', 'Delivered'), -- Anna Petrova - War and Peace
    (3, '2024-10-03', 1299.99, 'Pending', 'Pending'), -- John Doe - MacBook Pro
    (4, '2024-08-08', 865.97, 'Pending', 'Pending'), -- Eugene Aristov - Office desk, Screwdriver Set and Huawei P50
    (5, '2024-10-05', 14.97, 'Paid', 'Shipped'),     -- Satoshi Nakamoto - Ibuprofen Tablets x3
    (6, '2024-10-06', 149.99, 'Paid', 'Shipped');    -- Alexander Bykov -Office Desk
    
INSERT INTO e_shop.order_item (fk_order, fk_product, quantity)
VALUES
    (1, 6, 1),  -- Bogdan Butakov 1 S63 AMG 
    (1, 4, 1), -- Bogdan Butakov 1 Fresh Apples
    (2, 3, 1),  -- Anna Petrova 1 War and Peace
    (3, 2, 1),  -- John Doe 1 MacBook Pro
    (4, 5, 1),  -- Eugene Aristov 1 Office Desk
    (4, 7, 1),  -- Eugene Aristov 1 Screwdriver Set
    (4, 1, 1),  -- Eugene Aristov 1 Huawei P50
    (5, 7, 3),  -- Satoshi Nakamoto 3 Ibuprofen Tablets
    (6, 5, 1);  -- Alexander Bykov 1 Office Desk
    
INSERT INTO e_shop.shipment (fk_order, courier, shippedDate, deliveredDate)
VALUES
    (1, 'DHL', '2023-11-01', '2023-11-02'),  -- Bogdan
    (2, 'TNT', '2024-05-03', '2024-05-04'), -- Anna
    (3, 'UPS', '3000-01-01', '3000-01-01'),                   -- John Doe not shipped yet
    (4, 'FedEx', '3000-01-01', '3000-01-01'),                   -- Eugene not shipped yet
    (5, 'DHL', '2024-10-06', '2024-10-07'),   -- Satoshi's shipment
    (6, 'UltramegasuperBek Aqwdpoasdvich', '2024-10-06', '2024-10-07'); -- Alexander s
    
INSERT INTO e_shop.payment (fk_order, Amount, paymentDate, paymentMethod)
VALUES
    (1, 50002.49, '2023-10-31', 'Debet Card'), -- Bogdan
    (2, 19.99, '2024-05-02', 'SBP'),         -- Anna
    (5, 14.97, '2024-10-05', 'Bank Transfer'),  --  Satoshi
    (6, 149.99, '2024-10-06', 'Debet Card');   -- Alexander
    
INSERT INTO e_shop.review (fk_customer, fk_product, rating, comment, reviewDate)
VALUES
    (1, 6, 5, 'Incredible car! Worth every ruble!', '2024-11-01'),  -- Bogdan - Sedan E-Class
    (2, 3, 3, 'A classic, but shipping was delayed.', '2024-05-05'), -- Anna - War and Peace
    (3, 2, 1, 'Xiaomi is better!!!', '2024-10-04'),  -- John - MacBook Pro
    (4, 5, 4, 'Great desk, very solid!', '2024-08-09'),  -- Eugene - Office Desk
    (5, 7, 4, 'Good pain relief, but shipping was slow.', '2024-10-08'),  --  Satoshi - Ibuprofen Tablets
    (6, 5, 5, 'Excellent desk, highly recommend!', '2024-10-11'); -- Alexander - Office Desk
    
INSERT INTO e_shop.warehouse (fk_product, quantity, location)
VALUES
    (1, 50, 'Warehouse A'),  -- Huawei P50
    (2, 25, 'Warehouse A'),  -- MacBook Pro
    (3, 200, 'Warehouse C'), -- War and Peace
    (4, 500, 'Warehouse C'), -- Fresh Apples
    (5, 30, 'Warehouse B'),  -- Office Desk
    (6, 10, 'Warehouse D'),   -- Mercedes S63 AMG
    (7, 300, 'Warehouse C'),  -- Ibuprofen Tablets
    (8, 100, 'Warehouse B');   -- Screwdriver Set
    
COMMIT;


BEGIN;

-- генерируем 10 покупателей с 5 заказами у каждого (распределяем по случайным складам, цены и прочие показатели случайны)
DO
$$
DECLARE
    i INT;
    customer_id INT;
    supplier_id INT;
    product_id INT;
    order_id INT;
    total_amount NUMERIC(10, 2);
    quantity INT;
BEGIN
    FOR i IN 1..10 LOOP
        INSERT INTO e_shop.customer (firstname, lastname, email, city, country)
        VALUES ('Firstname'||i, 'Lastname'||i, 'customer'||i||'@gmail.com', 'City'||i, 'Country'||i)
        RETURNING id INTO customer_id;

        FOR j IN 1..5 LOOP
            INSERT INTO e_shop.supplier (name, website, address)
            VALUES ('Supplier'||(i+j), 'supplier'||(i+j)||'.com', 'Address'||(i+j)||' City'||(i+j)||', Country'||(i+j))
            RETURNING id INTO supplier_id;

            INSERT INTO e_shop.category (name)
            VALUES ('Category'||(i+j));

            INSERT INTO e_shop.product (name, description, price, fk_supplier, fk_category)
            VALUES ('Product'||(i+j), 'Description '||(i+j), (RANDOM() * 1000)::NUMERIC(10, 2), supplier_id, (i % 8) + 1)
            RETURNING id INTO product_id;

            INSERT INTO e_shop.warehouse (fk_product, quantity, location)
            VALUES (product_id, (RANDOM() * 100)::INT, 'Warehouse ' || chr(65 + (i % 4)));

            quantity := (RANDOM() * 5 + 1)::INT;
            total_amount := quantity * (RANDOM() * 100)::NUMERIC(10, 2);

            INSERT INTO e_shop.order (fk_customer, orderDate, totalAmount, paymentStatus, shippingStatus)
            VALUES (customer_id, CURRENT_DATE - (i % 365), total_amount, 'Paid', 'Shipped')
            RETURNING id INTO order_id;

            INSERT INTO e_shop.order_item (fk_order, fk_product, quantity)
            VALUES (order_id, product_id, quantity);

            INSERT INTO e_shop.shipment (fk_order, courier, shippedDate, deliveredDate)
            VALUES (order_id, 'Courier'||i, CURRENT_DATE - (i % 10), CURRENT_DATE - (i % 5));

            INSERT INTO e_shop.payment (fk_order, amount, paymentDate, paymentMethod)
            VALUES (order_id, total_amount, CURRENT_DATE - (i % 30), 'Credit Card');
        END LOOP;
    END LOOP;
END;
$$;



-- 6.1 - суммарные продажи для каждого из поставщиков
SELECT s.name AS supplier_name,
       SUM(oi.quantity * p.price) AS total_sales
FROM e_shop.order_item oi
JOIN e_shop.product p ON oi.fk_product = p.id
JOIN e_shop.supplier s ON p.fk_supplier = s.id
JOIN e_shop.order o ON oi.fk_order = o.id
WHERE o.paymentStatus = 'Paid'
GROUP BY s.name
ORDER BY total_sales DESC;

-- SELECT * FROM e_shop.order;

-- 6.2 - просмотр всех заказов каждого покупателя с выводом общей суммы, статус платежа и всех данных заказа
SELECT 
    CONCAT(c.firstname, ' ', c.lastname) AS customer_name,
    COUNT(DISTINCT o.id) AS total_orders,
    SUM(oi.quantity * p.price) AS total_spent,
    CASE 
        WHEN MIN(o.paymentStatus) = 'Paid' 
        THEN 'All Paid' 
        ELSE 'Pending Payments' 
    END AS payment_status,
    STRING_AGG(DISTINCT p.name || ' (Supplier: ' || s.name || ')', ', ') AS purchased_items
FROM e_shop.customer c
JOIN e_shop.order o ON c.id = o.fk_customer
JOIN e_shop.order_item oi ON o.id = oi.fk_order
JOIN e_shop.product p ON oi.fk_product = p.id
JOIN e_shop.supplier s ON p.fk_supplier = s.id
GROUP BY c.id
ORDER BY total_spent DESC;

-- 7.1 - создали view из-за необходимости во многих местах просматривать все данные о продажах за месяц с информацией о компании 
CREATE OR REPLACE VIEW e_shop.monthly_company_sales AS
SELECT 
    o.id AS order_id,
    o.orderDate AS order_date,
    SUM(oi.quantity * p.price) AS total_revenue,
    s.name AS supplier_name,
    s.website AS supplier_website,
    s.address AS supplier_address
FROM 
    e_shop.order o
JOIN 
    e_shop.order_item oi ON o.id = oi.fk_order
JOIN 
    e_shop.product p ON oi.fk_product = p.id
JOIN 
    e_shop.supplier s ON p.fk_supplier = s.id
WHERE 
    o.paymentStatus = 'Paid'
    AND o.orderDate >= (CURRENT_DATE - INTERVAL '1 month')
GROUP BY 
    o.id, o.orderDate, s.name, s.website, s.address
ORDER BY order_date, total_revenue;

SELECT * FROM e_shop.monthly_company_sales;

-- 7.2 - материализованное представление со всеми данными, необходимыми для клиента - всё о заказе: название, цена, кол-во, местонахождение, поставщик, даты отправки и доставки - для быстрого доступа без необходимости заново производить сложный запрос с множественными объединениями
CREATE MATERIALIZED VIEW e_shop.product_inventory AS
SELECT 
    p.id AS product_id,
    p.name AS product_name,
    p.description AS product_description,
    p.price AS product_price,
    w.quantity AS stock_quantity,
    w.location AS warehouse_location,
    s.name AS supplier_name,
    s.website AS supplier_website,
    o.id AS order_id,
    o.orderDate AS order_date,
    sh.shippedDate AS shipped_date,
    sh.deliveredDate AS delivered_date
FROM 
    e_shop.product p
LEFT JOIN 
    e_shop.warehouse w ON p.id = w.fk_product
JOIN 
    e_shop.supplier s ON p.fk_supplier = s.id
LEFT JOIN 
    e_shop.order_item oi ON p.id = oi.fk_product
LEFT JOIN 
    e_shop.order o ON oi.fk_order = o.id
LEFT JOIN 
    e_shop.shipment sh ON o.id = sh.fk_order
GROUP BY 
    p.id, w.quantity, w.location, s.name, s.website, o.id, o.orderDate, sh.shippedDate, sh.deliveredDate;

    
SELECT * FROM e_shop.product_inventory;

UPDATE e_shop.order
SET shippingStatus = 'Shipped'
WHERE id = 7;

DELETE FROM e_shop.order
WHERE id = 5;

SELECT * FROM e_shop.order_logs;


-- ROLLBACK;
COMMIT;
