-- Диаграмма 
-- https://drive.google.com/file/d/1aUhPtKf7hHml8pKJ2b4JMha7UNWFQn3F/view?usp=sharing

-- Сервис-база данных аэропорта

-- Таблицы 

-- 1 Авиакомпании
create table airlines (
  id integer not null primary key,
  name text not null unique,
  iata_code char(2) unique,
-- International Air Transport Association
  icao_code char(3) unique,
-- International Civil Aviation Organization
  country_code char(2),
  created_at timestamptz not null default now()
);

-- 2 Аэропорты
create table airports (
  id integer not null primary key,
  name text not null,
  city text,
  country text,
  country_code char(2),
  iata_code char(3) unique,
  icao_code char(4) unique,
  time_zone text,
  created_at timestamptz not null default now()
);

-- 3 Выходы на посадку, гейты аэропортов
create table gates (
  id integer not null primary key,
  airport_id integer not null references airports(id) on delete restrict,
  terminal text,
  gate_code text not null,
  created_at timestamptz not null default now(),
  unique (airport_id, terminal, gate_code)
);

-- 4 Типы самолетов
create table aircraft_types (
  id integer not null primary key,
  manufacturer text,
  model text not null unique,
  icao_code char(4) unique,
  capacity_seats integer not null check (capacity_seats > 0),
  created_at timestamptz not null default now()
);

-- 5 Самолеты
create table aircrafts (
  id integer not null primary key,
  airline_id integer not null references airlines(id) on delete restrict,
  aircraft_type_id integer not null references aircraft_types(id) on delete restrict,
  tail_number text not null unique,
  manufacture_year integer,
  status text not null default 'active'
    check (status in ('active','maintenance','retired')),
  created_at timestamptz not null default now()
);

-- 6 Логические рейсы, маршруты по расписанию
create table flights (
  id integer not null primary key,
  airline_id integer not null references airlines(id) on delete restrict,
  flight_number text not null,
  origin_airport_id integer not null references airports(id) on delete restrict,
  destination_airport_id integer not null references airports(id) on delete restrict,
  base_departure_time time not null,
  base_arrival_time time not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  check (origin_airport_id <> destination_airport_id),
  unique (airline_id, flight_number)
);

