import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Verify Authorization (either webhook secret or user JWT token)
    const authHeader = req.headers.get('Authorization')
    const webhookSecret = Deno.env.get('MODERATION_WEBHOOK_SECRET')
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Missing Supabase URL or Service Role Key in environment variables.")
    }

    let isAuthorized = false

    if (webhookSecret && authHeader === `Bearer ${webhookSecret}`) {
      isAuthorized = true
    } else if (authHeader) {
      try {
        const authClient = createClient(supabaseUrl, supabaseServiceKey, {
          global: { headers: { Authorization: authHeader } }
        })
        const { data: { user }, error: authError } = await authClient.auth.getUser()
        if (user && !authError) {
          isAuthorized = true
        }
      } catch (err) {
        console.error("User token validation failed:", err)
      }
    }

    if (!isAuthorized) {
      console.warn("Unauthorized request attempt.")
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const payload = await req.json()
    const record = payload.record

    if (!record) {
      return new Response(JSON.stringify({ error: 'No record found in payload' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    console.log(`Processing new report: ID=${record.id}, TargetType=${record.target_type}, TargetID=${record.target_id}`)

    // 2. Initialize Supabase Client with service role key (to bypass RLS)
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // 3. Handle messages moderation
    if (record.target_type === 'message') {
      // Retrieve the message content and author ID
      const { data: message, error: messageError } = await supabase
        .from('messages')
        .select('content, profile_id')
        .eq('id', record.target_id)
        .single()

      if (messageError || !message) {
        console.error(`Failed to fetch message for ID ${record.target_id}:`, messageError)
        return new Response(JSON.stringify({ 
          error: 'Message not found or inaccessible',
          details: messageError ? messageError.message : 'No message found with this ID',
          code: messageError ? messageError.code : null,
          hint: messageError ? messageError.hint : null
        }), {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      const reportedText = message.content
      const reporterReason = record.reason
      const reporterDetails = record.details || ''

      console.log(`Fetched reported message text: "${reportedText}" by User ${message.profile_id}`)

      // 4. Request Gemini API moderation
      const geminiApiKey = Deno.env.get('GEMINI_API_KEY')
      if (!geminiApiKey) {
        throw new Error("Missing GEMINI_API_KEY in environment variables.")
      }

      const promptText = `
        Ты — ИИ-модератор безопасного мессенджера.
        Проанализируй полученное сообщение и жалобу на него от другого пользователя.
        Определи, нарушает ли сообщение правила сообщества (спам, мошенничество, оскорбления, травля, угрозы, неприемлемый контент, нецензурная брань).
        
        Текст сообщения: "${reportedText}"
        Указанная причина жалобы: "${reporterReason}"
        Дополнительные детали от отправителя жалобы: "${reporterDetails}"

        Определи действие:
        - "none": Нарушений нет (обычное сообщение, ложная жалоба).
        - "delete": Сообщение нарушает правила (нецензурная лексика, мелкие оскорбления, спам-ссылки). Нужно удалить сообщение, но блокировать пользователя не требуется.
        - "ban": Грубое нарушение (мошенничество/скам, агрессивная травля, разжигание ненависти, экстремизм, угрозы насилия). Нужно удалить сообщение и заблокировать пользователя.

        ВАЖНО: Поле "reason" в JSON должно быть строго на русском языке. Это текст, который увидит заблокированный пользователь на своем экране (например, "Мошенничество и спам-рассылка").
      `

      // Build structured schema to guarantee JSON response format from Gemini
      const geminiRequest = {
        contents: [
          {
            parts: [{ text: promptText }]
          }
        ],
        generationConfig: {
          responseMimeType: "application/json",
          responseSchema: {
            type: "OBJECT",
            properties: {
              is_violation: { type: "BOOLEAN" },
              action: {
                type: "STRING",
                enum: ["none", "delete", "ban"]
              },
              reason: { type: "STRING" },
              severity: {
                type: "STRING",
                enum: ["none", "low", "medium", "high"]
              }
            },
            required: ["is_violation", "action", "reason", "severity"]
          }
        }
      }

      console.log("Sending moderation request to Gemini API...")
      const geminiResponse = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${geminiApiKey}`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(geminiRequest),
        }
      )

      if (!geminiResponse.ok) {
        const errorText = await geminiResponse.text()
        throw new Error(`Gemini API error: ${geminiResponse.status} - ${errorText}`)
      }

      const geminiData = await geminiResponse.json()
      const rawText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text
      
      if (!rawText) {
        throw new Error("Empty response received from Gemini API.")
      }

      const moderationResult = JSON.parse(rawText)
      console.log("Gemini moderation response:", moderationResult)

      // 5. Apply moderation action in Database
      if (moderationResult.is_violation) {
        // A. Delete the message if action is "delete" or "ban"
        if (moderationResult.action === 'delete' || moderationResult.action === 'ban') {
          console.log(`Action: Deleting message ID ${record.target_id}`)
          const { error: deleteError } = await supabase
            .from('messages')
            .update({
              is_deleted: true,
              deleted_at: new Date().toISOString()
            })
            .eq('id', record.target_id)

          if (deleteError) {
            console.error(`Error deleting message:`, deleteError)
          } else {
            console.log(`Successfully deleted message ID ${record.target_id}`)
          }
        }

        // B. Ban the user if action is "ban"
        if (moderationResult.action === 'ban') {
          const banDurationDays = 7 // Default ban duration
          const bannedUntil = new Date()
          bannedUntil.setDate(bannedUntil.getDate() + banDurationDays)

          console.log(`Action: Banning user ID ${message.profile_id} until ${bannedUntil.toISOString()}`)
          const { error: banError } = await supabase
            .from('profiles')
            .update({
              is_banned: true,
              banned_until: bannedUntil.toISOString(),
              banned_reason: `Automated AI Ban: ${moderationResult.reason} (Severity: ${moderationResult.severity})`
            })
            .eq('id', message.profile_id)

          if (banError) {
            console.error(`Error banning user ${message.profile_id}:`, banError)
          } else {
            console.log(`Successfully banned user ${message.profile_id}`)
          }
        }
      } else {
        console.log("No violation found by AI moderation. No actions taken.")
      }

      return new Response(JSON.stringify({ success: true, moderation: moderationResult }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Handled cases other than "message"
    return new Response(JSON.stringify({ success: true, message: 'Report type not handled yet' }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error("Error in auto-moderate function execution:", error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
