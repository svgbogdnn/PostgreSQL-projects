-- https://www.db-fiddle.com/f/xfic6QQxRH5vHdkvVefLbZ/4

-- Schema SQL

-- .............................................................
-- .............................................................
-- .............................................................
-- .............................................................
-- .............................................................

-- Диаграмма png https://drive.google.com/file/d/1a3jUr3S7b4Rm-hS0a9YfLoK5UKSSUsBp/view?usp=sharing
-- Диаграмма pdf https://drive.google.com/file/d/1wlCSZTRstwvbM76RcMgmTW8ZUFKYxzO3/view?usp=sharing


/*
	TABLES
*/

-- !1-1 one string in A corresponds one string in B
-- !1-N one string in A match many strings in B, N-1 vice-versa
-- !M-N many strings in A match many strings in B
-- !0..1 maybe yes maybe no
-- !with = w/ = w;
-- !Primary key = Unique + Not Null, create B-tree index
-- !Unique = ban repeats in column, maybe Null
-- !References = link to other table, ON DELETE CASCADE delete parent and children, ON DELETE SET NULL delete parent and child link setted to Null
-- !CHECK = take only valid values



-- 1 Артисты / Исполнители

DROP TABLE IF EXISTS artists;
CREATE TABLE artists (
  id           integer     NOT NULL PRIMARY KEY,
  name         text        NOT NULL UNIQUE,
  aka          text,
  country_code char(2),
  created_at   timestamptz NOT NULL DEFAULT now()
);
-- 		!artists: name, nickname, country, createtime; !M-N through album_artist, M-N through track_artist, 1-N in follows_artists
--! id – PK; name – уникальное имя артиста; aka – псевдоним; country_code – ISO-2 (International Organization for Standardization) код страны; created_at – дата/время создания записи


-- 2 Лейблы

DROP TABLE IF EXISTS labels;
CREATE TABLE labels (
  id			integer     NOT NULL PRIMARY KEY,
  name          text        NOT NULL UNIQUE,
  contact_email text,
  created_at    timestamptz NOT NULL DEFAULT now()
);
--		!labels: name, email, createtime; 1-N w albums
--! id – PK; name – уникальное имя лейбла; contact_email – контактная почта; created_at – дата/время создания записи


-- 3 Альбомы / EP

DROP TABLE IF EXISTS albums;
CREATE TABLE albums (
  id           integer     NOT NULL PRIMARY KEY,
  title        text        NOT NULL,
  release_date date,
  upc          text        UNIQUE,
  -- Universal Product Code
  label_id     integer     NOT NULL REFERENCES labels(id) ON DELETE RESTRICT,
  created_at   timestamptz NOT NULL DEFAULT now()
);
--		!albums: title, release_date, upc, label, createtime;
--      !M-N tru album_artist, 1-N w tracks
--! id – PK; title – название релиза; release_date – дата релиза; upc – товарный код релиза; label_id – ссылка на лейбл; created_at – дата/время создания


-- 4 Треки / Песни

DROP TABLE IF EXISTS tracks;
CREATE TABLE tracks (
  id           integer     NOT NULL PRIMARY KEY,
  album_id     integer     NOT NULL REFERENCES albums(id) ON DELETE RESTRICT,
  title        text        NOT NULL,
  duration_sec integer               CHECK (duration_sec >= 0),
  isrc         text        UNIQUE,
  -- International Standard Recording Code
  meta_json    jsonb       NOT NULL DEFAULT '{}'::jsonb,
  active       boolean     NOT NULL DEFAULT true,
  created_at   timestamptz NOT NULL DEFAULT now()
);
--		!tracks: album, title, duration, isrc, meta_json, active, createtime;
--      !M-N tru track_artist track_genre track_vibe playlist_track, 1-N in likes_tracks, 1-N in stream_events
--! id – PK; album_id – ссылка на альбом (жёсткая связь); title – название трека; duration_sec – длительность в секундах; isrc – код записи; meta_json – произвольные метаданные; active – признак активности; created_at – дата/время создания


-- 5 Пользователи

DROP TABLE IF EXISTS users;
CREATE TABLE users (
  id            integer     NOT NULL PRIMARY KEY,
  email         text        NOT NULL UNIQUE,
  password_hash text        NOT NULL,
  nickname      text        NOT NULL,
  birth_date    date,
  phone         text,
  country_code  char(2),
  created_at    timestamptz NOT NULL DEFAULT now()
);
--! id – PK; email – уникальная почта; password_hash – хэш пароля; nickname – ник; birth_date – дата рождения; phone – телефон; country_code – ISO-2 код страны; created_at – дата/время создания


-- 6 Жанры

DROP TABLE IF EXISTS genres;
CREATE TABLE genres (
  id         integer NOT NULL PRIMARY KEY,
  name       text    NOT NULL UNIQUE,
  parent_id  integer REFERENCES genres(id)
);
--		!genres: name, link; M-N through track_genre
--! id – PK; name – уникальное имя жанра; parent_id – ссылка на родительский жанр (иерархия жанров)


