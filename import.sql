create table users(
    id integer primary key,
    name text,
    password text,
    role_id integer,
    win_count integer,
    is_entry boolean,
    dead_count integer
);

create table roles(
    id integer primary key,
    role_name text,
    action_order integer
);

INSERT INTO roles
    SELECT 1, '村人', 0
    UNION ALL SELECT 2, '人狼', 2
    UNION ALL SELECT 3, 'ボディガード', 1
    UNION ALL SELECT 4, '占い師', 3;

create table players(
  id integer primary key,
  user_id integer,
  name text,
  role integer,
  votes_count integer,
  is_saved boolean,
  is_dead boolean
);
