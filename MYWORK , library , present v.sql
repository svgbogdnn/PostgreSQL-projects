 -- https://www.db-fiddle.com/f/baszpbs9YtX4MeQeBNU4Hk/0

/*
This service implements a full library management database
that catalogs books, authors, publishers, and categories, 
tracks readers, staff, loans/returns with fines and history,
reservations and reviews, and provides reporting views for 
popularity, overdue items, and overall library statistics.
*/

-- ================================================
-- СОЗДАНИЕ ТАБЛИЦ
-- ================================================

DROP TABLE IF EXISTS loan_history CASCADE;
DROP TABLE IF EXISTS loans CASCADE;
DROP TABLE IF EXISTS reservations CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS book_authors CASCADE;
DROP TABLE IF EXISTS books CASCADE;
DROP TABLE IF EXISTS authors CASCADE;
DROP TABLE IF EXISTS publishers CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS readers CASCADE;
DROP TABLE IF EXISTS library_staff CASCADE;

-- Издатели
CREATE TABLE publishers (
    publisher_id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    country VARCHAR(100)
);

-- Категории
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

-- Авторы
CREATE TABLE authors (
    author_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    country VARCHAR(100)
);

-- Книги
CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    isbn VARCHAR(20) UNIQUE,
    title VARCHAR(300) NOT NULL,
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    category_id INTEGER NOT NULL REFERENCES categories(category_id),
    publication_year INTEGER,
    total_copies INTEGER NOT NULL DEFAULT 1,
    available_copies INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT chk_copies CHECK (available_copies >= 0 AND available_copies <= total_copies)
);

-- Связь книг и авторов
CREATE TABLE book_authors (
    book_id INTEGER NOT NULL REFERENCES books(book_id) ON DELETE CASCADE,
    author_id INTEGER NOT NULL REFERENCES authors(author_id) ON DELETE CASCADE,
    PRIMARY KEY (book_id, author_id)
);

-- Читатели
CREATE TABLE readers (
    reader_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    registration_date DATE DEFAULT CURRENT_DATE,
    is_active BOOLEAN DEFAULT TRUE
);

-- Сотрудники
CREATE TABLE library_staff (
    staff_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    position VARCHAR(100) NOT NULL
);

-- Выдачи
CREATE TABLE loans (
    loan_id SERIAL PRIMARY KEY,
    book_id INTEGER NOT NULL REFERENCES books(book_id),
    reader_id INTEGER NOT NULL REFERENCES readers(reader_id),
    staff_id INTEGER REFERENCES library_staff(staff_id),
    loan_date DATE DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    return_date DATE,
    fine_amount DECIMAL(8, 2) DEFAULT 0.00,
    status VARCHAR(20) DEFAULT 'active',
    CONSTRAINT chk_status CHECK (status IN ('active', 'returned', 'overdue'))
);

-- Резервирования
CREATE TABLE reservations (
    reservation_id SERIAL PRIMARY KEY,
    book_id INTEGER NOT NULL REFERENCES books(book_id),
    reader_id INTEGER NOT NULL REFERENCES readers(reader_id),
    reservation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending'
);

-- Отзывы
CREATE TABLE reviews (
    review_id SERIAL PRIMARY KEY,
    book_id INTEGER NOT NULL REFERENCES books(book_id),
    reader_id INTEGER NOT NULL REFERENCES readers(reader_id),
    rating INTEGER NOT NULL,
    review_text TEXT,
    CONSTRAINT chk_rating CHECK (rating >= 1 AND rating <= 5)
);

-- История выдач
CREATE TABLE loan_history (
    history_id SERIAL PRIMARY KEY,
    loan_id INTEGER NOT NULL REFERENCES loans(loan_id),
    book_id INTEGER NOT NULL,
    reader_id INTEGER NOT NULL,
    loan_date DATE NOT NULL,
    return_date DATE
);

-- ================================================
-- ВСТАВКА ДАННЫХ
-- ================================================

-- Издатели
INSERT INTO publishers (name, country) VALUES
('АСТ', 'Россия'),
('Эксмо', 'Россия'),
('Азбука', 'Россия'),
('Penguin Random House', 'США'),
('Macmillan Publishers', 'Великобритания'),
('Росмэн', 'Россия'),
('Просвещение', 'Россия'),
('Clever', 'Россия'),
('HarperCollins', 'США'),
('Simon & Schuster', 'США');

