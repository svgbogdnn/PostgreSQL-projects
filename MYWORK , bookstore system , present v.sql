-- https://www.db-fiddle.com/f/8wgZZgbF5c2LdF66xFq8g6/5

/*
This PostgreSQL service models an online bookstore 
system, tracking books with authors, publishers, 
categories, ISBNs, suppliers and supplies, users, 
orders and order items, payments/transactions,
ratings, and analytic views for inventory and sales.
*/

CREATE SCHEMA IF NOT EXISTS bs;

CREATE TABLE IF NOT EXISTS bs.supplier (
    supplier_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    contact_name VARCHAR(255) DEFAULT NULL,
    contact_email VARCHAR(255) DEFAULT NULL,
    phone_number VARCHAR(50) NOT NULL,
    address TEXT DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS bs.author (
    author_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) DEFAULT NULL,
    last_name VARCHAR(100) DEFAULT NULL,
    birth_year INT NOT NULL DEFAULT 1900,
    death_year INT DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS bs.category (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    description TEXT DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS bs.publisher (
    publisher_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT DEFAULT NULL,
    contact_email VARCHAR(255) DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS bs.book (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    fk_author_id INT NOT NULL,
    fk_publisher_id INT NOT NULL,
    year_of_publication INT DEFAULT 1900,
    fk_category_id INT NOT NULL,
    fk_supplier_id INT NOT NULL,
    price DECIMAL(10, 2) DEFAULT 0.00 CHECK (price >= 0),
    available_quantity INT DEFAULT 0 CHECK (available_quantity >= 0),
    FOREIGN KEY (fk_author_id) REFERENCES bs.author(author_id),
    FOREIGN KEY (fk_publisher_id) REFERENCES bs.publisher(publisher_id),
    FOREIGN KEY (fk_category_id) REFERENCES bs.category(category_id),
    FOREIGN KEY (fk_supplier_id) REFERENCES bs.supplier(supplier_id)
);

CREATE TABLE IF NOT EXISTS bs.book_isbn (
    isbn_id SERIAL PRIMARY KEY,
    fk_book_id INT NOT NULL,
    isbn VARCHAR(20) NOT NULL,
    FOREIGN KEY (fk_book_id) REFERENCES bs.book(book_id)
);

CREATE TABLE IF NOT EXISTS bs.user (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(255) DEFAULT NULL,
    first_name VARCHAR(100) DEFAULT NULL,
    last_name VARCHAR(100) DEFAULT NULL,
    phone_number VARCHAR(50) DEFAULT NULL,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bs.order (
    order_id SERIAL PRIMARY KEY,
    fk_user_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'canceled')),
    total_amount DECIMAL(10, 2) DEFAULT 0.00 CHECK (total_amount >= 0),
    FOREIGN KEY (fk_user_id) REFERENCES bs.user(user_id)
);

CREATE TABLE IF NOT EXISTS bs.order_item (
    order_item_id SERIAL PRIMARY KEY,
    fk_order_id INT NOT NULL,
    fk_book_id INT NOT NULL,
    quantity INT DEFAULT 1 CHECK (quantity > 0),
    price DECIMAL(10, 2) DEFAULT 0.00 CHECK (price >= 0),
    FOREIGN KEY (fk_order_id) REFERENCES bs.order(order_id),
    FOREIGN KEY (fk_book_id) REFERENCES bs.book(book_id)
);

CREATE TABLE IF NOT EXISTS bs.book_rating (
    rating_id SERIAL PRIMARY KEY,
    fk_book_id INT NOT NULL,
    fk_user_id INT NOT NULL,
    rating INT DEFAULT 0 CHECK (rating >= 1 AND rating <= 5),
    review TEXT DEFAULT NULL,
    FOREIGN KEY (fk_book_id) REFERENCES bs.book(book_id),
    FOREIGN KEY (fk_user_id) REFERENCES bs.user(user_id)
);

CREATE TABLE IF NOT EXISTS bs.supply (
    supply_id SERIAL PRIMARY KEY,
    fk_supplier_id INT NOT NULL,
    fk_book_id INT NOT NULL,
    quantity INT DEFAULT 0 CHECK (quantity >= 0),
    supply_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (fk_supplier_id) REFERENCES bs.supplier(supplier_id),
    FOREIGN KEY (fk_book_id) REFERENCES bs.book(book_id)
);

CREATE TABLE IF NOT EXISTS bs.transaction (
    transaction_id SERIAL PRIMARY KEY,
    fk_user_id INT NOT NULL,
    fk_order_id INT NOT NULL,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount >= 0),
    payment_method VARCHAR(50) DEFAULT 'card' CHECK (payment_method IN ('card', 'QR', 'cash')),
    FOREIGN KEY (fk_user_id) REFERENCES bs.user(user_id),
    FOREIGN KEY (fk_order_id) REFERENCES bs.order(order_id)
);

INSERT INTO bs.supplier (name, contact_name, contact_email, phone_number, address) VALUES
('BookSupply Inc.', 'John Doe', 'contact@booksupply.com', '123-456-7890', '123 Book St, New York, NY'),
('Literature Distributors', 'Jane Smith', 'info@literaturedistributors.com', '234-567-8901', '456 Book Ave, Los Angeles, CA'),
('PageTurner Supplies', 'Alice Johnson', 'service@pageturner.com', '345-678-9012', '789 Reading Rd, Chicago, IL'),
('NovelCorp', 'Bob Brown', 'support@novelcorp.com', '456-789-0123', '101 Novel Ln, San Francisco, CA'),
('ReadMore Supplies', 'Tom White', 'contact@readmore.com', '567-890-1234', '202 Readmore Blvd, Austin, TX');

INSERT INTO bs.author (first_name, last_name, birth_year, death_year) VALUES
('George', 'Orwell', 1903, 1950),
('J.K.', 'Rowling', 1965, NULL),
('F. Scott', 'Fitzgerald', 1896, 1940),
('Agatha', 'Christie', 1890, 1976),
('J.R.R.', 'Tolkien', 1892, 1973);

INSERT INTO bs.category (category_name, description) VALUES
('Fiction', 'Novels and short stories based on imaginative events'),
('Non-Fiction', 'Books based on factual information'),
('Science Fiction', 'Fiction based on scientific concepts and futuristic ideas'),
('Biography', 'Books that tell the life stories of people'),
('Mystery', 'Books that involve solving a crime or mystery');

INSERT INTO bs.publisher (name, address, contact_email) VALUES
('Penguin Random House', '1745 Broadway, New York, NY', 'contact@penguinrandomhouse.com'),
('HarperCollins', '195 Broadway, New York, NY', 'support@harpercollins.com'),
('Simon & Schuster', '1230 Avenue of the Americas, New York, NY', 'info@simonandschuster.com'),
('Macmillan', '120 Broadway, New York, NY', 'contact@macmillan.com'),
('Hachette Book Group', '1290 Avenue of the Americas, New York, NY', 'info@hachettebookgroup.com');

INSERT INTO bs.book (title, fk_author_id, fk_publisher_id, year_of_publication, fk_category_id, fk_supplier_id, price, available_quantity) VALUES
('Test', 1, 1, 1949, 1, 1, 19.99, 10),
('Harry Potter and the Sorcerer\s Stone', 2, 2, 1997, 1, 2, 29.99, 5),
('The Great Gatsby', 3, 3, 1925, 1, 3, 14.99, 7),
('Murder on the Orient Express', 4, 4, 1934, 5, 4, 12.99, 8),
('The Hobbit', 5, 5, 1937, 3, 5, 24.99, 6);

INSERT INTO bs.book_isbn (fk_book_id, isbn) VALUES
(1, '978-0451524935'),
(2, '978-0439708180'),
(3, '978-0743273565'),
(4, '978-0062693662'),
(5, '978-0547928227');

INSERT INTO bs.user (username, password, email, first_name, last_name, phone_number) VALUES
('john_doe', 'password123', 'john.doe@example.com', 'John', 'Doe', '123-456-7890'),
('jane_smith', 'password123', 'jane.smith@example.com', 'Jane', 'Smith', '234-567-8901'),
('bob_brown', 'password123', 'bob.brown@example.com', 'Bob', 'Brown', '345-678-9012'),
('alice_johnson', 'password123', 'alice.johnson@example.com', 'Alice', 'Johnson', '456-789-0123'),
('tom_white', 'password123', 'tom.white@example.com', 'Tom', 'White', '567-890-1234');

INSERT INTO bs.order (fk_user_id, status, total_amount) VALUES
(1, 'pending', 49.98),
(2, 'completed', 29.99),
(3, 'canceled', 19.99),
(4, 'completed', 99.97),
(5, 'pending', 74.98);

INSERT INTO bs.order_item (fk_order_id, fk_book_id, quantity, price) VALUES
(1, 1, 2, 19.99),
(2, 2, 1, 29.99),
(3, 3, 1, 14.99),
(4, 4, 3, 12.99),
(5, 5, 2, 24.99);

INSERT INTO bs.book_rating (fk_book_id, fk_user_id, rating, review) VALUES
(1, 1, 5, 'A timeless classic, very thought-provoking'),
(2, 2, 4, 'An enchanting story for all ages'),
(3, 3, 4, 'Great read, but a bit slow-paced in the middle'),
(4, 4, 5, 'Masterpiece, as always with Agatha Christie'),
(5, 5, 5, 'A wonderful journey into Middle-earth');

INSERT INTO bs.supply (fk_supplier_id, fk_book_id, quantity) VALUES
(1, 1, 50),
(2, 2, 100),
(3, 3, 75),
(4, 4, 25),
(5, 5, 40);

INSERT INTO bs.transaction (fk_user_id, fk_order_id, amount, payment_method) VALUES
(1, 1, 49.98, 'QR'),
(2, 2, 29.99, 'card'),
(3, 3, 19.99, 'cash'),
(4, 4, 99.97, 'QR'),
(5, 5, 74.98, 'card');

CREATE VIEW v_book_author_info AS
SELECT b.book_id,
       b.title AS book_title,
       a.first_name || ' ' || a.last_name AS author_name,
       b.year_of_publication,
       b.price,
       b.available_quantity
FROM bs.book b
JOIN bs.author a ON b.fk_author_id = a.author_id;
SELECT * FROM v_book_author_info;


CREATE VIEW v_order_book_details AS
SELECT o.order_id,
       u.username AS user_name,
       b.title AS book_title,
       oi.quantity,
       oi.price,
       (oi.quantity * oi.price) AS total_price
FROM bs.order o
JOIN bs.order_item oi ON o.order_id = oi.fk_order_id
JOIN bs.book b ON oi.fk_book_id = b.book_id
JOIN bs.user u ON o.fk_user_id = u.user_id;
SELECT * FROM v_order_book_details;


CREATE VIEW v_book_ratings AS
SELECT b.book_id,
       b.title AS book_title,
       AVG(br.rating) AS average_rating,
       COUNT(br.rating) AS total_ratings,
       STRING_AGG(br.review, ' | ') AS reviews
FROM bs.book b
LEFT JOIN bs.book_rating br ON b.book_id = br.fk_book_id
GROUP BY b.book_id, b.title;
SELECT * FROM v_book_ratings;


CREATE VIEW v_book_supplier_info AS
SELECT b.book_id,
       b.title AS book_title,
       s.name AS supplier_name,
       SUM(sup.quantity) AS total_supplied,
       MAX(sup.supply_date) AS last_supply_date
FROM bs.book b
JOIN bs.supply sup ON b.book_id = sup.fk_book_id
JOIN bs.supplier s ON sup.fk_supplier_id = s.supplier_id
GROUP BY b.book_id, b.title, s.name;
SELECT * FROM v_book_supplier_info;


--Запрос для подсчёта общего количества заказанных книг
SELECT b.book_id,
       b.title AS book_title,
       SUM(oi.quantity) AS total_quantity_ordered
FROM bs.book b
JOIN bs.order_item oi ON b.book_id = oi.fk_book_id
GROUP BY b.book_id, b.title
HAVING SUM(oi.quantity) > 1
ORDER BY total_quantity_ordered DESC;

--Запрос для нахождения самого дорогого заказа
SELECT u.user_id,
       u.username,
       o.order_id,
       o.total_amount
FROM bs.order o
JOIN bs.user u ON o.fk_user_id = u.user_id
ORDER BY o.total_amount DESC
LIMIT 1;

--Запрос для нахождения последнего заказа пользователя 'jane_smith'
SELECT u.username,
       o.order_id,
       o.order_date,
       o.total_amount
FROM bs.order o
JOIN bs.user u ON o.fk_user_id = u.user_id
WHERE u.username = 'jane_smith'
ORDER BY o.order_date DESC
LIMIT 1;



CREATE VIEW v_category_order_info AS
SELECT c.category_name,
       b.title AS book_title,
       SUM(oi.quantity) AS total_quantity_ordered,
       SUM(oi.quantity * oi.price) AS total_sales
FROM bs.category c
JOIN bs.book b ON c.category_id = b.fk_category_id
JOIN bs.order_item oi ON b.book_id = oi.fk_book_id
GROUP BY c.category_name, b.title
ORDER BY total_sales DESC;
SELECT * FROM v_category_order_info;


--Количество книг, доступных для покупки по категориям
SELECT c.category_name,
       COUNT(b.book_id) AS total_books_in_category,
       SUM(b.available_quantity) AS total_available_books
FROM bs.category c
JOIN bs.book b ON c.category_id = b.fk_category_id
GROUP BY c.category_name
ORDER BY total_available_books DESC;
