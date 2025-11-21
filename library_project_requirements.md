# Требования к учебному проекту «Система управления библиотекой»

## 1. Общая цель проекта

Разработать учебную реляционную базу данных в PostgreSQL для предметной области **библиотека** (Library Management System, LMS), которая демонстрирует:

- корректное проектирование схемы (связи 1–N, M–N, иерархии);
- использование ограничений целостности (PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK, DEFAULT);
- работу с обычными и материализованными представлениями (VIEW и MATERIALIZED VIEW);
- написание базовых и аналитических SQL‑запросов.

---

## 2. Требования к схеме базы данных

1. **Количество и состав таблиц**

   В схему должны входить не менее **11–12 таблиц**. В твоём проекте используются:

   - `authors` – авторы книг  
   - `books` – логические книги (произведения)  
   - `publishers` – издательства  
   - `categories` – жанры/категории книг (с иерархией через `parent_id`)  
   - `authors_books` – M–N связь авторов и книг  
   - `book_category` – M–N связь книг и категорий  
   - `book_editions` – издания книг (разные годы, форматы, издательства)  
   - `book_copies` – физические экземпляры конкретных изданий  
   - `readers` – пользователи/читатели библиотеки  
   - `loans` – выдачи книг читателям  
   - `reservations` – бронирования экземпляров  
   - `fines` – штрафы за просрочку возврата

2. **Ключи и связи**

   - Во всех таблицах есть **первичные ключи** (`primary key`) – обычно `integer not null primary key`.
   - Связи между таблицами оформлены через **FOREIGN KEY** с осмысленными правилами удаления:
     - `on delete restrict` – нельзя удалить запись из родительской таблицы, если на неё есть ссылки (строгая целостность).
   - Реализованы типы связей:
     - **1–N**:
       - один `publisher` → много `book_editions`  
       - один `book` → много `book_editions`  
       - один `reader` → много `loans` и `reservations`
     - **M–N** (через таблицы‑связки):
       - `authors` ↔ `books` через `authors_books`  
       - `books` ↔ `categories` через `book_category`
     - **Иерархия**:
       - `categories.parent_id` → `categories.id` (дерево категорий/подкатегорий).

3. **Ограничения и типы данных**

   - Используются основные типы:
     - `integer`, `text`, `char(2)` / `char(3)`, `date`, `timestamptz`, `boolean`, `jsonb`.
   - Основные ограничения:
     - `primary key` – уникальный идентификатор строки;
     - `unique` – запрет дубликатов (например, `authors.name`, `publishers.name`, `readers.email`, `books.isbn` и т.п.);
     - `not null` – обязательные поля (id, name, email, и т.д.);
     - `check (...)` – проверка допустимых значений:
       - `account_status in ('active','blocked','deleted')`;
       - `amount_cents >= 0`;
       - `edition_no is null or edition_no >= 1`;
       - `status in ('available','loaned','lost','repair')`, и т.п.;
     - `default`:
       - `created_at default now()` для фиксации времени создания записи;
       - `status default 'active'` / `status default 'unpaid'`;
       - `currency char(3) not null default 'USD'`.
   - Для части сущностей используется `jsonb` для хранения **произвольных метаданных** (`meta_json` в `books` – по аналогии с музыкальным сервисом).

---

## 3. Тестовые данные

1. Для **каждой таблицы** добавлено несколько записей (примерно 5–10 строк):

   - `authors` – несколько реальных авторов (Толстой, Достоевский, Orwell, Rowling, Murakami, Austen и т.д.);  
   - `publishers` – несколько издательств с адресами и email;  
   - `books` – реальные названия книг с годами и исходным языком;  
   - `book_editions` – несколько изданий на разные годы/издательства;  
   - `book_copies` – несколько физических экземпляров с `inventory_code` и разными `status`;  
   - `readers` – несколько читателей с email, телефоном, датой рождения;  
   - `loans`, `reservations`, `fines` – несколько строк для демонстрации работы связей и отчётных запросов.

2. Цель тестовых данных:

   - показать работу всех связей (join между таблицами);
   - обеспечить примеры для `group by`, `sum`, `count`, `rank()` и т.п.;
   - продемонстрировать разные состояния (`active`, `canceled`, `expired`, `fulfilled`, `unpaid`, `paid`, `waived`, `available`, `lost`, `repair`).