-- Категории
INSERT INTO categories (name) VALUES
('Художественная литература'),
('Научная литература'),
('Детская литература'),
('Классическая литература'),
('Фантастика'),
('Детективы'),
('Биография'),
('Поэзия'),
('История'),
('Философия');

-- Авторы
INSERT INTO authors (first_name, last_name, country) VALUES
('Лев', 'Толстой', 'Россия'),
('Фёдор', 'Достоевский', 'Россия'),
('Александр', 'Пушкин', 'Россия'),
('Михаил', 'Булгаков', 'Россия'),
('Джордж', 'Оруэлл', 'Великобритания'),
('Рэй', 'Брэдбери', 'США'),
('Стивен', 'Кинг', 'США'),
('Агата', 'Кристи', 'Великобритания'),
('Иван', 'Тургенев', 'Россия'),
('Николай', 'Гоголь', 'Россия'),
('Эрнест', 'Хемингуэй', 'США'),
('Франц', 'Кафка', 'Чехия'),
('Джейн', 'Остин', 'Великобритания'),
('Джордж Р.Р.', 'Мартин', 'США'),
('Джоан', 'Роулинг', 'Великобритания');

-- Книги
INSERT INTO books (isbn, title, publisher_id, category_id, publication_year, total_copies, available_copies) VALUES
('978-5-17-098765-4', 'Война и мир', 1, 4, 2018, 5, 3),
('978-5-699-12345-6', 'Преступление и наказание', 2, 4, 2019, 4, 2),
('978-5-389-09876-5', 'Евгений Онегин', 3, 4, 2020, 3, 1),
('978-5-00057-123-4', 'Мастер и Маргарита', 1, 4, 2017, 6, 4),
('978-0-452-28423-4', '1984', 4, 5, 2019, 4, 1),
('978-1-451-67396-2', '451 градус по Фаренгейту', 4, 5, 2018, 3, 2),
('978-1-501-17521-4', 'Оно', 4, 6, 2017, 4, 2),
('978-0-062-07348-9', 'Убийство в Восточном экспрессе', 5, 6, 2015, 5, 4),
('978-5-17-111111-1', 'Отцы и дети', 1, 4, 2020, 4, 4),
('978-5-699-22222-2', 'Мёртвые души', 2, 4, 2019, 3, 3),
('978-0-684-80122-3', 'Старик и море', 4, 4, 2018, 5, 5),
('978-0-8052-1082-7', 'Процесс', 5, 4, 2017, 3, 3),
('978-0-14-143951-8', 'Гордость и предубеждение', 4, 4, 2019, 4, 3),
('978-0-553-80370-6', 'Игра престолов', 5, 5, 2020, 6, 2),
('978-0-439-70818-8', 'Гарри Поттер и философский камень', 9, 3, 2018, 8, 5);

-- Связь книг и авторов
INSERT INTO book_authors (book_id, author_id) VALUES
(1, 1), (2, 2), (3, 3), (4, 4),
(5, 5), (6, 6), (7, 7), (8, 8),
(9, 9), (10, 10), (11, 11), (12, 12),
(13, 13), (14, 14), (15, 15);

-- Читатели
INSERT INTO readers (first_name, last_name, email, registration_date) VALUES
('Иван', 'Петров', 'ivan.petrov@email.ru', '2023-01-15'),
('Мария', 'Сидорова', 'maria.sidorova@email.ru', '2023-03-20'),
('Алексей', 'Иванов', 'alexey.ivanov@email.ru', '2023-05-10'),
('Елена', 'Смирнова', 'elena.smirnova@email.ru', '2023-07-05'),
('Дмитрий', 'Козлов', 'dmitry.kozlov@email.ru', '2023-09-12'),
('Ольга', 'Новикова', 'olga.novikova@email.ru', '2024-01-20'),
('Сергей', 'Морозов', 'sergey.morozov@email.ru', '2024-03-15'),
('Анна', 'Волкова', 'anna.volkova@email.ru', '2024-05-01'),
('Виктория', 'Павлова', 'victoria.pavlova@email.ru', '2024-06-10'),
('Максим', 'Федоров', 'maxim.fedorov@email.ru', '2024-07-15');

-- Сотрудники
INSERT INTO library_staff (first_name, last_name, position) VALUES
('Татьяна', 'Библиотекарова', 'Главный библиотекарь'),
('Николай', 'Книжников', 'Библиотекарь'),
('Светлана', 'Читалкина', 'Библиотекарь'),
('Петр', 'Страницын', 'Библиотекарь'),
('Людмила', 'Томова', 'Старший библиотекарь');

