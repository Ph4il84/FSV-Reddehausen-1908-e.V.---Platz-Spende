-- ============================================================
-- Schema für "FSV Reddehausen 1908 e.V. – Platz-Spende"
-- In Supabase: Projekt anlegen -> SQL Editor -> dieses Skript einfügen -> Run
-- ============================================================

create table if not exists public.fields (
  id text primary key,
  kind text not null,
  row_num int not null,
  col_num int not null,
  colspan int not null default 1,
  rowspan int not null default 1,
  price int not null,
  size text not null,
  special boolean not null default false,
  status text not null default 'frei' check (status in ('frei','reserviert','verkauft')),
  sponsor text,
  logo_url text,
  pending_name text,
  pending_email text,
  updated_at timestamptz not null default now()
);

alter table public.fields enable row level security;

-- Jeder darf den Platz sehen (öffentliche Startseite)
drop policy if exists "Felder sind öffentlich lesbar" on public.fields;
create policy "Felder sind öffentlich lesbar"
  on public.fields for select
  to anon, authenticated
  using (true);

-- Direktes UPDATE/INSERT/DELETE ist für anonyme Besucher NICHT erlaubt.
-- Reservieren läuft ausschließlich über die Funktion reserve_field() unten,
-- damit niemand per Browser-Konsole ein Feld auf "verkauft" setzen kann.

-- Der Admin (eingeloggt über Supabase Auth) darf alles ändern.
drop policy if exists "Eingeloggte Admins duerfen Felder aendern" on public.fields;
create policy "Eingeloggte Admins duerfen Felder aendern"
  on public.fields for update
  to authenticated
  using (true)
  with check (true);

-- ------------------------------------------------------------
-- Funktion: sicheres Reservieren durch Besucher
-- ------------------------------------------------------------
create or replace function public.reserve_field(p_id text, p_name text, p_email text)
returns public.fields
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.fields;
begin
  if p_name is null or length(trim(p_name)) = 0 then
    raise exception 'Name fehlt.';
  end if;
  if p_email is null or length(trim(p_email)) = 0 then
    raise exception 'E-Mail fehlt.';
  end if;

  update public.fields
  set status = 'reserviert',
      pending_name = trim(p_name),
      pending_email = trim(p_email),
      updated_at = now()
  where id = p_id and status = 'frei'
  returning * into result;

  if not found then
    raise exception 'Dieses Feld ist nicht mehr frei.';
  end if;

  return result;
end;
$$;

grant execute on function public.reserve_field(text, text, text) to anon, authenticated;

-- ------------------------------------------------------------
-- Realtime aktivieren, damit alle Besucher Änderungen live sehen
-- ------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'fields'
  ) then
    alter publication supabase_realtime add table public.fields;
  end if;
end $$;

-- ------------------------------------------------------------
-- Storage-Bucket für Sponsoren-Logos
-- ------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('logos', 'logos', true)
on conflict (id) do nothing;

drop policy if exists "Logos sind oeffentlich lesbar" on storage.objects;
create policy "Logos sind oeffentlich lesbar"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'logos');

drop policy if exists "Eingeloggte Admins duerfen Logos hochladen" on storage.objects;
create policy "Eingeloggte Admins duerfen Logos hochladen"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'logos');

drop policy if exists "Eingeloggte Admins duerfen Logos ersetzen" on storage.objects;
create policy "Eingeloggte Admins duerfen Logos ersetzen"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'logos');