-- 7 Вайб / Настроение

DROP TABLE IF EXISTS vibes;
CREATE TABLE vibes (
  id   integer NOT NULL PRIMARY KEY,
  name text    NOT NULL UNIQUE
);
--		!vibes: name; M-N tru track_vibe
--! id – PK; name – уникальное название вайба/настроения


-- 8 Планы

DROP TABLE IF EXISTS plans;
CREATE TABLE plans (
  id          integer NOT NULL PRIMARY KEY,
  name        text    NOT NULL UNIQUE,
  period      text    NOT NULL CHECK (period IN ('monthly','annual')),
  price_cents integer NOT NULL CHECK (price_cents >= 0),
  is_active   boolean NOT NULL DEFAULT true
);
--		!plans: name, period, price_cents, is_active; 1-N w subscriptions
--! id – PK; name – название тарифа; period – периодичность; price_cents – цена в центах; is_active – активен ли план


-- 9 Подписки

DROP TABLE IF EXISTS subscriptions;
CREATE TABLE subscriptions (
  id         integer     NOT NULL PRIMARY KEY,
  user_id    integer     NOT NULL REFERENCES users(id)  ON DELETE RESTRICT,
  plan_id    integer     NOT NULL REFERENCES plans(id)  ON DELETE RESTRICT,
  status     text        NOT NULL CHECK (status IN ('active','canceled','expired','trial')),
  start_at   timestamptz NOT NULL DEFAULT now(),
  end_at     timestamptz,
  auto_renew boolean     NOT NULL DEFAULT true
);
--		!subscriptions: user, plan, status, start_at, end_at, auto_renew; N-1 to users, plans; 1-N w payments
--! id – PK; user_id – владелец подписки; plan_id – план; status – статус подписки; start_at/end_at – период действия; auto_renew – автопродление


-- 10 Платежи

DROP TABLE IF EXISTS payments;
CREATE TABLE payments (
  id               integer     NOT NULL PRIMARY KEY,
  user_id          integer     NOT NULL REFERENCES users(id)         ON DELETE RESTRICT,
  subscription_id  integer              REFERENCES subscriptions(id) ON DELETE RESTRICT,
  amount_cents     integer     NOT NULL CHECK (amount_cents >= 0),
  currency         char(3)     NOT NULL DEFAULT 'USD',
  paid_at          timestamptz NOT NULL DEFAULT now(),
  method           text        NOT NULL,
  status           text        NOT NULL CHECK (status IN ('succeeded','failed','refunded','pending'))
);
--		!payments: user, subscription?, amount_cents, currency, paid_at, method, status; N-1 to users; 0..1 to subscriptions
--! id – PK; user_id – кто платил; subscription_id – к какой подписке относится; amount_cents – сумма; currency – валюта (3-симв. код); paid_at – время платежа; method – способ оплаты; status – состояние


-- 11 Плейлисты / Подборки

DROP TABLE IF EXISTS playlists;
CREATE TABLE playlists (
  id            integer     NOT NULL PRIMARY KEY,
  owner_user_id integer     NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  title         text,
  is_public     boolean     NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now()
);
--		!playlists: owner_user, title, is_public, createtime; N-1 to users; M-N tru playlist_track
--! id – PK; owner_user_id – владелец; title – название плейлиста; is_public – публичность; created_at – дата/время создания


-- 12 Связка альбом-артист

DROP TABLE IF EXISTS album_artist;
CREATE TABLE album_artist (
  album_id integer NOT NULL REFERENCES albums(id)  ON DELETE RESTRICT,
  artist_id integer NOT NULL REFERENCES artists(id) ON DELETE RESTRICT,
  role     text,
  order_no integer,
  PRIMARY KEY (album_id, artist_id)
);
--		!album_artist (M-N): album_id, artist_id, role, order_no; links albums ↔ artists
--! album_id – ссылка на альбом; artist_id – ссылка на артиста; role – роль (primary/featuring и т.п.); order_no – порядок артистов в релизе


--  13 Связка трек-артист

DROP TABLE IF EXISTS track_artist;
CREATE TABLE track_artist (
  track_id  integer NOT NULL REFERENCES tracks(id)   ON DELETE RESTRICT,
  artist_id integer NOT NULL REFERENCES artists(id)  ON DELETE RESTRICT,
  role      text,
  order_no  integer,
  PRIMARY KEY (track_id, artist_id)
);
--      !track_artist (M-N): track_id, artist_id, role, order_no; links tracks ↔ artists
--! track_id – ссылка на трек; artist_id – ссылка на артиста; role – роль артиста в треке; order_no – порядок


--  14 Связка трек-жанр

