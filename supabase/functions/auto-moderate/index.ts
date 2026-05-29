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
    // 1. Verify Authorization webhook secret
    const authHeader = req.headers.get('Authorization')
    const webhookSecret = Deno.env.get('MODERATION_WEBHOOK_SECRET')
    
    if (webhookSecret && authHeader !== `Bearer ${webhookSecret}`) {
      console.warn("Unauthorized webhook request attempt.")
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
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Missing Supabase URL or Service Role Key in environment variables.")
    }

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
        return new Response(JSON.stringify({ error: 'Message not found or inaccessible' }), {
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
        You are an AI Content Moderator for a secure chat messenger application.
        Analyze the reported chat message below and decide if it violates safety standards (e.g., contains toxic behavior, harassment, extreme profanity/insults, spam, scam, or dangerous content).
        
        Reported Message: "${reportedText}"
        Reporter's Specified Reason: "${reporterReason}"
        Reporter's Extra Details: "${reporterDetails}"

        Determine whether to take action.
        - "none": No severe violation. (e.g., normal chat, false positive report).
        - "delete": Mild/medium violation, delete the message but do not ban the user.
        - "ban": High-severity violation (scam, extreme harassment, hate speech, illegal activities). Delete the message and ban the user.
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
