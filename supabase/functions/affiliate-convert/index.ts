// supabase/functions/affiliate-convert/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ConvertRequest {
  url: string
  affiliateTag?: string
}

interface ConvertResponse {
  success: boolean
  affiliateUrl?: string
  error?: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Vérifier l'authentification
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

    // Vérifier que l'utilisateur est authentifié
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      throw new Error('Unauthorized')
    }

    // Parser le body
    const { url, affiliateTag }: ConvertRequest = await req.json()

    if (!url) {
      throw new Error('URL is required')
    }

    // Valider que c'est une URL Amazon valide
    const urlObj = new URL(url)
    const isAmazon = /amazon\.(com|fr|de|co\.uk|es|it|ca|com\.mx|com\.br|in|cn|co\.jp|com\.au)/i.test(
      urlObj.hostname
    )

    if (!isAmazon) {
      throw new Error('Only Amazon URLs are supported')
    }

    // Récupérer le tag d'affiliation depuis les variables d'environnement
    const defaultTag = Deno.env.get('AMAZON_AFFILIATE_TAG') ?? 'moments-21'
    const tag = affiliateTag || defaultTag

    // Convertir l'URL
    let affiliateUrl = url

    // Nettoyer les paramètres existants et ajouter le tag
    const cleanUrl = new URL(url)
    cleanUrl.searchParams.delete('tag')
    cleanUrl.searchParams.delete('linkCode')
    cleanUrl.searchParams.delete('ref')
    cleanUrl.searchParams.set('tag', tag)

    affiliateUrl = cleanUrl.toString()

    // Logger l'activité (optionnel - pour tracking)
    await supabaseClient
      .from('affiliate_conversions')
      .insert({
        user_id: user.id,
        original_url: url,
        affiliate_url: affiliateUrl,
        affiliate_tag: tag,
      })
      .select()
      .single()
      .catch(() => {
        // Ignorer les erreurs de logging (table peut ne pas exister encore)
        console.warn('Could not log affiliate conversion')
      })

    const response: ConvertResponse = {
      success: true,
      affiliateUrl,
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    console.error('Error:', error)

    const response: ConvertResponse = {
      success: false,
      error: error.message,
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: error.message === 'Unauthorized' ? 401 : 400,
    })
  }
})
