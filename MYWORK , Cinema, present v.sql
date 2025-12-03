-- https://drive.google.com/file/d/17wpmdXpwHQst37cf3hhzBs2BR7_y3RZZ/view?usp=sharing

-- Сервис для управления кинотеатрами



-- Кинотеатры
create table cinemas (
  id integer not null primary key,
  name text not null unique,
  city text,
  address text,
  phone text,
  email text,
  created_at timestamptz not null default now()
);

-- Залы
create table halls (
  id integer not null primary key,
  cinema_id integer not null references cinemas(id) on delete restrict,
  name text not null unique,
  total_seats integer check (total_seats is null or total_seats >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Посадочные места
create table seats (
  id integer not null primary key,
  hall_id integer not null references halls(id) on delete restrict,
  row_number integer not null unique check (row_number >= 1),
  seat_number integer not null unique check (seat_number >= 1),
  seat_type text not null default 'standard'
    check (seat_type in ('standard','vip','couple','wheelchair')),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Фильмы
create table movies (
  id integer not null primary key,
  title text not null,
  original_title text,
  duration_minutes integer not null check (duration_minutes > 0),
  age_rating text,
  release_year integer,
  language_code char(2),
  created_at timestamptz not null default now()
);

-- Форматы показа фильмов
create table movie_formats (
  id integer not null primary key,
  code text not null unique,
  description text,
  created_at timestamptz not null default now()
);

-- Сеансы
create table showtimes (
  id integer not null primary key,
  hall_id integer not null references halls(id) on delete restrict,
  movie_id integer not null references movies(id) on delete restrict,
  movie_format_id integer references movie_formats(id) on delete restrict,
  start_time timestamptz not null,
  end_time timestamptz,
  base_price_cents integer not null check (base_price_cents >= 0),
  status text not null default 'scheduled'
    check (status in ('scheduled','on_sale','sold_out','canceled','finished')),
  created_at timestamptz not null default now()
);

-- Ценовые тарифы на билеты
create table tariffs (
  id integer not null primary key,
  name text not null unique,
  description text,
  price_delta_cents integer not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Тарифы на сеансах
create table showtime_tariffs (
  showtime_id integer not null references showtimes(id) on delete restrict,
  tariff_id integer not null references tariffs(id) on delete restrict,
  primary key (showtime_id, tariff_id)
);

-- Клиенты
create table customers (
  id integer not null primary key,
  full_name text not null,
  email text unique,
  phone text,
  created_at timestamptz not null default now()
);

-- Бронирования билетов на сеансы
create table bookings (
  id integer not null primary key,
  booking_code text not null unique,
  customer_id integer not null references customers(id) on delete restrict,
  created_at timestamptz not null default now(),
  status text not null default 'created'
    check (status in ('created','paid','canceled','expired')),
  total_price_cents integer not null check (total_price_cents >= 0),
  currency char(3) not null default 'USD'
);

-- Билеты
create table tickets (
  id integer not null primary key,
  booking_id integer not null references bookings(id) on delete restrict,
  showtime_id integer not null references showtimes(id) on delete restrict,
  seat_id integer not null references seats(id) on delete restrict unique,
  price_cents integer not null check (price_cents >= 0),
  currency char(3) not null default 'USD',
  ticket_status text not null default 'reserved'
    check (ticket_status in ('reserved','paid','canceled','used','refunded','no_show')),
  created_at timestamptz not null default now()
);

-- Платежи по бронированиям
create table payments (
  id integer not null primary key,
  booking_id integer not null references bookings(id) on delete restrict,
  paid_at timestamptz,
  amount_cents integer not null check (amount_cents >= 0),
  currency char(3) not null default 'USD',
  payment_method text not null default 'card'
    check (payment_method in ('card','cash','online','other')),
  status text not null default 'pending'
    check (status in ('pending','success','failed','refunded')),
  created_at timestamptz not null default now()
);

-- Продукция бара
create table bar_products (
  id integer not null primary key,
  name text not null,
  category text,
  price_cents integer not null check (price_cents >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Товары бара в составе бронирования
create table booking_bar_products (
  booking_id integer not null references bookings(id) on delete restrict,
  bar_product_id integer not null references bar_products(id) on delete restrict,
  quantity integer not null check (quantity > 0),
  price_cents integer not null check (price_cents >= 0),
  primary key (booking_id, bar_product_id)
);

-- Индексы
create index idx_halls_cinema_id on halls (cinema_id);
create index idx_seats_hall_id on seats (hall_id);
create index idx_showtimes_hall_id on showtimes (hall_id);
create index idx_showtimes_movie_id on showtimes (movie_id);
create index idx_showtimes_start_time on showtimes (start_time);





-- Значения

-- Кинотеатры
insert into cinemas (id, name, city, address, phone, email) values
  (1, 'Pathé Tuschinski', 'Amsterdam', 'Reguliersbreestraat 26-34, 1017 CN Amsterdam', '+31-20-000-0001', 'info.tuschinski@example.com'),
  (2, 'Odeon Luxe Leicester Square', 'London', '22-24 Leicester Square, London WC2H 7LQ', '+44-20-0000-0002', 'info.leicester@odeon.example.com'),
  (3, 'UGC Ciné Cité Les Halles', 'Paris', '7 Place de la Rotonde, 75001 Paris', '+33-1-0000-0003', 'leshalles@ugc.example.com'),
  (4, 'Cineworld Glasgow Renfrew Street', 'Glasgow', '7 Renfrew Street, Glasgow', '+44-141-000-0004', 'glasgow.renfrew@cineworld.example.com'),
  (5, 'AMC Empire 25', 'New York', '234 West 42nd Street, New York, NY 10036', '+1-212-000-0005', 'empire25@amc.example.com'),
  (6, 'Lotte Cinema World Tower', 'Seoul', 'Lotte World Tower, Songpa-gu, Seoul', '+82-2-000-0006', 'worldtower@lottecinema.example.com'),
  (7, 'Vue West End', 'London', '3 Cranbourn Street, Leicester Square, London', '+44-20-0000-0007', 'westend@vue.example.com'),
  (8, 'Kino International', 'Berlin', 'Karl-Marx-Allee 33, 10178 Berlin', '+49-30-000-0008', 'info@kino-international.example.com');

-- Залы
insert into halls (id, cinema_id, name, total_seats, is_active) values
  (1, 1, 'Hall 1', 300, true),
  (2, 1, 'Hall 2', 150, true),
  (3, 2, 'Dolby Cinema', 350, true),
  (4, 2, 'Screen 2', 150, true),
  (5, 3, 'Salle 1', 400, true),
  (6, 3, 'Salle 2', 250, true),
  (7, 5, 'IMAX', 400, true),
  (8, 8, 'Main Hall', 500, true);

-- Места
insert into seats (id, hall_id, row_number, seat_number, seat_type) values
  (1, 1, 1, 1, 'standard'),
  (2, 1, 1, 2, 'standard'),
  (3, 1, 1, 3, 'standard'),
  (4, 1, 1, 4, 'standard'),
  (5, 1, 1, 5, 'vip'),
  (6, 1, 2, 1, 'standard'),
  (7, 1, 2, 2, 'standard'),
  (8, 1, 2, 3, 'standard'),
  (9, 1, 2, 4, 'standard'),
  (10, 1, 2, 5, 'vip'),

  (11, 3, 1, 1, 'standard'),
  (12, 3, 1, 2, 'standard'),
  (13, 3, 1, 3, 'standard'),
  (14, 3, 1, 4, 'standard'),
  (15, 3, 1, 5, 'vip'),
  (16, 3, 2, 1, 'standard'),
  (17, 3, 2, 2, 'standard'),
  (18, 3, 2, 3, 'standard'),
  (19, 3, 2, 4, 'standard'),
  (20, 3, 2, 5, 'vip'),

  (21, 7, 1, 1, 'standard'),
  (22, 7, 1, 2, 'standard'),
  (23, 7, 1, 3, 'standard'),
  (24, 7, 1, 4, 'standard'),
  (25, 7, 1, 5, 'vip'),
  (26, 7, 2, 1, 'standard'),
  (27, 7, 2, 2, 'standard'),
  (28, 7, 2, 3, 'standard'),
  (29, 7, 2, 4, 'standard'),
  (30, 7, 2, 5, 'vip');

-- Фильмы (реальные)
insert into movies (id, title, original_title, duration_minutes, age_rating, release_year, language_code) values
  (1, 'Barbie', 'Barbie', 114, 'PG-13', 2023, 'EN'),
  (2, 'Oppenheimer', 'Oppenheimer', 180, 'R', 2023, 'EN'),
  (3, 'The Super Mario Bros. Movie', 'The Super Mario Bros. Movie', 92, 'PG', 2023, 'EN'),
  (4, 'Dune: Part Two', 'Dune: Part Two', 166, 'PG-13', 2024, 'EN'),
  (5, 'Inside Out 2', 'Inside Out 2', 100, 'PG', 2024, 'EN'),
  (6, 'Deadpool & Wolverine', 'Deadpool & Wolverine', 128, 'R', 2024, 'EN'),
  (7, 'Moana 2', 'Moana 2', 100, 'PG', 2024, 'EN'),
  (8, 'Despicable Me 4', 'Despicable Me 4', 95, 'PG', 2024, 'EN');

-- Форматы показа
insert into movie_formats (id, code, description) values
  (1, '2D', 'Standard digital 2D'),
  (2, '3D', 'Stereoscopic 3D'),
  (3, 'IMAX', 'Large-format IMAX'),
  (4, '4DX', 'Motion seats with effects');

-- Сеансы
insert into showtimes (id, hall_id, movie_id, movie_format_id, start_time, end_time, base_price_cents, status) values
  (1, 1, 1, 1, '2025-12-03 18:00:00+01', '2025-12-03 20:00:00+01', 1200, 'on_sale'),
  (2, 1, 2, 3, '2025-12-03 20:30:00+01', '2025-12-03 23:30:00+01', 1800, 'scheduled'),
  (3, 3, 4, 3, '2025-12-03 19:00:00+00', '2025-12-03 21:45:00+00', 1600, 'on_sale'),
  (4, 3, 5, 1, '2025-12-03 16:00:00+00', '2025-12-03 17:45:00+00', 1300, 'on_sale'),
  (5, 7, 6, 3, '2025-12-03 19:30:00-05', '2025-12-03 21:45:00-05', 1700, 'on_sale'),
  (6, 7, 8, 1, '2025-12-03 17:00:00-05', '2025-12-03 18:40:00-05', 1100, 'on_sale');

-- Тарифы
insert into tariffs (id, name, description, price_delta_cents, is_active) values
  (1, 'Standard', 'Base price without adjustment', 0, true),
  (2, 'Student', 'Student discount', -200, true),
  (3, 'VIP Seat', 'Supplement for VIP or premium seats', 400, true),
  (4, 'Morning', 'Morning/matinee discount', -300, true);

-- Тарифы, применимые к сеансам
insert into showtime_tariffs (showtime_id, tariff_id) values
  (1, 1),
  (1, 2),
  (1, 3),
  (3, 1),
  (3, 3),
  (4, 1),
  (4, 2),
  (4, 4),
  (5, 1),
  (5, 3),
  (6, 1),
  (6, 4);

-- Клиенты
insert into customers (id, full_name, email, phone) values
  (1, 'Alice Johnson', 'alice.johnson@example.com', '+44-7700-000001'),
  (2, 'Bob Smith', 'bob.smith@example.com', '+31-6-0000-0002'),
  (3, 'Claire Dubois', 'claire.dubois@example.com', '+33-6-0000-0003'),
  (4, 'Daniel Müller', 'daniel.mueller@example.com', '+49-160-0000004'),
  (5, 'Eun-ji Kim', 'eunji.kim@example.com', '+82-10-0000-0005');

-- Бронирования
insert into bookings (id, booking_code, customer_id, status, total_price_cents, currency) values
  (1, 'BK20251203-001', 1, 'paid',     4600, 'EUR'),
  (2, 'BK20251203-002', 2, 'paid',     3000, 'GBP'),
  (3, 'BK20251203-003', 3, 'created',  1300, 'GBP'),
  (4, 'BK20251203-004', 4, 'paid',     6400, 'USD'),
  (5, 'BK20251203-005', 5, 'paid',     2000, 'USD'),
  (6, 'BK20251203-006', 1, 'canceled', 2550, 'EUR');

-- Продукты бара
insert into bar_products (id, name, category, price_cents, is_active) values
  (1, 'Popcorn Small', 'snack', 500, true),
  (2, 'Popcorn Large', 'snack', 800, true),
  (3, 'Soda 0.5L', 'drink', 400, true),
  (4, 'Craft Beer', 'drink', 700, true),
  (5, 'Nachos', 'snack', 750, true),
  (6, 'Chocolate Bar', 'snack', 300, true);

-- Билеты
insert into tickets (id, booking_id, showtime_id, seat_id, price_cents, currency, ticket_status) values
  (1, 1, 1,  1, 1400, 'EUR', 'paid'),
  (2, 1, 1,  2, 1400, 'EUR', 'paid'),
  (3, 2, 3, 11, 1800, 'GBP', 'paid'),
  (4, 3, 4, 12, 1300, 'GBP', 'reserved'),
  (5, 4, 5, 21, 1700, 'USD', 'paid'),
  (6, 4, 5, 22, 1700, 'USD', 'paid'),
  (7, 5, 6, 23, 1100, 'USD', 'paid'),
  (8, 6, 2,  3, 1800, 'EUR', 'canceled');

-- Платежи
insert into payments (id, booking_id, paid_at, amount_cents, currency, payment_method, status) values
  (1, 1, '2025-12-01 12:00:00+01', 4600, 'EUR', 'online', 'success'),
  (2, 2, '2025-12-01 13:00:00+00', 3000, 'GBP', 'card',   'success'),
  (3, 3, null,                         1300, 'GBP', 'card',   'pending'),
  (4, 4, '2025-12-01 10:30:00-05', 6400, 'USD', 'online', 'success'),
  (5, 5, '2025-12-02 09:00:00-05', 2000, 'USD', 'cash',   'success'),
  (6, 6, '2025-12-01 18:00:00+01', 2550, 'EUR', 'card',   'refunded');

-- Позиции бара в заказах
insert into booking_bar_products (booking_id, bar_product_id, quantity, price_cents) values
  (1, 1, 2, 1000),
  (1, 3, 2,  800),
  (2, 2, 1,  800),
  (2, 3, 1,  400),
  (4, 2, 2, 1600),
  (4, 4, 2, 1400),
  (5, 1, 1,  500),
  (5, 3, 1,  400),
  (6, 5, 1,  750);


--Количество строк в таблицах
select count(*) as cinemas_counter
from cinemas;
select count(*) as movies_counter
from movies;
select count(*) as tickets_counter
from tickets;


-- 1 сколько кинотеатров в каждом городе
select
  city,
  count(*) as cinemas_count
from cinemas
group by city
order by cinemas_count desc, city;

-- 2 расписание сеансов с кинотеатром, залом, фильмом и форматом
select
  st.id as showtime_id,
  c.name as cinema_name,
  h.name as hall_name,
  m.title as movie_title,
  mf.code as format_code,
  st.start_time,
  st.end_time,
  st.base_price_cents,
  st.status
from showtimes st
join halls h on st.hall_id = h.id
join cinemas c on h.cinema_id = c.id
join movies m on st.movie_id = m.id
left join movie_formats mf on st.movie_format_id = mf.id
order by st.start_time, cinema_name, hall_name;

-- 3 статистика по статусам сеансов
select
  status,
  count(*) as showtimes_count
from showtimes
group by status
order by showtimes_count desc, status;

-- 4 сколько билетов продано на каждый сеанс
select
  st.id as showtime_id,
  c.name as cinema_name,
  h.name as hall_name,
  m.title as movie_title,
  st.start_time,
  count(t.id) as tickets_count
from showtimes st
join halls h on st.hall_id = h.id
join cinemas c on h.cinema_id = c.id
join movies m on st.movie_id = m.id
left join tickets t on t.showtime_id = st.id
group by
  st.id,
  c.name,
  h.name,
  m.title,
  st.start_time
order by st.id;

-- 5 топ фильмов по количеству проданных билетов
select
  m.id as movie_id,
  m.title as movie_title,
  count(t.id) as tickets_count
from movies m
left join showtimes st on st.movie_id = m.id
left join tickets t on t.showtime_id = st.id
group by m.id, m.title
order by tickets_count desc, movie_title;



-- обычное представление: расписание сеансов
create view v_showtime_schedule as
select
  st.id as showtime_id,
  c.name as cinema_name,
  c.city,
  h.name as hall_name,
  m.title as movie_title,
  mf.code as format_code,
  st.start_time,
  st.end_time,
  st.base_price_cents,
  st.status
from showtimes st
join halls h on st.hall_id = h.id
join cinemas c on h.cinema_id = c.id
join movies m on st.movie_id = m.id
left join movie_formats mf on st.movie_format_id = mf.id;

-- Проверка
-- select *
-- from v_showtime_schedule
-- order by start_time
-- limit 50;



-- материальное представление: статистика по фильмам, билеты и выручка
create materialized view mv_movie_ticket_stats as
select
  m.id as movie_id,
  m.title as movie_title,
  count(t.id) as tickets_count,
  coalesce(sum(t.price_cents), 0) as total_revenue_cents
from movies m
left join showtimes st on st.movie_id = m.id
left join tickets t on t.showtime_id = st.id
group by m.id, m.title;

-- Проверка
-- refresh materialized view mv_movie_ticket_stats;
-- select *
-- from mv_movie_ticket_stats
-- order by tickets_count desc, movie_title;
