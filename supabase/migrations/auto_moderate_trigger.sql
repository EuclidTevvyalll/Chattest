create extension if not exists pg_net;

create or replace function public.handle_new_report()
returns trigger
security definer
language plpgsql
as $$
declare
  webhook_url text := 'https://qhrcpooazwkdckusqcvx.supabase.co/functions/v1/auto-moderate';
  webhook_secret text := 'f7a2d8e4c9b10375a6e8f0d9c8b7a6d5';
  payload jsonb;
begin
  payload := jsonb_build_object(
    'record', row_to_json(new)
  );

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

drop trigger if exists on_report_created on public.reports;
create trigger on_report_created
  after insert on public.reports
  for each row
  execute function public.handle_new_report();

comment on function public.handle_new_report is 'Triggers the auto-moderate Edge Function when a user reports content.';
