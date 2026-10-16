import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const webhookSecret = Deno.env.get('REVENUECAT_WEBHOOK_SECRET') ?? ''

    // 1. Verify Authorization Header if webhook secret is configured
    if (webhookSecret) {
      const authHeader = req.headers.get('Authorization')
      if (!authHeader || authHeader !== `Bearer ${webhookSecret}`) {
        return new Response(JSON.stringify({ error: 'Unauthorized webhook request' }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401,
        })
      }
    }

    const body = await req.json()
    console.log('RevenueCat Webhook Payload:', JSON.stringify(body))

    const event = body.event
    if (!event) {
      return new Response(JSON.stringify({ error: 'Missing event payload' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    const eventType = event.type
    const appUserId = event.app_user_id

    // Check if event is a purchase event
    const validEvents = ['INITIAL_PURCHASE', 'NON_RENEWING_PURCHASE', 'RENEWAL', 'PRODUCT_CHANGE']
    if (!validEvents.includes(eventType)) {
      console.log(`Ignoring event type: ${eventType}`)
      return new Response(JSON.stringify({ message: `Ignored event: ${eventType}` }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    // Extract product ID from URL query param or custom subscriber attributes
    const url = new URL(req.url)
    let productId = url.searchParams.get('productId')

    if (!productId && event.subscriber_attributes?.productId?.value) {
      productId = event.subscriber_attributes.productId.value
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey)

    // 2. Activate product by specific productId, or activate latest pending product for this user
    if (productId) {
      console.log(`Activating product by ID: ${productId}`)
      const { error } = await supabase
        .from('products')
        .update({ status: 'active' })
        .eq('id', productId)

      if (error) throw error
    } else if (appUserId) {
      console.log(`Activating latest pending product for seller: ${appUserId}`)
      const { data: pendingProducts, error: fetchError } = await supabase
        .from('products')
        .select('id')
        .eq('seller_id', appUserId)
        .eq('status', 'pending_payment')
        .order('created_at', { ascending: false })
        .limit(1)

      if (fetchError) throw fetchError

      if (pendingProducts && pendingProducts.length > 0) {
        const targetId = pendingProducts[0].id
        console.log(`Activating pending product: ${targetId}`)

        const { error: updateError } = await supabase
          .from('products')
          .update({ status: 'active' })
          .eq('id', targetId)

        if (updateError) throw updateError
      } else {
        console.log(`No pending_payment products found for seller ${appUserId}`)
      }
    }

    return new Response(JSON.stringify({ success: true, message: 'Payment verified and product activated' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (err) {
    console.error('RevenueCat Webhook Error:', err.message)
    return new Response(JSON.stringify({ error: err.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