-- 7 Выполнения рейсов, конкретные вылеты по датам
create table flight_instances (
  id integer not null primary key,
  flight_id integer not null references flights(id) on delete restrict,
  scheduled_departure timestamptz not null,
  scheduled_arrival timestamptz,
  actual_departure timestamptz,
  actual_arrival timestamptz,
  status text not null default 'scheduled'
    check (status in ('scheduled','boarding','departed','arrived','delayed','canceled')),
  gate_id integer references gates(id) on delete set null,
  aircraft_id integer references aircrafts(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (flight_id, scheduled_departure)
);

-- 8 Пассажиры, справочник клиентов
create table passengers (
  id integer not null primary key,
  full_name text not null,
  birth_date date,
  document_type text,
  document_number text,
  email text,
  phone text,
  created_at timestamptz not null default now(),
  unique (document_type, document_number)
);

-- 9 Бронирования авиабилетов
create table bookings (
  id integer not null primary key,
  booking_code text not null unique,
  passenger_id integer not null references passengers(id) on delete restrict,
  created_at timestamptz not null default now(),
  status text not null default 'booked'
    check (status in ('booked','ticketed','canceled')),
  total_price_cents integer not null check (total_price_cents >= 0),
  currency char(3) not null default 'USD'
);

-- 10 Билеты на рейсы, места на конкретные вылеты
create table tickets (
  id integer not null primary key,
  booking_id integer not null references bookings(id) on delete restrict,
  flight_instance_id integer not null references flight_instances(id) on delete restrict,
  seat_no text,
  service_class text not null default 'economy'
    check (service_class in ('economy','premium_economy','business','first')),
  ticket_status text not null default 'issued'
    check (ticket_status in ('booked','issued','checked_in','boarded','canceled','refunded','no_show')),
  price_cents integer not null check (price_cents >= 0),
  currency char(3) not null default 'USD',
  created_at timestamptz not null default now()
);

-- 11 Регистрация на рейс, check-in по билетам
create table checkins (
  id integer not null primary key,
  ticket_id integer not null references tickets(id) on delete restrict unique,
  checked_in_at timestamptz not null default now(),
  checkin_counter text,
  boarding_group text,
  seat_no text,
  has_baggage boolean not null default false,
  boarding_pass_number text,
  created_at timestamptz not null default now()
);

-- 12 Багаж
create table baggage (
  id integer not null primary key,
  ticket_id integer not null references tickets(id) on delete restrict,
  tag_number text not null unique,
  weight_kg numeric(5,2) not null check (weight_kg >= 0),
  status text not null default 'checked_in'
    check (status in ('checked_in','loaded','unloaded','lost','delivered')),
  created_at timestamptz not null default now()
);


-- индексы для связей и частых фильтров, ускоряют поиск и выборку данных
create index idx_gates_airport
  on gates (airport_id);

create index idx_aircrafts_airline
  on aircrafts (airline_id);

create index idx_aircrafts_type
  on aircrafts (aircraft_type_id);
  
  
  
-- Данные 

-- 1 airlines
insert into airlines (id, name, iata_code, icao_code, country_code) values
  (1, 'Lufthansa', 'LH', 'DLH', 'DE'),
  (2, 'Air France', 'AF', 'AFR', 'FR'),
  (3, 'KLM Royal Dutch Airlines', 'KL', 'KLM', 'NL'),
  (4, 'British Airways', 'BA', 'BAW', 'GB'),
  (5, 'Ryanair', 'FR', 'RYR', 'IE'),
  (6, 'easyJet', 'U2', 'EZY', 'GB'),
  (7, 'Turkish Airlines', 'TK', 'THY', 'TR'),
  (8, 'Swiss International Air Lines', 'LX', 'SWR', 'CH'),
  (9, 'Iberia', 'IB', 'IBE', 'ES'),
  (10, 'SAS Scandinavian Airlines', 'SK', 'SAS', 'SE');

-- 2 airports
insert into airports (id, name, city, country, country_code, iata_code, icao_code, time_zone) values
  (1, 'Frankfurt Airport', 'Frankfurt', 'Germany', 'DE', 'FRA', 'EDDF', 'Europe/Berlin'),
  (2, 'Paris Charles de Gaulle Airport', 'Paris', 'France', 'FR', 'CDG', 'LFPG', 'Europe/Paris'),
  (3, 'Amsterdam Schiphol Airport', 'Amsterdam', 'Netherlands', 'NL', 'AMS', 'EHAM', 'Europe/Amsterdam'),
  (4, 'London Heathrow Airport', 'London', 'United Kingdom', 'GB', 'LHR', 'EGLL', 'Europe/London'),
  (5, 'Adolfo Suárez Madrid–Barajas Airport', 'Madrid', 'Spain', 'ES', 'MAD', 'LEMD', 'Europe/Madrid'),
  (6, 'Zurich Airport', 'Zurich', 'Switzerland', 'CH', 'ZRH', 'LSZH', 'Europe/Zurich'),
  (7, 'Istanbul Airport', 'Istanbul', 'Turkey', 'TR', 'IST', 'LTFM', 'Europe/Istanbul'),
  (8, 'Barcelona–El Prat Airport', 'Barcelona', 'Spain', 'ES', 'BCN', 'LEBL', 'Europe/Madrid'),
  (9, 'Rome Fiumicino Airport', 'Rome', 'Italy', 'IT', 'FCO', 'LIRF', 'Europe/Rome'),
  (10, 'Copenhagen Airport, Kastrup', 'Copenhagen', 'Denmark', 'DK', 'CPH', 'EKCH', 'Europe/Copenhagen');

-- 3 gates
insert into gates (id, airport_id, terminal, gate_code) values
  (1, 1, '1', 'A12'),
  (2, 1, '1', 'A15'),
  (3, 2, '2E', 'K21'),
  (4, 3, '1', 'D05'),
  (5, 4, '5', 'B34'),
  (6, 5, '4', 'J12'),
  (7, 6, '1', 'A06'),
  (8, 7, 'I', 'G02'),
  (9, 8, '1', 'A10'),
  (10, 10, '3', 'C24');

-- 4 aircraft_types
insert into aircraft_types (id, manufacturer, model, icao_code, capacity_seats) values
  (1, 'Airbus', 'A320', 'A320', 180),
  (2, 'Boeing', '737-800', 'B738', 189),
  (3, 'Boeing', '777-300ER', 'B77W', 396);

-- 5 aircrafts
insert into aircrafts (id, airline_id, aircraft_type_id, tail_number, manufacture_year, status) values
  (1, 1, 1, 'D-AIUA', 2013, 'active'),
  (2, 2, 1, 'F-GKXH', 2002, 'active'),
  (3, 3, 2, 'PH-BXA', 2003, 'active'),
  (4, 4, 1, 'G-EUYA', 2007, 'active'),
  (5, 5, 2, 'EI-DCL', 2010, 'active'),
  (6, 6, 1, 'G-EZTD', 2009, 'active'),
  (7, 7, 3, 'TC-JJP', 2013, 'active'),
  (8, 8, 1, 'HB-IJO', 1997, 'active'),
  (9, 9, 1, 'EC-MXU', 2018, 'active'),
  (10, 10, 1, 'LN-RGL', 2016, 'active');

-- 6 flights
insert into flights (id, airline_id, flight_number, origin_airport_id, destination_airport_id, base_departure_time, base_arrival_time, is_active) values
  (1, 1, 'LH100', 1, 3, '08:00:00', '09:15:00', true),
  (2, 2, 'AF1300', 2, 1, '07:30:00', '08:45:00', true),
  (3, 3, 'KL1771', 3, 8, '12:00:00', '14:30:00', true),
  (4, 4, 'BA485', 4, 5, '09:00:00', '12:20:00', true),
  (5, 5, 'FR456', 5, 10, '15:00:00', '19:00:00', true),
  (6, 6, 'U21600', 4, 3, '06:30:00', '08:45:00', true),
  (7, 7, 'TK1980', 7, 4, '14:00:00', '16:10:00', true),
  (8, 8, 'LX1742', 6, 9, '10:00:00', '11:40:00', true),
  (9, 9, 'IB3250', 5, 9, '13:00:00', '15:30:00', true),
  (10, 10, 'SK1670', 10, 3, '16:00:00', '17:30:00', true);

-- 7 flight_instances
insert into flight_instances (id, flight_id, scheduled_departure, scheduled_arrival, actual_departure, actual_arrival, status, gate_id, aircraft_id) values
  (1, 1, '2025-01-10 08:00:00+01', '2025-01-10 09:15:00+01', '2025-01-10 08:10:00+01', '2025-01-10 09:25:00+01', 'arrived', 1, 1),
  (2, 1, '2025-01-11 08:00:00+01', '2025-01-11 09:15:00+01', null, null, 'scheduled', 1, 1),
  (3, 2, '2025-01-10 07:30:00+01', '2025-01-10 08:45:00+01', '2025-01-10 07:40:00+01', '2025-01-10 08:55:00+01', 'arrived', 3, 2),
  (4, 2, '2025-01-11 07:30:00+01', '2025-01-11 08:45:00+01', null, null, 'canceled', 3, 2),
  (5, 3, '2025-01-10 12:00:00+01', '2025-01-10 14:30:00+01', '2025-01-10 12:05:00+01', '2025-01-10 14:40:00+01', 'arrived', 4, 3),
  (6, 3, '2025-01-11 12:00:00+01', '2025-01-11 14:30:00+01', null, null, 'scheduled', 4, 3),
  (7, 4, '2025-01-10 09:00:00+00', '2025-01-10 12:20:00+01', '2025-01-10 09:20:00+00', '2025-01-10 12:40:00+01', 'arrived', 5, 4),
  (8, 4, '2025-01-11 09:00:00+00', '2025-01-11 12:20:00+01', null, null, 'scheduled', 5, 4),
  (9, 5, '2025-01-10 15:00:00+01', '2025-01-10 19:00:00+01', '2025-01-10 15:00:00+01', '2025-01-10 18:50:00+01', 'arrived', 6, 5),
  (10, 5, '2025-01-11 15:00:00+01', '2025-01-11 19:00:00+01', null, null, 'scheduled', 6, 5),
  (11, 6, '2025-01-10 06:30:00+00', '2025-01-10 08:45:00+01', '2025-01-10 06:35:00+00', '2025-01-10 08:50:00+01', 'arrived', 5, 6),
  (12, 7, '2025-01-10 14:00:00+03', '2025-01-10 16:10:00+00', '2025-01-10 14:10:00+03', '2025-01-10 16:25:00+00', 'arrived', 8, 7),
  (13, 8, '2025-01-10 10:00:00+01', '2025-01-10 11:40:00+01', '2025-01-10 10:10:00+01', null, 'departed', 7, 8),
  (14, 9, '2025-01-10 13:00:00+01', '2025-01-10 15:30:00+01', null, null, 'scheduled', 6, 9),
  (15, 10, '2025-01-10 16:00:00+01', '2025-01-10 17:30:00+01', null, null, 'scheduled', 10, 10);

-- 8 passengers
insert into passengers (id, full_name, birth_date, document_type, document_number, email, phone) values
  (1, 'John Smith', '1985-04-12', 'passport', 'P1234567', 'john.smith@example.com', '+44-20-0000-0001'),
  (2, 'Maria Garcia', '1990-08-03', 'passport', 'P2345678', 'maria.garcia@example.com', '+34-91-0000-0002'),
  (3, 'Hans Müller', '1982-01-15', 'passport', 'P3456789', 'hans.mueller@example.com', '+49-69-0000-0003'),
  (4, 'Sophie Dubois', '1995-11-30', 'passport', 'P4567890', 'sophie.dubois@example.com', '+33-1-0000-0004'),
  (5, 'Luca Rossi', '1988-06-21', 'passport', 'P5678901', 'luca.rossi@example.com', '+39-06-0000-0005'),
  (6, 'Anna Kowalska', '1992-09-14', 'passport', 'P6789012', 'anna.kowalska@example.com', '+48-22-0000-0006'),
  (7, 'Peter Jensen', '1980-03-10', 'passport', 'P7890123', 'peter.jensen@example.com', '+45-32-0000-0007'),
  (8, 'Elena Petrova', '1993-07-19', 'passport', 'P8901234', 'elena.petrova@example.com', '+7-495-000-0008'),
  (9, 'David Novak', '1987-02-05', 'passport', 'P9012345', 'david.novak@example.com', '+420-2-0000-0009'),
  (10, 'Emma Johnson', '1998-12-25', 'passport', 'P0123456', 'emma.johnson@example.com', '+44-20-0000-0010'),
  (11, 'Carlos Sanchez', '1979-05-17', 'passport', 'P1122334', 'carlos.sanchez@example.com', '+34-91-0000-0011'),
  (12, 'Olga Ivanova', '1984-10-09', 'passport', 'P2233445', 'olga.ivanova@example.com', '+7-812-000-0012');

-- 9 bookings
insert into bookings (id, booking_code, passenger_id, created_at, status, total_price_cents, currency) values
  (1, 'AB12CD', 1, '2024-12-15 09:00:00+01', 'ticketed', 15000, 'EUR'),
  (2, 'EF34GH', 2, '2024-12-15 09:05:00+01', 'ticketed', 18000, 'EUR'),
  (3, 'IJ56KL', 3, '2024-12-16 10:10:00+01', 'ticketed', 22000, 'EUR'),
  (4, 'MN78OP', 4, '2024-12-16 11:20:00+01', 'ticketed', 24000, 'EUR'),
  (5, 'QR90ST', 5, '2024-12-17 12:30:00+01', 'ticketed', 26000, 'EUR'),
  (6, 'UV12WX', 6, '2024-12-17 13:40:00+01', 'ticketed', 14000, 'EUR'),
  (7, 'YZ34AA', 7, '2024-12-18 14:00:00+01', 'ticketed', 32000, 'EUR'),
  (8, 'BB56CC', 8, '2024-12-18 14:10:00+01', 'ticketed', 20000, 'EUR'),
  (9, 'DD78EE', 9, '2024-12-19 15:15:00+01', 'booked', 23000, 'EUR'),
  (10, 'FF90GG', 10, '2024-12-19 15:20:00+01', 'booked', 21000, 'EUR'),
  (11, 'HH12II', 11, '2024-12-20 16:00:00+01', 'booked', 17000, 'EUR'),
  (12, 'JJ34KK', 12, '2024-12-20 16:05:00+01', 'canceled', 18000, 'EUR');

-- 10 tickets
insert into tickets (id, booking_id, flight_instance_id, seat_no, service_class, ticket_status, price_cents, currency) values
  (1, 1, 1, '12A', 'economy', 'boarded', 15000, 'EUR'),
  (2, 2, 3, '14C', 'economy', 'boarded', 18000, 'EUR'),
  (3, 3, 5, '10A', 'economy', 'boarded', 22000, 'EUR'),
  (4, 4, 7, '22D', 'economy', 'boarded', 24000, 'EUR'),
  (5, 5, 9, '18A', 'economy', 'boarded', 26000, 'EUR'),
  (6, 6, 11, '7F', 'economy', 'boarded', 14000, 'EUR'),
  (7, 7, 12, '15C', 'economy', 'boarded', 32000, 'EUR'),
  (8, 8, 13, '4A', 'business', 'boarded', 20000, 'EUR'),
  (9, 9, 14, '19B', 'economy', 'issued', 23000, 'EUR'),
  (10, 10, 15, '23E', 'economy', 'issued', 21000, 'EUR'),
  (11, 11, 2, '12C', 'economy', 'issued', 17000, 'EUR'),
  (12, 12, 4, '14D', 'economy', 'canceled', 18000, 'EUR');

-- 11 checkins
insert into checkins (id, ticket_id, checked_in_at, checkin_counter, boarding_group, seat_no, has_baggage, boarding_pass_number) values
  (1, 1, '2025-01-09 20:00:00+01', 'online', 'A', '12A', true, 'BP-LH100-1'),
  (2, 2, '2025-01-09 19:30:00+01', 'online', 'A', '14C', true, 'BP-AF1300-2'),
  (3, 3, '2025-01-09 21:00:00+01', 'counter', 'B', '10A', true, 'BP-KL1771-3'),
  (4, 4, '2025-01-09 07:30:00+00', 'kiosk', 'B', '22D', true, 'BP-BA485-4'),
  (5, 5, '2025-01-10 12:30:00+01', 'online', 'C', '18A', true, 'BP-FR456-5'),
  (6, 6, '2025-01-10 04:30:00+00', 'online', 'A', '7F', false, 'BP-U21600-6'),
  (7, 7, '2025-01-10 11:30:00+03', 'counter', 'B', '15C', true, 'BP-TK1980-7'),
  (8, 8, '2025-01-10 08:30:00+01', 'online', 'A', '4A', true, 'BP-LX1742-8');

-- 12 baggage
insert into baggage (id, ticket_id, tag_number, weight_kg, status) values
  (1, 1, 'LH000001', 20.50, 'loaded'),
  (2, 2, 'AF000001', 23.00, 'loaded'),
  (3, 3, 'KL000001', 18.20, 'delivered'),
  (4, 3, 'KL000002', 19.70, 'delivered'),
  (5, 5, 'FR000001', 15.00, 'loaded'),
  (6, 7, 'TK000001', 24.30, 'loaded'),
  (7, 7, 'TK000002', 21.90, 'loaded'),
  (8, 8, 'LX000001', 17.40, 'loaded'),
  (9, 8, 'LX000002', 18.00, 'loaded'),
  (10, 4, 'BA000001', 20.00, 'loaded');


-- количество строк в таблицах

select count(*) as airlines_cnt  from airlines;
select count(*) as airports_cnt from airports;
select count(*) as flights_cnt from flights;
select count(*) as flight_instances_cnt from flight_instances;
select count(*) as tickets_cnt from tickets;


-- 1 сколько аэропортов в каждой стране
select
  country,
  country_code,
  count(*) as airports_count
from airports
group by country, country_code
order by airports_count desc, country;

-- 2 список логических рейсов с маршрутами и авиакомпаниями
select
  f.id,
  a.name as airline_name,
  f.flight_number,
  ao.iata_code as origin_iata,
  ao.city as origin_city,
  ad.iata_code as destination_iata,
  ad.city as destination_city,
  f.base_departure_time,
  f.base_arrival_time,
  f.is_active
from flights f
join airlines a on f.airline_id = a.id
join airports ao on f.origin_airport_id = ao.id
join airports ad on f.destination_airport_id = ad.id
order by f.id;

-- 3 статистика по статусам выполнений рейсов
select
  status,
  count(*) as flights_count
from flight_instances
group by status
order by flights_count desc, status;

-- 4 сколько билетов на каждое выполнение рейса
select
  fi.id as flight_instance_id,
  a.name as airline_name,
  f.flight_number,
  ao.iata_code as origin_iata,
  ad.iata_code as destination_iata,
  fi.scheduled_departure,
  count(t.id) as tickets_count
from flight_instances fi
join flights f on fi.flight_id = f.id
join airlines a on f.airline_id = a.id
join airports ao on f.origin_airport_id = ao.id
join airports ad on f.destination_airport_id = ad.id
left join tickets t on t.flight_instance_id = fi.id
group by
  fi.id,
  a.name,
  f.flight_number,
  ao.iata_code,
  ad.iata_code,
  fi.scheduled_departure
order by fi.scheduled_departure, airline_name, f.flight_number;

-- 5 сколько уникальных пассажиров у каждой авиакомпании 
select
  al.id as airline_id,
  al.name as airline_name,
  count(distinct b.passenger_id) as passengers_count
from airlines al
left join flights f on f.airline_id = al.id
left join flight_instances fi on fi.flight_id = f.id
left join tickets t on t.flight_instance_id = fi.id
left join bookings b on b.id = t.booking_id
group by al.id, al.name
order by passengers_count desc, airline_name;



-- Представления

-- обычное представление, расписание рейсов с детализацией
create view v_flight_schedule as
select
  fi.id as flight_instance_id,
  a.name as airline_name,
  f.flight_number,
  ao.iata_code as origin_iata,
  ao.city as origin_city,
  ad.iata_code as destination_iata,
  ad.city as destination_city,
  fi.scheduled_departure,
  fi.scheduled_arrival,
  fi.actual_departure,
  fi.actual_arrival,
  fi.status,
  g.terminal,
  g.gate_code,
  ac.tail_number
from flight_instances fi
join flights f on fi.flight_id = f.id
join airlines a on f.airline_id = a.id
join airports ao on f.origin_airport_id = ao.id
join airports ad on f.destination_airport_id = ad.id
left join gates g on fi.gate_id = g.id
left join aircrafts ac on fi.aircraft_id = ac.id;
-- проверка
-- select * from v_flight_schedule order by scheduled_departure limit 50;

-- материальное представление, агрегированная статистика по авиакомпаниям
create materialized view mv_airline_ticket_stats as
select
  al.id as airline_id,
  al.name as airline_name,
  count(t.id) as tickets_count,
  coalesce(sum(t.price_cents), 0) as total_revenue_cents
from airlines al
left join flights f on f.airline_id = al.id
left join flight_instances fi on fi.flight_id = f.id
left join tickets t on t.flight_instance_id = fi.id
group by al.id, al.name;
-- проверка
-- refresh materialized view mv_airline_ticket_stats;
-- select * from mv_airline_ticket_stats order by tickets_count desc, airline_name;