---

## 4. Индексы

Добавлены индексы на внешние ключи и поля, по которым часто идут фильтры и соединения:

- `create index idx_authors_books_book on authors_books (book_id);`  
  — ускоряет поиск авторов по конкретной книге и `join` `books ↔ authors_books` по `book_id`.

- `create index idx_book_editions_book on book_editions (book_id);`  
  — ускоряет поиск всех изданий одной книги и `join` `books ↔ book_editions`.

- `create index idx_book_copies_edition on book_copies (book_edition_id);`  
  — ускоряет поиск всех физических экземпляров по конкретному изданию и `join` `book_editions ↔ book_copies`.

(Можешь добавить ещё индексы по аналогии, например на `loans(reader_id)`, `loans(book_copy_id)`, `fines(loan_id)`.)

---

## 5. Представления (VIEW и MATERIALIZED VIEW)

1. **Обычное представление `v_books_authors_categories`**

   ```sql
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
   ```

   **Смысл и требования:**

   - это обычное VIEW (виртуальная таблица, данные не хранятся отдельно);
   - для каждой книги собираются:
     - название книги;
     - все авторы (в одну строку через запятую);
     - все категории (в одну строку через запятую);
   - используется:
     - несколько `join` для объединения `books`, `authors`, `authors_books`, `categories`, `book_category`;
     - агрегирующая функция `string_agg` с `distinct` и `order by`;
     - `coalesce(..., '')` для замены `null` на пустую строку;
     - `group by b.id, b.title` для получения одной строки на книгу.

2. **Материализованное представление `mv_top_books_90d`**

   ```sql
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
   ```

   **Смысл и требования:**

   - MATERIALIZED VIEW хранит результат как **физическую таблицу** (снимок на момент `create`/`refresh`);
   - `with base as (...)` – CTE, где считается количество выдач (`count(l.id)`) по каждой книге за последние 90 дней;
   - цепочка `join`:
     - `books` → `book_editions` → `book_copies` → `loans`  
       позволяет посчитать популярность на уровне логической книги;
   - `rank() over (order by loans_count desc, book_id asc)` добавляет **номер в рейтинге** по популярности;
   - для обновления данных используется:
     ```sql
     refresh materialized view mv_top_books_90d;
     ```

---

## 6. Примерные запросы для демонстрации работы

1. **Проверка количества строк в основных таблицах**

   ```sql
   select count(*) as counter from authors;
   select count(*) as counter from books;
   select count(*) as counter from book_editions;
   ```

2. **Получение всех книг с их авторами**

   ```sql
   select
     b.id,
     b.title,
     a.name as author_name
   from books b
   join authors_books ab on ab.book_id = b.id
   join authors a on a.id = ab.author_id
   order by b.id;
   ```
   - демонстрирует связь M–N через таблицу `authors_books`.

3. **Количество физических экземпляров по каждой книге**

   ```sql
   select
     b.id,
     b.title,
     count(c.id) as copies_count
   from books b
   join book_editions e on e.book_id = b.id
   join book_copies c on c.book_edition_id = e.id
   group by b.id, b.title
   order by copies_count desc;
   ```
   - показывает работу `group by` и подсчёт агрегатов по связанным таблицам.

4. **Все доступные экземпляры с названием книги**

   ```sql
   select
     c.id as copy_id,
     c.inventory_code,
     c.status,
     b.title
   from book_copies c
   join book_editions e on e.id = c.book_edition_id
  _join books b on b.id = e.book_id
   where c.status = 'available'
   order by c.id;
   ```
   - демонстрирует фильтрацию по статусу и несколько `join` подряд.

5. **Итоговые штрафы по каждому читателю**

   ```sql
   select
     r.id as reader_id,
     r.name as reader_name,
     sum(f.amount_cents) as total_fines_cents
   from fines f
   join loans l on l.id = f.loan_id
   join readers r on r.id = l.reader_id
   group by r.id, r.name
   order by total_fines_cents desc;
   ```
   - показывает работу с «фактовой» таблицей `fines`, агрегирование штрафов по читателям и использование `group by`.

---