-- Выдачи
INSERT INTO loans (book_id, reader_id, staff_id, loan_date, due_date, return_date, fine_amount, status) VALUES
(1, 1, 1, '2024-10-01', '2024-10-15', '2024-10-14', 0.00, 'returned'),
(2, 2, 2, '2024-10-05', '2024-10-19', '2024-10-22', 30.00, 'returned'),
(3, 3, 1, '2024-10-10', '2024-10-24', NULL, 0.00, 'overdue'),
(4, 4, 3, '2024-10-15', '2024-10-29', '2024-10-28', 0.00, 'returned'),
(5, 5, 2, '2024-10-20', '2024-11-03', NULL, 0.00, 'active'),
(7, 1, 1, '2024-11-05', '2024-11-19', NULL, 0.00, 'active'),
(9, 6, 4, '2024-09-01', '2024-09-15', '2024-09-14', 0.00, 'returned'),
(10, 7, 5, '2024-09-10', '2024-09-24', '2024-09-25', 10.00, 'returned'),
(11, 8, 1, '2024-10-01', '2024-10-15', '2024-10-14', 0.00, 'returned'),
(12, 9, 2, '2024-10-10', '2024-10-24', NULL, 0.00, 'active'),
(13, 10, 3, '2024-10-20', '2024-11-03', '2024-11-02', 0.00, 'returned'),
(14, 6, 4, '2024-11-01', '2024-11-15', NULL, 0.00, 'active');

-- Резервирования
INSERT INTO reservations (book_id, reader_id, status) VALUES
(1, 3, 'pending'),
(5, 2, 'pending'),
(14, 1, 'pending'),
(13, 5, 'pending'),
(3, 7, 'pending');

-- Отзывы
INSERT INTO reviews (book_id, reader_id, rating, review_text) VALUES
(1, 1, 5, 'Великолепный роман! Обязательно к прочтению.'),
(2, 2, 5, 'Очень глубокое произведение, заставляет задуматься.'),
(4, 4, 5, 'Шедевр! Мистика и философия переплетены мастерски.'),
(7, 1, 4, 'Страшно, но очень интересно. Кинг как всегда на высоте.'),
(9, 6, 5, 'Прекрасный роман о конфликте поколений.'),
(10, 7, 4, 'Интересное произведение Гоголя.'),
(11, 8, 5, 'Хемингуэй умеет писать просто о сложном.'),
(13, 10, 5, 'Остин - королева романтики!'),
(15, 6, 5, 'Гарри Поттер - это классика!'),
(14, 9, 4, 'Игра престолов затягивает с первых страниц.');

-- История выдач
INSERT INTO loan_history (loan_id, book_id, reader_id, loan_date, return_date) VALUES
(1, 1, 1, '2024-10-01', '2024-10-14'),
(2, 2, 2, '2024-10-05', '2024-10-22'),
(4, 4, 4, '2024-10-15', '2024-10-28'),
(7, 9, 6, '2024-09-01', '2024-09-14'),
(8, 10, 7, '2024-09-10', '2024-09-25'),
(9, 11, 8, '2024-10-01', '2024-10-14'),
(11, 13, 10, '2024-10-20', '2024-11-02');

-- ================================================
-- СОЗДАНИЕ ИНДЕКСОВ
-- ================================================

CREATE INDEX idx_books_title ON books(title);
CREATE INDEX idx_authors_name ON authors(last_name, first_name);
CREATE INDEX idx_loans_status ON loans(status);

-- Популярные книги (представление)
CREATE VIEW v_popular_books AS
SELECT 
    b.book_id,
    b.title,
    STRING_AGG(a.first_name || ' ' || a.last_name, ', ') AS authors,
    p.name AS publisher,
    c.name AS category,
    COUNT(DISTINCT l.loan_id) AS times_borrowed,
    ROUND(AVG(rev.rating)::numeric, 2) AS average_rating,
    b.available_copies
FROM books b
LEFT JOIN book_authors ba ON b.book_id = ba.book_id
LEFT JOIN authors a ON ba.author_id = a.author_id
LEFT JOIN publishers p ON b.publisher_id = p.publisher_id
LEFT JOIN categories c ON b.category_id = c.category_id
LEFT JOIN loans l ON b.book_id = l.book_id
LEFT JOIN reviews rev ON b.book_id = rev.book_id
GROUP BY b.book_id, b.title, p.name, c.name, b.available_copies;


