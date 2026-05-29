-- Migration: Set up automatic moderation trigger on the 'reports' table.
-- This script enables pg_net and creates a trigger that invokes the Edge Function on INSERT.

-- 1. Enable the pg_net extension (required for making HTTP requests from Postgres)
create extension if not exists pg_net;

-- 2. Create the trigger function that calls the Edge Function
create or replace function public.handle_new_report()
returns trigger
security definer
language plpgsql
as $$
declare
  webhook_url text := 'https://qhrcpooazwkdckusqcvx.supabase.co/functions/v1/auto-moderate';
  webhook_secret text := 'f7a2d8e4c9b10375a6e8f0d9c8b7a6d5'; -- Replace this or set up via vault
  payload jsonb;
begin
  -- Construct the payload containing the new report record
  payload := jsonb_build_object(
    'record', row_to_json(new)
  );

  -- Perform the asynchronous HTTP POST request to the Supabase Edge Function
  perform net.http_post(
    url := webhook_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || webhook_secret
    ),
    body := payload
  );

  return new;
end;
$$;

-- 3. Bind the trigger to the 'reports' table
drop trigger if exists on_report_created on public.reports;
create trigger on_report_created
  after insert on public.reports
  for each row
  execute function public.handle_new_report();

comment on function public.handle_new_report is 'Triggers the auto-moderate Edge Function when a user reports content.';
