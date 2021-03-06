#!/bin/bash

psql <<EOF
create schema if not exists aoc2018;
drop table if exists aoc2018.input03;
create table aoc2018.input03 (rowid serial, a text);
EOF

#psql -c 'copy aoc2018.input03(a) from stdin;' < sample0.txt
psql -c 'copy aoc2018.input03(a) from stdin;' < input

psql <<EOF
with claims as (
  select
    rowid
    , a
    , x0
    , y0
    , x1
    , y1
    , row_number() over (order by x0, x1, y0, y1) rn
  from (
    select
      rowid
      , a
      , b[3]::int x0
      , b[4]::int y0
      , b[6]::int w
      , b[7]::int h
      , b[3]::int + b[6]::int - 1 x1
      , b[4]::int + b[7]::int - 1 y1
    from (
      select
        rowid
        , a
        , regexp_split_to_array(a, '[ ,:x]') b
      from aoc2018.input03
    ) x
  ) x
)
, find_overlaps as (
  select
    a.a a
    , a.x0 ax0
    , a.y0 ay0
    , a.x1 ax1
    , a.y1 ay1
    , b.a b
    , b.x0 bx0
    , b.y0 by0
    , b.x1 bx1
    , b.y1 by1
    , case
      when a.x1 >= b.x0
        and a.x0 <= b.x1
        and a.y1 >= b.y0
        and a.y0 <= b.y1
      then 1 else 0 end
    overlap
  from claims a
  inner join claims b
    on a.rowid < b.rowid
    -- and a.x0 <= b.x0
    -- and a.y0 <= b.y0
)
, overlapping_claims as (
  select
    a
    , b
    , case when bx0 between ax0 and ax1 then bx0 else ax0 end x0
    , case when bx1 between ax0 and ax1 then bx1 else ax1 end x1
    , case when by0 between ay0 and ay1 then by0 else ay0 end y0
    , case when by1 between ay0 and ay1 then by1 else ay1 end y1
  from find_overlaps x
  where overlap = 1
)
, unique_overlapping_claims as (
  select distinct
    x
    , y
    -- , generate_series(x0, x1) x , generate_series(y0, y1) y
  from overlapping_claims oc
  inner join generate_series(x0, x1) x
    on x between oc.x0 and oc.x1
  inner join generate_series(y0, y1) y
    on y between oc.y0 and oc.y1
)
select count(*) part_1 from unique_overlapping_claims
--select * from find_overlaps
;
EOF

psql <<EOF
with claims as (
  select
    rowid
    , a
    , x0
    , y0
    , x1
    , y1
    , row_number() over (order by x0, x1, y0, y1) rn
  from (
    select
      rowid
      , a
      , b[3]::int x0
      , b[4]::int y0
      , b[6]::int w
      , b[7]::int h
      , b[3]::int + b[6]::int - 1 x1
      , b[4]::int + b[7]::int - 1 y1
    from (
      select
        rowid
        , a
        , regexp_split_to_array(a, '[ ,:x]') b
      from aoc2018.input03
    ) x
  ) x
)
, find_overlaps as (
  select
    a.a a
    , a.x0 ax0
    , a.y0 ay0
    , a.x1 ax1
    , a.y1 ay1
    , b.a b
    , b.x0 bx0
    , b.y0 by0
    , b.x1 bx1
    , b.y1 by1
    , case
      when a.x1 >= b.x0
        and a.x0 <= b.x1
        and a.y1 >= b.y0
        and a.y0 <= b.y1
      then 1 else 0 end
    overlap
  from claims a
  inner join claims b
    on a.rowid <> b.rowid
    -- and a.x0 <= b.x0
    -- and a.y0 <= b.y0
)
select
  a part_2
from find_overlaps
group by a
having sum(overlap) = 0
;
EOF