DROP TABLE IF EXISTS track_genre;
CREATE TABLE track_genre (
  track_id integer NOT NULL REFERENCES tracks(id)  ON DELETE RESTRICT,
  genre_id integer NOT NULL REFERENCES genres(id)  ON DELETE RESTRICT,
  PRIMARY KEY (track_id, genre_id)
);
--      !track_genre (M-N): track_id, genre_id; links tracks ↔ genres
--! track_id – ссылка на трек; genre_id – ссылка на жанр


--  15 Связка трек-вайб

DROP TABLE IF EXISTS track_vibe;
CREATE TABLE track_vibe (
  track_id integer NOT NULL REFERENCES tracks(id)  ON DELETE RESTRICT,
  vibe_id  integer NOT NULL REFERENCES vibes(id)   ON DELETE RESTRICT,
  PRIMARY KEY (track_id, vibe_id)
);
--      !track_vibe (M-N): track_id, vibe_id; links tracks ↔ vibes
--! track_id – ссылка на трек; vibe_id – ссылка на вайб/настроение


--  16 Связка плейлист-трек

DROP TABLE IF EXISTS playlist_track;
CREATE TABLE playlist_track (
  playlist_id integer     NOT NULL REFERENCES playlists(id) ON DELETE RESTRICT,
  track_id    integer     NOT NULL REFERENCES tracks(id)    ON DELETE RESTRICT,
  position    integer     NOT NULL CHECK (position >= 1),
  added_at    timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (playlist_id, track_id),
  UNIQUE (playlist_id, position)
);
--      !playlist_track (M-N): playlist_id, track_id, position, added_at; links playlists ↔ tracks
--! playlist_id – ссылка на плейлист; track_id – ссылка на трек; position – позиция трека в плейлисте (уникальна в рамках плейлиста); added_at – когда добавлен


--  17 Связка подписка-артист, подписки на артистов

DROP TABLE IF EXISTS follows_artists;
CREATE TABLE follows_artists (
  user_id     integer     NOT NULL REFERENCES users(id)   ON DELETE RESTRICT,
  artist_id   integer     NOT NULL REFERENCES artists(id) ON DELETE RESTRICT,
  followed_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, artist_id)
);
--      !follows_artists (M-N): user_id, artist_id, followed_at; links users ↔ artists
--! user_id – кто подписался; artist_id – на кого подписался; followed_at – время подписки


--  18 Связка лайк-трек, лайки треков

DROP TABLE IF EXISTS likes_tracks;
CREATE TABLE likes_tracks (
  user_id  integer     NOT NULL REFERENCES users(id)  ON DELETE RESTRICT,
  track_id integer     NOT NULL REFERENCES tracks(id) ON DELETE RESTRICT,
  liked_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, track_id)
);
--      !likes_tracks (M-N): user_id, track_id, liked_at; links users ↔ tracks
--! user_id – кто лайкнул; track_id – какой трек лайкнули; liked_at – когда


--	19 Уведомления

DROP TABLE IF EXISTS notifications;
CREATE TABLE notifications (
  id           integer     NOT NULL PRIMARY KEY,
  user_id      integer     NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  kind         text        NOT NULL,
  payload_json jsonb       NOT NULL DEFAULT '{}'::jsonb,
  created_at   timestamptz NOT NULL DEFAULT now(),
  read_at      timestamptz
);
--		!notifications: user_id, kind, payload_json, created_at, read_at; N-1 to users
--! id – PK; user_id – кому адресовано; kind – тип/категория уведомления; payload_json – полезная нагрузка; created_at – когда создано; read_at – когда прочитано


--	20 Стримы / Прослушивания

DROP TABLE IF EXISTS stream_events;
CREATE TABLE stream_events (
  id              integer     NOT NULL PRIMARY KEY,
  user_id         integer              REFERENCES users(id)  ON DELETE RESTRICT,
  track_id        integer              REFERENCES tracks(id) ON DELETE RESTRICT,
  started_at      timestamptz NOT NULL DEFAULT now(),
  seconds_played  integer     NOT NULL CHECK (seconds_played >= 0),
  device_type     text,
  client_meta_json jsonb      NOT NULL DEFAULT '{}'::jsonb
);
--		!stream_events(прослушивания/стримы): user_id?, track_id?, started_at, seconds_played, device_type, client_meta_json; 0..N to users, tracks (facts/logs)
--! id – PK; user_id/track_id – кто слушал и что (связь может отсутствовать для анонимного/тестового события); started_at – время начала; seconds_played – длительность; device_type – тип устройства; client_meta_json – метаданные клиента


--	21 Запросы в поиске

DROP TABLE IF EXISTS search_queries;
CREATE TABLE search_queries (
  id          integer     NOT NULL PRIMARY KEY,
  user_id     integer              REFERENCES users(id) ON DELETE RESTRICT,
  query       text        NOT NULL,
  searched_at timestamptz NOT NULL DEFAULT now()
);
--		!search_queries(запросы в поиске): user_id?, query, searched_at; 0..N to users (logs)
--! id – PK; user_id – кто вводил запрос (может быть пусто, если нет авторизации); query – текст запроса; searched_at – когда искали


