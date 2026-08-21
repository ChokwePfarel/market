import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }

  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { amount, productId } = await req.json()
    const secretKey = Deno.env.get('YOCO_SECRET_KEY')

    if (!secretKey) throw new Error('YOCO_SECRET_KEY not configured in Supabase')

    console.log(`Creating YOCO checkout for product ${productId}, amount: ${amount}`)

    const response = await fetch('https://payments.yoco.com/api/checkouts', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${secretKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        amount: amount,
        currency: 'ZAR',
        successUrl: `marketapp://paymentrecieved-callback?id=${productId}`,
        cancelUrl: `marketapp://payment-cancel?id=${productId}`,
        metadata: { productId: productId },
      }),
    })

    const contentType = response.headers.get("content-type")
    let data
    if (contentType && contentType.includes("application/json")) {
      data = await response.json()
    } else {
      const text = await response.text()
      console.error(`YOCO returned non-JSON response (${response.status}):`, text)
      throw new Error(`YOCO API Error (Status ${response.status}). This usually means the API key is invalid or YOCO is blocking the request.`)
    }

    if (!response.ok) {
      console.error('YOCO API Error Detail:', data)
      throw new Error(data.displayMessage || `YOCO Error: ${response.status}`)
    }

    // NEW: Wrap the YOCO redirect URL inside your verified domain's redirector
    // Using your new verified domain: marketplaceapp.co.za
    const verifiedDomainPage = "https://marketplaceapp.co.za/pay.html";
    const finalRedirectUrl = `${verifiedDomainPage}?url=${encodeURIComponent(data.redirectUrl)}`;

    return new Response(JSON.stringify({ redirectUrl: finalRedirectUrl }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    })
  } catch (err) {
    console.error('Checkout Function Error:', err.message)
    return new Response(JSON.stringify({ error: err.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    })
  }
})
