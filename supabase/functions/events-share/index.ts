// supabase/functions/events-share/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ShareRequest {
  eventId: string
  inviteeEmail: string
}

interface ShareResponse {
  success: boolean
  shareUrl?: string
  invitationId?: string
  error?: string
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Authentification
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Missing authorization header')
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    )

    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      throw new Error('Unauthorized')
    }

    // Parser la requête
    const { eventId, inviteeEmail }: ShareRequest = await req.json()

    if (!eventId || !inviteeEmail) {
      throw new Error('eventId and inviteeEmail are required')
    }

    // Vérifier que l'utilisateur est bien le owner de l'événement
    const { data: event, error: eventError } = await supabaseClient
      .from('events')
      .select('*')
      .eq('id', eventId)
      .single()

    if (eventError || !event) {
      throw new Error('Event not found')
    }

    if (event.owner_id !== user.id) {
      throw new Error('You are not the owner of this event')
    }

    // Générer un token unique pour le partage
    const shareToken = crypto.randomUUID()

    // Créer l'invitation
    const { data: invitation, error: invitationError } = await supabaseClient
      .from('event_invitations')
      .insert({
        event_id: eventId,
        inviter_id: user.id,
        invitee_email: inviteeEmail,
        share_token: shareToken,
        status: 'pending',
      })
      .select()
      .single()

    if (invitationError) {
      console.error('Error creating invitation:', invitationError)
      throw new Error('Failed to create invitation')
    }

    // Générer l'URL de partage
    const baseUrl = Deno.env.get('APP_BASE_URL') ?? 'moments://invite'
    const shareUrl = `${baseUrl}?token=${shareToken}`

    // TODO: Envoyer un email d'invitation (intégration SendGrid/Resend)
    // await sendInvitationEmail(inviteeEmail, event, shareUrl)

    const response: ShareResponse = {
      success: true,
      shareUrl,
      invitationId: invitation.id,
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    console.error('Error:', error)

    const response: ShareResponse = {
      success: false,
      error: error.message,
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: error.message === 'Unauthorized' ? 401 : 400,
    })
  }
})