-- 22 Показы рекомендаций

DROP TABLE IF EXISTS recommendation_impressions;
CREATE TABLE recommendation_impressions (
  id         integer     NOT NULL PRIMARY KEY,
  user_id    integer     NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  session_id text,
  surface    text,
  item_type  text        NOT NULL CHECK (item_type IN ('track','album','playlist','artist')),
  item_id    integer     NOT NULL,
  position   integer               CHECK (position IS NULL OR position >= 1),
  shown_at   timestamptz NOT NULL DEFAULT now(),
  clicked    boolean     NOT NULL DEFAULT false,
  dismissed  boolean     NOT NULL DEFAULT false
);
--		!recommendation_impressions (показы рекомендаций): user_id, session_id, surface, item_type ('track'|'album'|'playlist'|'artist'), item_id, position, shown_at, clicked, dismissed; N-1 to users; polymorphic ref to content
--! id – PK; user_id – кто видел рекомендацию; session_id – идентификатор сессии; surface – место в интерфейсе; item_type – тип показанного объекта; item_id – id объекта; position – позиция в выдаче; shown_at – время показа; clicked/dismissed – реакция



--! Create index - accelerate filters & connections on columns
--! Using gin - gin-indexes for 'jsonb' for quick search by operators
CREATE INDEX idx_albums_label ON albums(label_id);
CREATE INDEX idx_tracks_album ON tracks(album_id);
CREATE INDEX idx_album_artist_artist ON album_artist(artist_id);
CREATE INDEX idx_track_artist_artist ON track_artist(artist_id);
CREATE INDEX idx_track_genre_genre ON track_genre(genre_id);
CREATE INDEX idx_track_vibe_vibe ON track_vibe(vibe_id);
CREATE INDEX idx_playlist_track_track ON playlist_track(track_id);
CREATE INDEX idx_follows_artists_artist ON follows_artists(artist_id);
CREATE INDEX idx_likes_tracks_track ON likes_tracks(track_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_stream_events_user ON stream_events(user_id);
CREATE INDEX idx_stream_events_track ON stream_events(track_id);
CREATE INDEX idx_stream_events_started_at ON stream_events(started_at);
CREATE INDEX idx_search_queries_user ON search_queries(user_id);
CREATE INDEX idx_search_queries_searched_at ON search_queries(searched_at);
CREATE INDEX idx_rec_impr_user_shown ON recommendation_impressions(user_id, shown_at);
CREATE INDEX idx_release_poly ON recommendation_impressions(item_type, item_id);
CREATE INDEX idx_release_sched_poly ON search_queries(id);
CREATE INDEX idx_tracks_meta_gin ON tracks USING gin (meta_json);
CREATE INDEX idx_stream_client_meta_gin ON stream_events USING gin (client_meta_json);






/*
	VIEWs
*/

-- просто VIEW это виртуальная сохраненная выборка, она не хранит данных и каждый реквест к ней просто заново выполняет ее SELECT
-- MATERIALIZED VIEW хранит снимок результата как таблицу, исходный реквест запоминается и дату нужно обновлять REFRESH



-- 1 Представление, именованный SELECT: оно объединяет треки с альбомами, артистами, жанрами и вайбом;
-- оно не хранит данные, каждый раз при обращении Postgres выполняет заложенный запрос поверх живых таблиц
CREATE OR REPLACE VIEW v_tracks_artists_genres AS
SELECT
  t.id     AS track_id,
  t.title  AS track_title,
  al.title AS album_title,
  COALESCE(STRING_AGG(a.name, ', ' ORDER BY ta.order_no), '') AS artists,
  COALESCE(STRING_AGG(DISTINCT g.name, ', '), '')             AS genres,
  COALESCE(STRING_AGG(DISTINCT v.name, ', '), '')             AS vibes
FROM tracks t
LEFT JOIN albums       al ON al.id = t.album_id
LEFT JOIN track_artist ta ON ta.track_id = t.id
LEFT JOIN artists      a  ON a.id = ta.artist_id
LEFT JOIN track_genre  tg ON tg.track_id = t.id
LEFT JOIN genres       g  ON g.id = tg.genre_id
LEFT JOIN track_vibe   tv ON tv.track_id = t.id
LEFT JOIN vibes        v  ON v.id = tv.vibe_id
GROUP BY t.id, t.title, al.title;
-- -- check
-- SELECT * FROM v_tracks_artists_genres ORDER BY track_id;

-- !Задача: собрать по каждому треку связанный контент — альбом, артистов, жанры и вайбы — в одну строку.
-- !Как работает:
-- !• LEFT JOIN берёт все треки, даже если по ним нет артистов/жанров/вайбов.
-- !• STRING_AGG(a.name, ', ' ORDER BY ta.order_no) склеивает имена артистов в нужном порядке.
-- !• DISTINCT в STRING_AGG для жанров/вайбов убирает дубликаты, возникающие из-за соединений.
-- !• COALESCE(..., '') превращает возможный NULL из агрегатов в пустую строку (удобно для UI/отчётов).
-- !• GROUP BY t.id, t.title, al.title делает по одной строке на трек (агрегируя множественные связи).


-- 1 Мат представление, топ-треки за 30 дней по времени прослушивания

CREATE MATERIALIZED VIEW mv_top_tracks_30d AS
WITH base AS (
  SELECT
    t.id    AS track_id,
    t.title AS track_title,
    CASE WHEN COUNT(se.seconds_played) = 0
         THEN 0
         ELSE SUM(se.seconds_played)
    END AS seconds_sum,
    COUNT(se.id) AS plays_count
  FROM tracks t
  LEFT JOIN stream_events se
    ON se.track_id = t.id
   AND se.started_at >= now() - interval '30 days'
  GROUP BY t.id, t.title
)
SELECT
  *,
  RANK() OVER (ORDER BY seconds_sum DESC, plays_count DESC) AS rnk
FROM base;

CREATE UNIQUE INDEX ux_mv_top_tracks_30d_track ON mv_top_tracks_30d(track_id);

-- -- check
-- SELECT track_title, seconds_sum, plays_count, rnk
-- FROM mv_top_tracks_30d
-- ORDER BY rnk
-- LIMIT 10;

-- !Задача: за последние 30 дней посчитать для каждого трека суммарное время прослушивания и число прослушиваний,
-- !        затем присвоить место в рейтинге.
-- !Как работает:
-- ! • WITH base AS (...) — CTE: «временная» таблица внутри запроса, чтобы логику было проще читать/переиспользовать.
-- ! • LEFT JOIN оставляет трек в выборке даже без событий прослушивания.
-- ! • SUM(se.seconds_played) даёт total-секунды; COUNT(se.id) FILTER (WHERE se.id IS NOT NULL) считает только реальные события.
-- !   (Когда прослушиваний нет, SUM даёт NULL — его далее удобно заменять на 0 при выводе, если нужно.)
-- ! • RANK() OVER (ORDER BY seconds_sum DESC, plays_count DESC) присваивает рейтинг; равные значения получают одинаковый ранг.
-- ! • UNIQUE-индекс по track_id ускоряет последующие JOIN’ы к матпредставлению и гарантирует один ряд на трек.
-- ! • Обновление: REFRESH MATERIALIZED VIEW mv_top_tracks_30d (по расписанию или вручную, чтобы данные стали актуальными).

-- .............................................................
-- .............................................................
-- .............................................................
-- .............................................................
-- .............................................................


-- Query SQL

-- .............................................................
-- .............................................................
-- .............................................................
-- .............................................................
-- .............................................................

-- DO $$ ' END $$; to delete empty queries
DO $$
BEGIN

/*
	TEST DATA
*/

-- Пример реальных данных
INSERT INTO labels (id,name,contact_email) VALUES
 (90100,'Universal Music Group','contact@universal-music-group.example'),
 (90101,'Sony Music Entertainment','contact@sony-music-entertainment.example'),
 (90102,'Warner Music Group','contact@warner-music-group.example'),
 (90103,'Columbia Records','contact@columbia-records.example'),
 (90104,'RCA Records','contact@rca-records.example'),
 (90105,'Atlantic Records','contact@atlantic-records.example'),
 (90106,'Capitol Records','contact@capitol-records.example'),
 (90107,'Interscope Records','contact@interscope-records.example'),
 (90108,'Republic Records','contact@republic-records.example'),
 (90109,'Def Jam Recordings','contact@def-jam-recordings.example'),
 (90110,'Island Records','contact@island-records.example'),
 (90111,'Epic Records','contact@epic-records.example'),
 (90112,'Sub Pop','contact@sub-pop.example'),
 (90113,'XL Recordings','contact@xl-recordings.example'),
 (90114,'Domino Recording Company','contact@domino-recording-company.example'),
 (90115,'4AD','contact@4ad.example'),
 (90116,'Ninja Tune','contact@ninja-tune.example'),
 (90117,'Matador Records','contact@matador-records.example'),
 (90118,'Epitaph Records','contact@epitaph-records.example'),
 (90119,'Warp Records','contact@warp-records.example')
ON CONFLICT DO NOTHING;

INSERT INTO plans (id,name,period,price_cents,is_active) VALUES
 (90200,'Free','monthly',0,true),
 (90201,'Individual','monthly',1199,true),
 (90202,'Student','monthly',599,true),
 (90203,'Duo','monthly',1699,true),
 (90204,'Family','monthly',1999,true),
 (90205,'HiFi','monthly',1499,true),
 (90206,'HiFi Plus','monthly',1999,true),
 (90207,'Single Device','monthly',799,true)
ON CONFLICT DO NOTHING;

INSERT INTO genres (id,name,parent_id) VALUES
 (90300,'Pop',NULL),
 (90301,'Rock',NULL),
 (90302,'Hip Hop',NULL),
 (90303,'R&B',NULL),
 (90304,'Electronic',NULL),
 (90305,'Dance',NULL),
 (90306,'House',NULL),
 (90307,'Techno',NULL),
 (90308,'Jazz',NULL),
 (90309,'Blues',NULL),
 (90310,'Country',NULL),
 (90311,'Folk',NULL),
 (90312,'Classical',NULL),
 (90313,'Reggae',NULL),
 (90314,'Latin',NULL),
 (90315,'Afrobeat',NULL),
 (90316,'K-Pop',NULL),
 (90317,'Metal',NULL),
 (90318,'Punk',NULL),
 (90319,'Soul',NULL),
 (90320,'Funk',NULL),
 (90321,'Indie',NULL),
 (90322,'Alternative',NULL),
 (90323,'Gospel',NULL),
 (90324,'Trap',NULL),
 (90325,'Drill',NULL),
 (90326,'Dubstep',NULL),
 (90327,'Drum and Bass',NULL)
ON CONFLICT DO NOTHING;

INSERT INTO vibes (id,name) VALUES
 (90400,'peaceful'),
 (90401,'happy'),
 (90402,'sad'),
 (90403,'energetic'),
 (90404,'dreamy'),
 (90405,'dark'),
 (90406,'romantic'),
 (90407,'mellow'),
 (90408,'melancholic'),
 (90409,'upbeat'),
 (90410,'moody'),
 (90411,'aggressive'),
 (90412,'introspective'),
 (90413,'playful'),
 (90414,'relaxed'),
 (90415,'uplifting'),
 (90416,'wistful'),
 (90417,'brooding'),
 (90418,'seductive'),
 (90419,'atmospheric')
ON CONFLICT DO NOTHING;

-- Пример синтетики 
INSERT INTO artists (id,name,aka,country_code)
SELECT 93000+i,
       'Artist '||i,
       CASE WHEN i%5=0 THEN 'AKA '||i ELSE NULL END,
       (ARRAY['US','GB','DE','FR','JP','BR','CA','AU','KR','SE'])[(i%10)+1]
FROM generate_series(1,50) s(i)
ON CONFLICT DO NOTHING;

INSERT INTO albums (id,title,release_date,upc,label_id)
SELECT 94000+i,
       'Album '||i,
       DATE '2018-01-01' + (i%200),
       'UPC-'||to_char(94000+i,'FM000000'),
       90100 + (i%20)
FROM generate_series(1,60) s(i)
ON CONFLICT DO NOTHING;

INSERT INTO tracks (id,album_id,title,duration_sec,isrc,meta_json,active)
SELECT 95000+i,
       94000 + 1 + ((i-1)%60),
       'Track '||i,
       120 + (i%240),
       'ISRC-'||to_char(95000+i,'FM000000'),
       jsonb_build_object('bitrate',(ARRAY[128,192,256,320])[(i%4)+1],
                          'lang',(ARRAY['en','es','fr','de'])[(i%4)+1]),
       true
FROM generate_series(1,300) s(i)
ON CONFLICT DO NOTHING;

INSERT INTO users (id,email,password_hash,nickname,birth_date,phone,country_code)
SELECT 96000+i,
       'u'||(96000+i)||'@example.com',
       'hash-'||(96000+i),
       'user_'||i,
       DATE '1980-01-01' + (i%12000),
       '+1555'||lpad(i::text,4,'0'),
       (ARRAY['US','GB','CA','DE','FR','AU','BR','JP','SE','RU'])[(i%10)+1]
FROM generate_series(1,60) s(i)
ON CONFLICT DO NOTHING;

INSERT INTO subscriptions (id,user_id,plan_id,status,start_at,end_at,auto_renew)
SELECT 96500+i,
       96000+i,
       90200 + (i%8),
       'active',
       now() - (i||' days')::interval,
       NULL,
       (i%2=0)
FROM generate_series(1,48) s(i)
ON CONFLICT DO NOTHING;

INSERT INTO payments (id,user_id,subscription_id,amount_cents,currency,paid_at,method,status)
SELECT 96600+i,
       96000+i,
       96500+i,
       (ARRAY[0,1199,599,1699,1999,1499,1999,799])[(i%8)+1],
       'USD',
       now() - (i||' days')::interval,
       (ARRAY['card','paypal','apple_pay','google_pay'])[(i%4)+1],
       'succeeded'
FROM generate_series(1,48) s(i)
ON CONFLICT DO NOTHING;

INSERT INTO playlists (id,owner_user_id,title,is_public)
SELECT 97000+i,
       96000 + ((i-1)%60)+1,
       'Playlist '||i,
       (i%3=0)
FROM generate_series(1,50) s(i)
ON CONFLICT DO NOTHING;

INSERT INTO album_artist (album_id,artist_id,role,order_no)
SELECT 94000+i, 93000 + ((i-1)%50)+1, 'primary', 1
FROM generate_series(1,60) s(i)
UNION ALL
SELECT 94000 + ((i-1)%60)+1, 93000 + ((i+7)%50)+1, 'featuring', 2
FROM generate_series(1,6) s(i)
ON CONFLICT DO NOTHING;

INSERT INTO track_artist (track_id,artist_id,role,order_no)
SELECT 95000+i, 93000 + ((i-1)%50)+1, 'primary', 1
FROM generate_series(1,300) s(i)
UNION ALL
SELECT 95000 + ((i-1)%300)+1, 93000 + ((i+13)%50)+1, 'featuring', 2
FROM generate_series(1,90) s(i)
ON CONFLICT DO NOTHING;

INSERT INTO track_genre (track_id,genre_id)
SELECT 95000+i, 90300 + (i%28)
FROM generate_series(1,300) s(i)
UNION ALL
SELECT 95000 + ((i-1)%300)+1, 90300 + ((i+7)%28)
FROM generate_series(1,30) s(i)
ON CONFLICT DO NOTHING;

INSERT INTO track_vibe (track_id,vibe_id)
SELECT 95000+i, 90400 + (i%20)
FROM generate_series(1,300) s(i)
ON CONFLICT DO NOTHING;

INSERT INTO playlist_track (playlist_id,track_id,position,added_at)
SELECT 97000 + ((i-1)%50)+1,
       95000 + ((i-1)%300)+1,
       1 + ((i-1)%25),
       now() - ((i%90)||' minutes')::interval
FROM generate_series(1,1000) s(i)
ON CONFLICT DO NOTHING;

INSERT INTO follows_artists (user_id,artist_id,followed_at)
SELECT 96000 + ((i-1)%60)+1,
       93000 + ((i*3)%50)+1,
       now() - ((i%45)||' days')::interval
FROM generate_series(1,240) s(i)
ON CONFLICT DO NOTHING;

INSERT INTO likes_tracks (user_id,track_id,liked_at)
SELECT 96000 + ((i-1)%60)+1,
       95000 + ((i*7)%300)+1,
       now() - ((i%60)||' hours')::interval
FROM generate_series(1,600) s(i)
ON CONFLICT DO NOTHING;

INSERT INTO notifications (id,user_id,kind,payload_json,created_at,read_at)
SELECT 98000+i,
       96000 + ((i-1)%60)+1,
       (ARRAY['system','promo','alert'])[(i%3)+1],
       jsonb_build_object('msg','n'||i),
       now() - ((i%72)||' hours')::interval,
       CASE WHEN i%5=0 THEN now() - ((i%36)||' hours')::interval ELSE NULL END
FROM generate_series(1,120) s(i)
ON CONFLICT DO NOTHING;

INSERT INTO stream_events (id,user_id,track_id,started_at,seconds_played,device_type,client_meta_json)
SELECT 98100+i,
       96000 + ((i-1)%60)+1,
       95000 + (1 + floor(random()*300))::int,
       now() - ((i%10080)||' minutes')::interval,
       30 + (i%240),
       (ARRAY['mobile','desktop','web','car','tv'])[(i%5)+1],
       jsonb_build_object('app','web','ver',1+(i%3))
FROM generate_series(1,4000) s(i)
ON CONFLICT DO NOTHING;

INSERT INTO search_queries (id,user_id,query,searched_at)
SELECT 98200+i,
       96000 + ((i-1)%60)+1,
       'query '||i,
       now() - ((i%1440)||' minutes')::interval
FROM generate_series(1,180) s(i)
ON CONFLICT DO NOTHING;

INSERT INTO recommendation_impressions (id,user_id,session_id,surface,item_type,item_id,position,shown_at,clicked,dismissed)
SELECT 99000+i,
       96000 + ((i-1)%60)+1,
       'sess-'||(96000 + ((i-1)%60)+1)||'-'||((i-1)/20),
       (ARRAY['home','artist','album','search'])[(i%4)+1],
       'track',
       95000 + (1 + floor(random()*300))::int,
       1 + ((i-1)%20),
       now() - ((i%720)||' minutes')::interval,
       (i%10=0),
       (i%7=0)
FROM generate_series(1,3000) s(i)
ON CONFLICT DO NOTHING;

END $$;

-- .............................................................
-- .............................................................
-- .............................................................
-- .............................................................
-- .............................................................

-- Базовые запросы по количеству строк в таблицах
SELECT COUNT(*) AS counter FROM users;
SELECT COUNT(*) AS counter FROM artists;
SELECT COUNT(*) AS counter FROM albums;
SELECT COUNT(*) AS counter FROM tracks;
SELECT COUNT(*) AS counter FROM labels;
SELECT COUNT(*) AS counter FROM payments;
SELECT COUNT(*) AS counter FROM subscriptions;
SELECT COUNT(*) AS counter FROM playlists;
SELECT COUNT(*) AS counter FROM stream_events;
SELECT COUNT(*) AS counter FROM search_queries;


-- 1 Активные планы с ценой в долларах
SELECT id, name, period, price_cents/100.0 AS price_usd
FROM plans
WHERE is_active = true
ORDER BY price_cents;

-- 2 Топ-10 треков по прослушанному времени за 30 дней
SELECT tracks.id,
       tracks.title,
       SUM(stream_events.seconds_played) AS sec_played_30d
FROM stream_events
JOIN tracks ON tracks.id = stream_events.track_id
WHERE stream_events.started_at >= now() - INTERVAL '30 days'
GROUP BY tracks.id, tracks.title
ORDER BY sec_played_30d DESC
LIMIT 10;

-- 3 Самые добавляемые треки в плейлисты за 90 дней
SELECT tracks.id,
       tracks.title,
       COUNT(*) AS add_cnt_90d
FROM playlist_track
JOIN tracks ON tracks.id = playlist_track.track_id
WHERE playlist_track.added_at >= now() - INTERVAL '90 days'
GROUP BY tracks.id, tracks.title
ORDER BY add_cnt_90d DESC
LIMIT 10;

-- 4 Топ-артисты по прослушанному времени
SELECT artists.id   AS artist_id,
       artists.name AS artist,
       SUM(stream_events.seconds_played) AS sec_played
FROM stream_events
JOIN track_artist ON track_artist.track_id = stream_events.track_id
JOIN artists      ON artists.id = track_artist.artist_id
GROUP BY artists.id, artists.name
ORDER BY sec_played DESC
LIMIT 10;

-- 5 Пользователи с авто-продлением и активной подпиской
SELECT subscriptions.id   AS subscription_id,
       users.id           AS user_id,
       users.email,
       plans.name         AS plan_name,
       subscriptions.start_at,
       subscriptions.end_at
FROM subscriptions
JOIN users ON users.id = subscriptions.user_id
JOIN plans ON plans.id = subscriptions.plan_id
WHERE subscriptions.status = 'active'
  AND subscriptions.auto_renew = true
ORDER BY subscriptions.start_at DESC;

-- 6 Представления 
REFRESH MATERIALIZED VIEW mv_top_tracks_30d;
SELECT * FROM mv_top_tracks_30d ORDER BY rnk LIMIT 10;

SELECT * FROM v_tracks_artists_genres ORDER BY track_id LIMIT 10;


-- Сложный запрос ' Топ-3 фаната каждого артиста (лимит=10, но можно убрать) за текущий месяц по времени прослушивания его композиций
-- Сортировка артистов по возрастанию id + Сортировка внутри артиста фанатов по убыванию их прослушивания

--! берём события стриминга только за текущий календарный месяц */
WITH month_streams AS (
  SELECT
    stream_events.user_id,
    stream_events.track_id,
    stream_events.seconds_played
  FROM stream_events
  WHERE stream_events.started_at >= date_trunc('month', now())
),

--! считаем, сколько секунд каждый пользователь наслушал у каждого артиста */
artist_user AS (
  SELECT
    track_artist.artist_id,
    month_streams.user_id,
    SUM(month_streams.seconds_played) AS sec_played
  FROM month_streams
  JOIN track_artist
    ON track_artist.track_id = month_streams.track_id
  GROUP BY
    track_artist.artist_id,
    month_streams.user_id
),

--! ранжируем пользователей внутри каждого артиста по секундам (по убыванию) */
ranked AS (
  SELECT
    artist_user.artist_id,
    artist_user.user_id,
    artist_user.sec_played,
    ROW_NUMBER() OVER (
      PARTITION BY artist_user.artist_id
      ORDER BY artist_user.sec_played DESC
    ) AS rn
  FROM artist_user
),

--! ограничиваемся первыми 10 артистами по их id */
top_artists AS (
  SELECT artists.id
  FROM artists
  ORDER BY artists.id
  LIMIT 10
)

--! итог — для каждого из 10 артистов берём топ-3 пользователей и сортируем сначала по артисту, затем по секундам внутри артиста */
SELECT
  artists.id   AS artist_id,
  artists.name AS artist,
  ranked.user_id,
  ranked.sec_played
FROM ranked
JOIN artists
  ON artists.id = ranked.artist_id
JOIN top_artists
  ON top_artists.id = ranked.artist_id
WHERE ranked.rn <= 3
ORDER BY
  artists.id,
  ranked.sec_played DESC;

-- .............................................................
-- .............................................................
-- .............................................................
-- .............................................................
-- .............................................................

COMMIT;
