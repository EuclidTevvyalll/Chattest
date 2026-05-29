# Supabase AI Moderation Setup Guide

This guide details how to set up, configure, and deploy the automated ИИ-moderation system.

## 1. Secrets Configuration

Before deploying, you must configure two environment variables in your Supabase project.

### Webhook Secret (`MODERATION_WEBHOOK_SECRET`)
To prevent unauthorized invocations of your edge function, generate a secure random string (e.g. 32 characters) and use it as a shared secret between PostgreSQL and Deno.
1. Set it in Supabase secrets:
   ```bash
   supabase secrets set MODERATION_WEBHOOK_SECRET=your_secure_random_string
   ```
2. Update the `webhook_secret` value in the migration file: [auto_moderate_trigger.sql](file:///c:/Projects/Chattest-main/supabase/migrations/auto_moderate_trigger.sql):
   ```sql
   webhook_secret text := 'your_secure_random_string';
   ```

### Gemini API Key (`GEMINI_API_KEY`)
Get a free/paid API Key from Google AI Studio.
1. Set it in Supabase secrets:
   ```bash
   supabase secrets set GEMINI_API_KEY=your_gemini_api_key
   ```

---

## 2. Deploying the Edge Function

Deploy the function to your Supabase cloud project:
```bash
supabase functions deploy auto-moderate
```

If you want to run and test it locally first:
1. Start your local Supabase stack:
   ```bash
   supabase start
   ```
2. Run the function locally:
   ```bash
   supabase functions serve auto-moderate --no-verify-jwt
   ```

---

## 3. Applying the Database Trigger

To enable the trigger, execute the SQL migration script:
1. Copy the contents of [auto_moderate_trigger.sql](file:///c:/Projects/Chattest-main/supabase/migrations/auto_moderate_trigger.sql).
2. Go to your **Supabase Dashboard** -> **SQL Editor**.
3. Create a new query, paste the script, and click **Run**.

Alternatively, if you use the Supabase CLI migrations:
```bash
supabase db push
```

---

## 4. Test the Integration

1. Send a message in your app, for example: `"Hey, this is a spam message: click here to win 1000$ free credits!"`
2. Obtain the message ID from the `messages` table or use the report option in the client UI.
3. Submit a report on that message using the client UI dialog or insert a mock report in the SQL editor:
   ```sql
   insert into public.reports (reporter_id, target_id, target_type, reason, details)
   values (
     'any-valid-profile-uuid',
     'reported-message-uuid',
     'message',
     'Spam',
     'This user is sending spam links.'
   );
   ```
4. Check the Supabase Edge Function logs (`Edge Functions` -> `auto-moderate` -> `Logs`). You should see:
   - Webhook trigger received.
   - Message text retrieved successfully.
   - Gemini API returning a classification (`is_violation: true, action: "delete" or "ban"`).
   - Message updated in database with `is_deleted = true`.
