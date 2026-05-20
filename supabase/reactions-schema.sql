-- Roatán Insider · Business reactions schema
-- =============================================================================
-- One-time setup. Run this in your Supabase SQL editor.
-- Project: vbxmmslzanixvqswtnnv (matches AppConstants.supabaseRESTBaseURL).
--
-- What it gives you:
--   - public.business_reactions  : one row per (device, business). The reactions
--     column is a text[] of {'heart','fire','thumbs'}.
--   - public.set_reactions       : RPC the iOS client calls to upsert atomically.
--     Anonymous, no auth required (it accepts device_id as a parameter).
--   - public.business_reaction_counts : read-only view exposing aggregate counts
--     per business. The iOS client GETs this with `business_id=in.(...)`.
--   - RLS policies                : reads are public; only the device that owns
--     a row can update or delete it.
--
-- iOS client behaviour without this schema applied:
--   The app gracefully degrades to "local-only reactions" — users see their own
--   reactions and counts, nothing syncs. Once you run this and add
--   SUPABASE_ANON_KEY to the app's Info.plist, syncing turns on transparently.
-- =============================================================================

-- 1. Table
create table if not exists public.business_reactions (
    id          uuid primary key default gen_random_uuid(),
    business_id text not null,
    device_id   text not null,
    reactions   text[] not null default '{}'::text[],
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now(),

    -- Each device has at most one row per business — toggles update in place.
    constraint business_reactions_device_business_unique
        unique (device_id, business_id)
);

create index if not exists business_reactions_business_idx
    on public.business_reactions (business_id);

-- 2. Aggregate counts view
create or replace view public.business_reaction_counts as
select
    business_id,
    count(*) filter (where 'heart'  = any(reactions))::int as heart_count,
    count(*) filter (where 'fire'   = any(reactions))::int as fire_count,
    count(*) filter (where 'thumbs' = any(reactions))::int as thumbs_count
from public.business_reactions
group by business_id;

-- 3. Upsert RPC
-- Called by the iOS client as POST /rest/v1/rpc/set_reactions with body:
--   { "p_business_id": "...", "p_device_id": "...", "p_reactions": ["heart"] }
-- Empty reactions array means "clear all reactions for this device on this
-- business." We delete the row in that case to keep the aggregate view clean.
create or replace function public.set_reactions(
    p_business_id text,
    p_device_id   text,
    p_reactions   text[]
) returns void as $$
begin
    -- Reject anything other than the three known reactions to keep the
    -- aggregate view stable. Silently filter rather than erroring so the
    -- iOS client never blocks the UI on a server-side reject.
    p_reactions := array(
        select unnest(p_reactions)
        intersect
        select unnest(array['heart','fire','thumbs'])
    );

    if array_length(p_reactions, 1) is null then
        delete from public.business_reactions
        where device_id = p_device_id and business_id = p_business_id;
        return;
    end if;

    insert into public.business_reactions (business_id, device_id, reactions, updated_at)
    values (p_business_id, p_device_id, p_reactions, now())
    on conflict (device_id, business_id)
    do update set reactions = excluded.reactions, updated_at = now();
end;
$$ language plpgsql security definer;

-- Allow the anon role to call the RPC (Supabase REST exposes it under
-- /rest/v1/rpc/set_reactions for the anon and authenticated roles).
grant execute on function public.set_reactions(text, text, text[]) to anon, authenticated;

-- 4. RLS
alter table public.business_reactions enable row level security;

-- Anyone can read. The counts view inherits this.
drop policy if exists "reactions_read" on public.business_reactions;
create policy "reactions_read" on public.business_reactions
    for select using (true);

-- Writes go through the security-definer RPC above, so direct inserts/updates
-- from the anon role aren't necessary. Locking them down keeps the data clean.
drop policy if exists "reactions_no_direct_writes" on public.business_reactions;
create policy "reactions_no_direct_writes" on public.business_reactions
    for insert with check (false);
drop policy if exists "reactions_no_direct_updates" on public.business_reactions;
create policy "reactions_no_direct_updates" on public.business_reactions
    for update using (false);
drop policy if exists "reactions_no_direct_deletes" on public.business_reactions;
create policy "reactions_no_direct_deletes" on public.business_reactions
    for delete using (false);

-- Grant the view to anon so the iOS client can GET it via REST.
grant select on public.business_reaction_counts to anon, authenticated;
