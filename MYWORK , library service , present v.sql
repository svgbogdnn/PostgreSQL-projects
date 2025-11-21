-- https://www.db-fiddle.com/f/8KeiFXUKfoTwCLGNyHmykU/11

-- https://drive.google.com/file/d/1Hb-TFmeFCu3bYim8HvBTzSIFbfqGWnCD/view?usp=sharing

/*
This project implements a relational database for a library
management system that catalogs authors, books, editions, 
categories, and physical copies, while handling reader accounts,
loans, reservations, and overdue fines to support end-to-end
circulation and inventory tracking. 
*/

-- Таблицы 

-- Авторы
create table authors (
  id integer not null primary key,
  name text not null unique,
  country_code char(2),
  birth_date date,
  created_at timestamptz not null default now()
);

-- Книги 
create table books (
  id integer not null primary key,
  title text not null,
  original_language char(2),
  publication_year integer,
  meta_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Издательства
create table publishers (
  id integer not null primary key,
  name text not null unique,
  contact_email text,
  country_code char(2),
  created_at timestamptz not null default now()
);

-- Категории
create table categories (
  id integer not null primary key,
  name text not null unique,
  parent_id integer references categories(id) on delete restrict
);

-- Читатели
create table readers (
  id integer not null primary key,
  email text not null unique,
  password_hash text not null,
  name text not null,
  birth_date date,
  phone text,
  created_at timestamptz not null default now(),
  account_status text not null default 'active'
    check (account_status in ('active','blocked','deleted'))
);

-- Издания книг 
create table book_editions (
  id integer not null primary key,
  book_id integer not null references books(id) on delete restrict,
  publisher_id integer not null references publishers(id) on delete restrict,
  isbn text unique,
  edition_no integer check (edition_no is null or edition_no >= 1),
  publication_year integer,
  format text,
  created_at timestamptz not null default now()
);

-- Физические экземпляры
create table book_copies (
  id integer not null primary key,
  book_edition_id integer not null references book_editions(id) on delete restrict,
  inventory_code text not null unique,
  status text not null check (status in ('available','loaned','lost','repair')),
  created_at timestamptz not null default now()
);

-- Автор-книга
create table authors_books (
  author_id integer not null references authors(id) on delete restrict,
  book_id integer not null references books(id) on delete restrict,
  role text,
  order_no integer,
  primary key (author_id, book_id)
);

-- Книга-категория 
create table book_category (
  book_id integer not null references books(id) on delete restrict,
  category_id integer not null references categories(id) on delete restrict,
  primary key (book_id, category_id)
);

-- Выдачи книг
create table loans (
  id integer not null primary key,
  reader_id integer not null references readers(id) on delete restrict,
  book_copy_id integer not null references book_copies(id) on delete restrict,
  loan_date timestamptz not null default now(),
  due_date date not null,
  return_date date,
  is_completed boolean not null default false
);

-- Бронирования
create table reservations (
  id integer not null primary key,
  reader_id integer not null references readers(id) on delete restrict,
  book_copy_id integer not null references book_copies(id) on delete restrict,
  reserved_at timestamptz not null default now(),
  status text not null default 'active'
    check (status in ('active','canceled','expired','fulfilled'))
);

-- Штрафы
create table fines (
  id integer not null primary key,
  loan_id integer not null references loans(id) on delete restrict,
  amount_cents integer not null check (amount_cents >= 0),
  currency char(3) not null default 'USD',
  due_date date not null,
  paid_at timestamptz,
  status text not null default 'unpaid'
    check (status in ('unpaid','paid','waived'))
);


-- индексы для связей и частых фильтров
create index idx_authors_books_book
  on authors_books (book_id);
create index idx_book_editions_book
  on book_editions (book_id);
create index idx_book_copies_edition
  on book_copies (book_edition_id);



-- Данные 

insert into authors (id, name, country_code, birth_date) values
    (101, 'Лев Толстой', 'RU', '1828-09-09'),
    (102, 'Фёдор Достоевский', 'RU', '1821-11-11'),
    (103, 'George Orwell', 'GB', '1903-06-25'),
    (104, 'J. K. Rowling', 'GB', '1965-07-31'),
    (105, 'Haruki Murakami', 'JP', '1949-01-12'),
    (106, 'Jane Austen', 'GB', '1775-12-16');

insert into publishers (id, name, contact_email, country_code) values
    (201, 'The Russian Messenger', 'info@russian-messenger.example', 'RU'),
    (202, 'Secker & Warburg', 'info@secker-warburg.example', 'GB'),
    (203, 'Bloomsbury Publishing', 'info@bloomsbury.example', 'GB'),
    (204, 'Shinchosha', 'info@shinchosha.example', 'JP'),
    (205, 'John Murray', 'info@john-murray.example', 'GB');

insert into books (id, title, original_language, publication_year, meta_json) values
    (301, 'Анна Каренина', 'ru', 1878, '{}'::jsonb),
    (302, 'Идиот', 'ru', 1869, '{}'::jsonb),
    (303, 'Animal Farm', 'en', 1945, '{}'::jsonb),
    (304, 'Harry Potter and the Chamber of Secrets', 'en', 1998, '{}'::jsonb),
    (305, 'Kafka on the Shore', 'ja', 2002, '{}'::jsonb),
    (306, 'Emma', 'en', 1816, '{}'::jsonb);

insert into categories (id, name, parent_id) values
    (401, 'Russian classics', null),
    (402, 'Political satire', null),
    (403, 'Fantasy', null),
    (404, 'Contemporary Japanese fiction', null),
    (405, 'English classics', null);

insert into readers (id, email, password_hash, name, birth_date, phone, account_status) values
    (701, 'ivan.petrov@example.com', 'hash-ivan-1', 'Иван Петров', '1990-01-15', '+1555000001', 'active'),
    (702, 'maria.ivanova@example.com', 'hash-maria-2', 'Мария Иванова', '1985-05-20', '+1555000002', 'active'),
    (703, 'alex.smirnov@example.com', 'hash-alex-3', 'Алексей Смирнов', '1992-08-03', '+1555000003', 'blocked'),
    (704, 'elena.sidorova@example.com', 'hash-elena-4', 'Елена Сидорова', '1995-11-30', '+1555000004', 'active'),
    (705, 'dmitry.nikolaev@example.com', 'hash-dmitry-5', 'Дмитрий Николаев', '1988-03-12', '+1555000005', 'deleted');

insert into book_editions (id, book_id, publisher_id, isbn, edition_no, publication_year, format) values
    (501, 301, 201, null, 1, 1878, 'hardcover'), -- Анна Каренина
    (502, 302, 201, null, 1, 1869, 'hardcover'), -- Идиот
    (503, 303, 202, null, 1, 1945, 'paperback'), -- Animal Farm
    (504, 304, 203, '0-7475-3849-2', 1, 1998, 'hardcover'), -- HP2
    (505, 305, 204, null, 1, 2002, 'paperback'), -- Kafka on the Shore
    (506, 306, 205, null, 1, 1816, 'hardcover'); -- Emma

insert into book_copies (id, book_edition_id, inventory_code, status) values
    (601, 501, 'AK-001', 'available'),
    (602, 501, 'AK-002', 'loaned'),
    (603, 502, 'ID-001', 'available'),
    (604, 503, 'AF-001', 'available'),
    (605, 503, 'AF-002', 'loaned'),
    (606, 504, 'HP2-001', 'available'),
    (607, 505, 'KS-001', 'available'),
    (608, 505, 'KS-002', 'repair'),
    (609, 506, 'EM-001', 'available'),
    (610, 506, 'EM-002', 'lost');

insert into authors_books (author_id, book_id, role, order_no) values
    (101, 301, 'author', 1),
    (102, 302, 'author', 1),
    (103, 303, 'author', 1),
    (104, 304, 'author', 1),
    (105, 305, 'author', 1),
    (106, 306, 'author', 1);

insert into book_category (book_id, category_id) values
    (301, 401),
    (302, 401),
    (303, 402),
    (304, 403),
    (305, 404),
    (306, 405);

insert into loans (id, reader_id, book_copy_id, loan_date, due_date, return_date, is_completed) values
    (801, 701, 602, '2024-01-10 10:00:00+00', '2024-02-10', '2024-02-05', true),
    (802, 702, 605, '2024-03-15 14:30:00+00', '2024-04-15', null, false),
    (803, 703, 603, '2024-02-01 09:00:00+00', '2024-03-01', '2024-03-10', true),
    (804, 704, 606, '2024-04-20 16:45:00+00', '2024-05-20', null, false),
    (805, 705, 604, '2024-05-05 11:20:00+00', '2024-06-05', '2024-05-20', true);

insert into reservations (id, reader_id, book_copy_id, reserved_at, status) values
    (901, 701, 601, '2024-01-05 12:00:00+00', 'fulfilled'),
    (902, 702, 607, '2024-03-10 09:00:00+00', 'active'),
    (903, 704, 609, '2024-04-01 13:30:00+00', 'canceled'),
    (904, 705, 610, '2024-05-01 15:10:00+00', 'expired');

insert into fines (id, loan_id, amount_cents, currency, due_date, paid_at, status) values
    (1001, 801, 500, 'USD', '2024-02-01', '2024-02-03 10:00:00+00', 'paid'),
    (1002, 802, 1500, 'USD', '2024-04-20', null, 'unpaid'),
    (1003, 803, 700, 'USD', '2024-03-05', null, 'waived');


-- количество строк в таблицах

select count(*) as counter from authors;
select count(*) as counter from books;
select count(*) as counter from book_editions;

-- все книги с их авторами
select
  b.id,
  b.title,
  a.name as author_name
from books b
join authors_books ab on ab.book_id = b.id
join authors a on a.id = ab.author_id
order by b.id;

-- количество экземпляров по каждой книге (по изданиям и копиям)
select
  b.id,
  b.title,
  count(c.id) as copies_count
from books b
join book_editions e on e.book_id = b.id
join book_copies c on c.book_edition_id = e.id
group by b.id, b.title
order by copies_count desc;

-- все доступные экземпляры с названием книги
select
  c.id as copy_id,
  c.inventory_code,
  c.status,
  b.title
from book_copies c
join book_editions e on e.id = c.book_edition_id
join books b on b.id = e.book_id
where c.status = 'available'
order by c.id;

-- активные выдачи с именем читателя и названием книги
select
  l.id as loan_id,
  r.name as reader_name,
  b.title as book_title,
  l.loan_date,
  l.due_date
from loans l
join readers r on r.id = l.reader_id
join book_copies c on c.id = l.book_copy_id
join book_editions e on e.id = c.book_edition_id
join books b on b.id = e.book_id
where l.is_completed = false
order by l.due_date;

-- итоговые штрафы по каждому читателю
select
  r.id as reader_id,
  r.name as reader_name,
  sum(f.amount_cents) as total_fines_cents
from fines f
join loans l on l.id = f.loan_id
join readers r on r.id = l.reader_id
group by r.id, r.name
order by total_fines_cents desc;



-- Представления 

-- книги + авторы + категории в одной строке на книгу
create view v_books_authors_categories as
select
  b.id as book_id,
  b.title as book_title,
  coalesce(
    string_agg(distinct a.name, ', ' order by a.name),
    ''
  ) as authors,
  coalesce(
    string_agg(distinct c.name, ', ' order by c.name),
    ''
  ) as categories
from books b
left join authors_books ab on ab.book_id = b.id
left join authors a on a.id = ab.author_id
left join book_category bc on bc.book_id = b.id
left join categories c on c.id = bc.category_id
group by b.id, b.title;

-- проверка
-- select * from v_books_authors_categories order by book_id;


-- мат. представление: топ-книги по количеству выдач за последние 90 дней
create materialized view mv_top_books_90d as
with base as (
  select
    b.id as book_id,
    b.title as book_title,
    count(l.id) as loans_count
  from books b
  join book_editions e on e.book_id = b.id
  join book_copies c on c.book_edition_id = e.id
  join loans l on l.book_copy_id = c.id
  where l.loan_date >= now() - interval '90 days'
  group by b.id, b.title
)
select
  *,
  rank() over (order by loans_count desc, book_id asc) as rnk
from base;

-- проверка
-- refresh materialized view mv_top_books_90d;
-- select * from mv_top_books_90d order by rnk limit 10;