-- ЗАПРОС 1: Проверка установки
-- ================================================
SELECT 'База данных создана!' AS message,
       (SELECT COUNT(*) FROM books) AS books,
       (SELECT COUNT(*) FROM readers) AS readers,
       (SELECT COUNT(*) FROM loans) AS loans;


-- ЗАПРОС 2: Все книги с авторами
-- ================================================
SELECT 
    b.title AS "Название книги",
    STRING_AGG(a.first_name || ' ' || a.last_name, ', ') AS "Авторы",
    p.name AS "Издатель",
    c.name AS "Категория",
    b.available_copies || '/' || b.total_copies AS "Доступно/Всего"
FROM books b
JOIN book_authors ba ON b.book_id = ba.book_id
JOIN authors a ON ba.author_id = a.author_id
JOIN publishers p ON b.publisher_id = p.publisher_id
JOIN categories c ON b.category_id = c.category_id
GROUP BY b.book_id, b.title, p.name, c.name, b.available_copies, b.total_copies
ORDER BY b.title;


-- ЗАПРОС 3: Финансовый отчет
-- ================================================
SELECT 
    r.first_name || ' ' || r.last_name AS "Читатель",
    COUNT(DISTINCT l.loan_id) AS "Просроченных выдач",
    SUM(l.fine_amount) AS "Общая сумма штрафов",
    ROUND(AVG(l.fine_amount)::numeric, 2) AS "Средний штраф"
FROM readers r
LEFT JOIN loans l ON r.reader_id = l.reader_id
WHERE l.fine_amount > 0
GROUP BY r.reader_id, r.first_name, r.last_name
HAVING SUM(l.fine_amount) > 0
ORDER BY SUM(l.fine_amount) DESC;


-- ЗАПРОС 4: Статистика по издателям
-- ================================================
SELECT 
    p.name AS "Издатель",
    p.country AS "Страна",
    COUNT(DISTINCT b.book_id) AS "Книг в библиотеке",
    COUNT(DISTINCT l.loan_id) AS "Всего выдач",
    ROUND(AVG(rev.rating)::numeric, 2) AS "Средняя оценка",
    ROUND(100.0 * SUM(b.available_copies) / NULLIF(SUM(b.total_copies), 0), 2) AS "% доступности"
FROM publishers p
LEFT JOIN books b ON p.publisher_id = b.publisher_id
LEFT JOIN loans l ON b.book_id = l.book_id
LEFT JOIN reviews rev ON b.book_id = rev.book_id
GROUP BY p.publisher_id, p.name, p.country
HAVING COUNT(DISTINCT b.book_id) > 0
ORDER BY COUNT(DISTINCT l.loan_id) DESC;


-- ЗАПРОС 5: Топ популярных книг
-- ================================================
SELECT * FROM v_popular_books
ORDER BY times_borrowed DESC, average_rating DESC
LIMIT 5;


-- ЗАПРОС 6: Активность читателей по категориям
-- ================================================
SELECT 
    r.first_name || ' ' || r.last_name AS "Читатель",
    c.name AS "Категория",
    COUNT(DISTINCT l.loan_id) AS "Взял книг",
    COUNT(DISTINCT CASE WHEN l.status = 'returned' THEN l.loan_id END) AS "Вернул",
    COUNT(DISTINCT CASE WHEN l.status = 'overdue' THEN l.loan_id END) AS "Просрочил"
FROM readers r
JOIN loans l ON r.reader_id = l.reader_id
JOIN books b ON l.book_id = b.book_id
JOIN categories c ON b.category_id = c.category_id
GROUP BY r.reader_id, r.first_name, r.last_name, c.category_id, c.name
ORDER BY r.first_name, COUNT(DISTINCT l.loan_id) DESC;


-- ЗАПРОС 7: Просроченные книги с деталями
-- ================================================
SELECT 
    l.loan_id AS "ID выдачи",
    b.title AS "Книга",
    r.first_name || ' ' || r.last_name AS "Читатель",
    r.email AS "Email",
    l.loan_date AS "Дата выдачи",
    l.due_date AS "Срок возврата",
    CURRENT_DATE - l.due_date AS "Дней просрочки",
    CASE 
        WHEN CURRENT_DATE - l.due_date > 30 THEN 'Критическая'
        WHEN CURRENT_DATE - l.due_date > 14 THEN 'Серьезная'
        ELSE 'Небольшая'
    END AS "Уровень"
