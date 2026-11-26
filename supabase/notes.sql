-- یادداشت‌های خانواده‌ها
-- این فایل را یک‌بار در Supabase ← SQL Editor ← New query اجرا کنید (قابل اجرای چندباره است).
-- فرض: نوع شناسه‌های families.id و profiles.family_id برابر uuid است.

create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  author_family_id uuid not null references public.families (id) on delete cascade,
  -- خالی (null) یعنی یادداشت همگانی؛ در غیر این صورت خصوصی برای آن خانواده
  to_family_id uuid references public.families (id) on delete cascade,
  body text not null check (char_length(body) between 1 and 500),
  created_at timestamptz not null default now()
);

create index if not exists notes_created_at_idx on public.notes (created_at);
create index if not exists notes_to_family_idx on public.notes (to_family_id, created_at);

-- خانوادهٔ کاربرِ واردشده (برای قواعد دسترسی)
create or replace function public.my_family_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select family_id from public.profiles where id = auth.uid()
$$;

revoke all on function public.my_family_id() from public;
grant execute on function public.my_family_id() to authenticated;

alter table public.notes enable row level security;

-- همه یادداشت‌های همگانی، به‌علاوهٔ خصوصی‌هایی که برای خانوادهٔ من آمده یا خانوادهٔ من نوشته.
drop policy if exists notes_select on public.notes;
create policy notes_select on public.notes
  for select to authenticated
  using (
    created_at > now() - interval '30 days'
    and (
      to_family_id is null
      or to_family_id = public.my_family_id()
      or author_family_id = public.my_family_id()
    )
  );

-- نوشتن: فقط با هویت خودِ کاربر و خانوادهٔ خودش؛ گیرنده نمی‌تواند خانوادهٔ خودش باشد.
drop policy if exists notes_insert on public.notes;
create policy notes_insert on public.notes
  for insert to authenticated
  with check (
    author_id = auth.uid()
    and author_family_id = public.my_family_id()
    and (to_family_id is null or to_family_id <> public.my_family_id())
  );

-- حذف: فقط نویسندهٔ یادداشت.
drop policy if exists notes_delete on public.notes;
create policy notes_delete on public.notes
  for delete to authenticated
  using (author_id = auth.uid());

grant select, insert, delete on public.notes to authenticated;

-- پاک‌شدن خودکار یادداشت‌های قدیمی‌تر از ۳۰ روز (هر ساعت)
create extension if not exists pg_cron;

select cron.unschedule('delete-old-notes')
where exists (select 1 from cron.job where jobname = 'delete-old-notes');

select cron.schedule(
  'delete-old-notes',
  '0 * * * *',
  $$ delete from public.notes where created_at < now() - interval '30 days' $$
);
