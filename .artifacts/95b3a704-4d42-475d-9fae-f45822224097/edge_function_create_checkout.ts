import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  // CORS Headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { amount, productId } = await req.json()
    const secretKey = Deno.env.get('YOCO_SECRET_KEY')

    if (!secretKey) throw new Error('YOCO_SECRET_KEY not configured in Supabase')

    const response = await fetch('https://online.yoco.com/v1/checkouts', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${secretKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        amount: amount, // in cents
        currency: 'ZAR',
        successUrl: `marketapp://paymentrecieved-callback?id=${productId}`,
        cancelUrl: `marketapp://payment-cancel?id=${productId}`,
        metadata: {
          productId: productId,
        },
      }),
    })

    const data = await response.json()

    if (!response.ok) {
      console.error('YOCO API Error:', data)
      throw new Error(data.displayMessage || 'Failed to create YOCO checkout')
    }

    return new Response(JSON.stringify({ redirectUrl: data.redirectUrl }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    })

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    })
  }
})