FROM loans l
JOIN books b ON l.book_id = b.book_id
JOIN readers r ON l.reader_id = r.reader_id
WHERE l.return_date IS NULL  -- Только НЕвозвращенные
    AND l.due_date < CURRENT_DATE  -- Срок истек
ORDER BY CURRENT_DATE - l.due_date DESC;


-- ЗАПРОС 8: Читатели без долгов (активные)
-- ================================================
SELECT 
    r.first_name || ' ' || r.last_name AS "Читатель",
    r.email AS "Email",
    COUNT(l.loan_id) AS "Всего взял книг",
    COUNT(CASE WHEN l.status = 'returned' THEN 1 END) AS "Вернул",
    COUNT(CASE WHEN l.status = 'active' THEN 1 END) AS "Сейчас на руках"
FROM readers r
LEFT JOIN loans l ON r.reader_id = l.reader_id
WHERE r.is_active = TRUE
GROUP BY r.reader_id, r.first_name, r.last_name, r.email
ORDER BY COUNT(l.loan_id) DESC;


-- ЗАПРОС 9: Книги которые никогда не брали
-- ================================================
SELECT 
    b.title AS "Название",
    STRING_AGG(a.first_name || ' ' || a.last_name, ', ') AS "Авторы",
    p.name AS "Издатель",
    b.publication_year AS "Год",
    b.total_copies AS "Экземпляров"
FROM books b
LEFT JOIN book_authors ba ON b.book_id = ba.book_id
LEFT JOIN authors a ON ba.author_id = a.author_id
LEFT JOIN publishers p ON b.publisher_id = p.publisher_id
LEFT JOIN loans l ON b.book_id = l.book_id
WHERE l.loan_id IS NULL
GROUP BY b.book_id, b.title, p.name, b.publication_year, b.total_copies
ORDER BY b.publication_year DESC;


-- ЗАПРОС 10: Общая статистика библиотеки
-- ================================================
SELECT 
    'Общая статистика' AS "Отчет",
    (SELECT COUNT(*) FROM books) AS "Всего книг",
    (SELECT SUM(total_copies) FROM books) AS "Всего экземпляров",
    (SELECT SUM(available_copies) FROM books) AS "Доступно",
    (SELECT COUNT(*) FROM readers WHERE is_active = TRUE) AS "Активных читателей",
    (SELECT COUNT(*) FROM loans WHERE return_date IS NULL) AS "Книг на руках",
    (SELECT COUNT(*) FROM loans WHERE return_date IS NULL AND due_date < CURRENT_DATE) AS "Просроченных (не возвращено)",
    (SELECT COALESCE(SUM(fine_amount), 0) FROM loans) AS "Штрафов собрано";


-- ЗАПРОС 11: Возвращенные книги с штрафами
-- ================================================
SELECT 
    l.loan_id AS "ID выдачи",
    b.title AS "Книга",
    r.first_name || ' ' || r.last_name AS "Читатель",
    l.loan_date AS "Дата выдачи",
    l.due_date AS "Срок возврата",
    l.return_date AS "Дата возврата",
    l.return_date - l.due_date AS "Дней просрочки",
    l.fine_amount AS "Штраф (руб)"
FROM loans l
JOIN books b ON l.book_id = b.book_id
JOIN readers r ON l.reader_id = r.reader_id
WHERE l.return_date IS NOT NULL  -- Возвращены
    AND l.fine_amount > 0  -- Есть штраф
ORDER BY l.fine_amount DESC;


-- ЗАПРОС 12: Информация о доступности и местонахождении копий книг
SELECT 
    b.title AS "Книга",
    b.available_copies AS "Доступно",
    (
        SELECT COUNT(*) 
        FROM loans l 
        WHERE l.book_id = b.book_id AND l.return_date IS NULL
    ) AS "На руках сейчас",
    (
        SELECT COUNT(*) 
        FROM reservations res 
        WHERE res.book_id = b.book_id AND res.status = 'pending'
    ) AS "В резерве",
    (
        SELECT COUNT(*) 
        FROM loans l 
        WHERE l.book_id = b.book_id 
            AND l.return_date IS NULL 
            AND l.due_date < CURRENT_DATE
    ) AS "Просрочено",
    CASE 
        WHEN b.available_copies = 0 THEN '<< Недоступна'
        WHEN b.available_copies < b.total_copies * 0.5 THEN '< Мало'
        ELSE '>> Доступна'
    END AS "Статус"
FROM books b
ORDER BY b.available_copies ASC;
