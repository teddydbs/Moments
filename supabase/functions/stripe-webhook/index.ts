// supabase/functions/stripe-webhook/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@13.6.0?target=deno'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
})

const cryptoProvider = Stripe.createSubtleCryptoProvider()

serve(async (req) => {
  const signature = req.headers.get('Stripe-Signature')

  if (!signature) {
    return new Response('No signature', { status: 400 })
  }

  try {
    // Lire le body en tant que texte brut (requis pour la vérification de signature)
    const body = await req.text()

    // Vérifier la signature du webhook
    const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')
    if (!webhookSecret) {
      throw new Error('Stripe webhook secret not configured')
    }

    const event = await stripe.webhooks.constructEventAsync(
      body,
      signature,
      webhookSecret,
      undefined,
      cryptoProvider
    )

    console.log(`Received event: ${event.type}`)

    // Créer un client Supabase avec service_role pour bypasser RLS
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Gérer les différents types d'événements
    switch (event.type) {
      case 'payment_intent.succeeded': {
        const paymentIntent = event.data.object as Stripe.PaymentIntent
        console.log(`PaymentIntent succeeded: ${paymentIntent.id}`)

        // Mettre à jour la contribution correspondante
        const { error } = await supabaseAdmin
          .from('contributions')
          .update({
            status: 'paid',
            stripe_payment_intent_id: paymentIntent.id,
            payment_method: paymentIntent.payment_method_types[0],
          })
          .eq('stripe_payment_intent_id', paymentIntent.id)

        if (error) {
          console.error('Error updating contribution:', error)
          throw error
        }

        console.log('Contribution marked as paid')
        break
      }

      case 'payment_intent.payment_failed': {
        const paymentIntent = event.data.object as Stripe.PaymentIntent
        console.log(`PaymentIntent failed: ${paymentIntent.id}`)

        // Optionnel : marquer comme échoué ou notifier l'utilisateur
        await supabaseAdmin
          .from('contributions')
          .update({
            status: 'pending',
          })
          .eq('stripe_payment_intent_id', paymentIntent.id)

        break
      }

      case 'charge.refunded': {
        const charge = event.data.object as Stripe.Charge
        console.log(`Charge refunded: ${charge.id}`)

        if (charge.payment_intent) {
          await supabaseAdmin
            .from('contributions')
            .update({
              status: 'refunded',
            })
            .eq('stripe_payment_intent_id', charge.payment_intent as string)
        }

        break
      }

      case 'customer.subscription.created':
      case 'customer.subscription.updated':
      case 'customer.subscription.deleted':
        // TODO: Gérer les abonnements si nécessaire dans le futur
        console.log(`Subscription event: ${event.type}`)
        break

      default:
        console.log(`Unhandled event type: ${event.type}`)
    }

    return new Response(JSON.stringify({ received: true }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    console.error('Webhook error:', error)
    return new Response(
      JSON.stringify({
        error: {
          message: error.message,
        },
      }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})