-- ------------------------------------------------------------
-- Felder befüllen (einmalig, 97 Felder: 92 Standard, 4 Elfmeter, 1 Mittelkreis)
-- ------------------------------------------------------------
insert into public.fields (id, kind, row_num, col_num, colspan, rowspan, price, size, special, status) values
('1', 'Standardfeld', 1, 1, 1, 1, 100, '1 Feld', false, 'frei'),
('2', 'Standardfeld', 1, 2, 1, 1, 100, '1 Feld', false, 'frei'),
('3', 'Standardfeld', 1, 3, 1, 1, 100, '1 Feld', false, 'frei'),
('4', 'Standardfeld', 1, 4, 1, 1, 100, '1 Feld', false, 'frei'),
('5', 'Standardfeld', 1, 5, 1, 1, 100, '1 Feld', false, 'frei'),
('6', 'Standardfeld', 1, 6, 1, 1, 100, '1 Feld', false, 'frei'),
('7', 'Standardfeld', 1, 7, 1, 1, 100, '1 Feld', false, 'frei'),
('8', 'Standardfeld', 1, 8, 1, 1, 100, '1 Feld', false, 'frei'),
('9', 'Standardfeld', 1, 9, 1, 1, 100, '1 Feld', false, 'frei'),
('10', 'Standardfeld', 1, 10, 1, 1, 100, '1 Feld', false, 'frei'),
('11', 'Standardfeld', 2, 1, 1, 1, 100, '1 Feld', false, 'frei'),
('12', 'Standardfeld', 2, 2, 1, 1, 100, '1 Feld', false, 'frei'),
('13', 'Standardfeld', 2, 3, 1, 1, 100, '1 Feld', false, 'frei'),
('14', 'Standardfeld', 2, 4, 1, 1, 100, '1 Feld', false, 'frei'),
('E1', 'Elfmeterpunkt 1', 5, 2, 1, 1, 60, '1 Feld (Teil Sonderfläche)', true, 'frei'),
('E2', 'Elfmeterpunkt 1', 6, 2, 1, 1, 60, '1 Feld (Teil Sonderfläche)', true, 'frei'),
('15', 'Standardfeld', 2, 7, 1, 1, 100, '1 Feld', false, 'frei'),
('16', 'Standardfeld', 2, 8, 1, 1, 100, '1 Feld', false, 'frei'),
('17', 'Standardfeld', 2, 9, 1, 1, 100, '1 Feld', false, 'frei'),
('18', 'Standardfeld', 2, 10, 1, 1, 100, '1 Feld', false, 'frei'),
('19', 'Standardfeld', 3, 1, 1, 1, 100, '1 Feld', false, 'frei'),
('20', 'Standardfeld', 3, 2, 1, 1, 100, '1 Feld', false, 'frei'),
('21', 'Standardfeld', 3, 3, 1, 1, 100, '1 Feld', false, 'frei'),
('22', 'Standardfeld', 3, 4, 1, 1, 100, '1 Feld', false, 'frei'),
('23', 'Standardfeld', 3, 5, 1, 1, 100, '1 Feld', false, 'frei'),
('24', 'Standardfeld', 3, 6, 1, 1, 100, '1 Feld', false, 'frei'),
('25', 'Standardfeld', 3, 7, 1, 1, 100, '1 Feld', false, 'frei'),
('26', 'Standardfeld', 3, 8, 1, 1, 100, '1 Feld', false, 'frei'),
('27', 'Standardfeld', 3, 9, 1, 1, 100, '1 Feld', false, 'frei'),
('28', 'Standardfeld', 3, 10, 1, 1, 100, '1 Feld', false, 'frei'),
('29', 'Standardfeld', 4, 1, 1, 1, 100, '1 Feld', false, 'frei'),
('30', 'Standardfeld', 4, 2, 1, 1, 100, '1 Feld', false, 'frei'),
('31', 'Standardfeld', 4, 3, 1, 1, 100, '1 Feld', false, 'frei'),
('32', 'Standardfeld', 4, 4, 1, 1, 100, '1 Feld', false, 'frei'),
('33', 'Standardfeld', 4, 5, 1, 1, 100, '1 Feld', false, 'frei'),
('34', 'Standardfeld', 4, 6, 1, 1, 100, '1 Feld', false, 'frei'),
('35', 'Standardfeld', 4, 7, 1, 1, 100, '1 Feld', false, 'frei'),
('36', 'Standardfeld', 4, 8, 1, 1, 100, '1 Feld', false, 'frei'),
('37', 'Standardfeld', 4, 9, 1, 1, 100, '1 Feld', false, 'frei'),
('38', 'Standardfeld', 4, 10, 1, 1, 100, '1 Feld', false, 'frei'),
('39', 'Standardfeld', 5, 1, 1, 1, 100, '1 Feld', false, 'frei'),
('40', 'Standardfeld', 5, 2, 1, 1, 100, '1 Feld', false, 'frei'),
('41', 'Standardfeld', 5, 3, 1, 1, 100, '1 Feld', false, 'frei'),
('42', 'Standardfeld', 5, 4, 1, 1, 100, '1 Feld', false, 'frei'),
('43', 'Standardfeld', 5, 7, 1, 1, 100, '1 Feld', false, 'frei'),
('44', 'Standardfeld', 5, 8, 1, 1, 100, '1 Feld', false, 'frei'),
('45', 'Standardfeld', 5, 9, 1, 1, 100, '1 Feld', false, 'frei'),
('46', 'Standardfeld', 5, 10, 1, 1, 100, '1 Feld', false, 'frei'),
('47', 'Standardfeld', 6, 1, 1, 1, 100, '1 Feld', false, 'frei'),
('48', 'Standardfeld', 6, 2, 1, 1, 100, '1 Feld', false, 'frei'),
('49', 'Standardfeld', 6, 3, 1, 1, 100, '1 Feld', false, 'frei'),
('50', 'Standardfeld', 6, 4, 1, 1, 100, '1 Feld', false, 'frei'),
('51', 'Standardfeld', 6, 7, 1, 1, 100, '1 Feld', false, 'frei'),
('52', 'Standardfeld', 6, 8, 1, 1, 100, '1 Feld', false, 'frei'),
('53', 'Standardfeld', 6, 9, 1, 1, 100, '1 Feld', false, 'frei'),
('54', 'Standardfeld', 6, 10, 1, 1, 100, '1 Feld', false, 'frei'),
('55', 'Standardfeld', 7, 1, 1, 1, 100, '1 Feld', false, 'frei'),
('56', 'Standardfeld', 7, 2, 1, 1, 100, '1 Feld', false, 'frei'),
('57', 'Standardfeld', 7, 3, 1, 1, 100, '1 Feld', false, 'frei'),
('58', 'Standardfeld', 7, 4, 1, 1, 100, '1 Feld', false, 'frei'),
('59', 'Standardfeld', 7, 5, 1, 1, 100, '1 Feld', false, 'frei'),
('60', 'Standardfeld', 7, 6, 1, 1, 100, '1 Feld', false, 'frei'),
('61', 'Standardfeld', 7, 7, 1, 1, 100, '1 Feld', false, 'frei'),
('62', 'Standardfeld', 7, 8, 1, 1, 100, '1 Feld', false, 'frei'),
('63', 'Standardfeld', 7, 9, 1, 1, 100, '1 Feld', false, 'frei'),
('64', 'Standardfeld', 7, 10, 1, 1, 100, '1 Feld', false, 'frei'),
('65', 'Standardfeld', 8, 1, 1, 1, 100, '1 Feld', false, 'frei'),
('66', 'Standardfeld', 8, 2, 1, 1, 100, '1 Feld', false, 'frei'),
('67', 'Standardfeld', 8, 3, 1, 1, 100, '1 Feld', false, 'frei'),
('68', 'Standardfeld', 8, 4, 1, 1, 100, '1 Feld', false, 'frei'),
('69', 'Standardfeld', 8, 5, 1, 1, 100, '1 Feld', false, 'frei'),
('70', 'Standardfeld', 8, 6, 1, 1, 100, '1 Feld', false, 'frei'),
('71', 'Standardfeld', 8, 7, 1, 1, 100, '1 Feld', false, 'frei'),
('72', 'Standardfeld', 8, 8, 1, 1, 100, '1 Feld', false, 'frei'),
('73', 'Standardfeld', 8, 9, 1, 1, 100, '1 Feld', false, 'frei'),
('74', 'Standardfeld', 8, 10, 1, 1, 100, '1 Feld', false, 'frei'),
('75', 'Standardfeld', 9, 1, 1, 1, 100, '1 Feld', false, 'frei'),
('76', 'Standardfeld', 9, 2, 1, 1, 100, '1 Feld', false, 'frei'),
('77', 'Standardfeld', 9, 3, 1, 1, 100, '1 Feld', false, 'frei'),
('78', 'Standardfeld', 9, 4, 1, 1, 100, '1 Feld', false, 'frei'),
('E3', 'Elfmeterpunkt 2', 5, 9, 1, 1, 60, '1 Feld (Teil Sonderfläche)', true, 'frei'),
('E4', 'Elfmeterpunkt 2', 6, 9, 1, 1, 60, '1 Feld (Teil Sonderfläche)', true, 'frei'),
('79', 'Standardfeld', 9, 7, 1, 1, 100, '1 Feld', false, 'frei'),
('80', 'Standardfeld', 9, 8, 1, 1, 100, '1 Feld', false, 'frei'),
('81', 'Standardfeld', 9, 9, 1, 1, 100, '1 Feld', false, 'frei'),
('82', 'Standardfeld', 9, 10, 1, 1, 100, '1 Feld', false, 'frei'),
('83', 'Standardfeld', 10, 1, 1, 1, 100, '1 Feld', false, 'frei'),
('84', 'Standardfeld', 10, 2, 1, 1, 100, '1 Feld', false, 'frei'),
('85', 'Standardfeld', 10, 3, 1, 1, 100, '1 Feld', false, 'frei'),
('86', 'Standardfeld', 10, 4, 1, 1, 100, '1 Feld', false, 'frei'),
('87', 'Standardfeld', 10, 5, 1, 1, 100, '1 Feld', false, 'frei'),
('88', 'Standardfeld', 10, 6, 1, 1, 100, '1 Feld', false, 'frei'),
('89', 'Standardfeld', 10, 7, 1, 1, 100, '1 Feld', false, 'frei'),
('90', 'Standardfeld', 10, 8, 1, 1, 100, '1 Feld', false, 'frei'),
('91', 'Standardfeld', 10, 9, 1, 1, 100, '1 Feld', false, 'frei'),
('92', 'Standardfeld', 10, 10, 1, 1, 100, '1 Feld', false, 'frei'),
('M', 'Mittelkreis', 5, 5, 2, 2, 500, '2×2 Felder (Sonderfläche)', true, 'frei')
on conflict (id) do nothing;
-- fertig
