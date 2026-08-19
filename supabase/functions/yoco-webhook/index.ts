import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

// Standard HMAC-SHA256 verification for Yoco
async function verifySignature(body: string, signature: string, secret: string): Promise<boolean> {
  const encoder = new TextEncoder()
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["verify"]
  )

  const signatureBytes = new Uint8Array(
    signature.match(/.{1,2}/g)!.map((byte) => parseInt(byte, 16))
  )

  return await crypto.subtle.verify(
    "HMAC",
    key,
    signatureBytes,
    encoder.encode(body)
  )
}

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405 })
    }

    const body = await req.text()
    const signature = req.headers.get("Yoco-Signature")
    const webhookSecret = Deno.env.get("YOCO_WEBHOOK_SECRET")

    // Verify signature if secret is configured
    if (webhookSecret && signature) {
      const isValid = await verifySignature(body, signature, webhookSecret)
      if (!isValid) {
        console.error("Invalid signature detected!")
        return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 })
      }
    }

    const event = JSON.parse(body)
    console.log("Yoco webhook received:", JSON.stringify(event))

    // Only process successful payments
    if (event.type !== "payment.succeeded") {
      console.log(`Ignoring event type: ${event.type}`)
      return new Response(JSON.stringify({ received: true }), { status: 200 })
    }

    const productId = event.payload?.metadata?.productId
    if (!productId) {
      console.error("Missing productId in webhook metadata")
      return new Response(JSON.stringify({ error: "Missing productId" }), { status: 400 })
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    )

    const { error } = await supabase
      .from("products")
      .update({ status: "active" })
      .eq("id", productId)

    if (error) {
      console.error("Failed to activate product:", error)
      throw error
    }

    console.log(`Product ${productId} activated successfully.`)
    return new Response(JSON.stringify({ received: true, success: true }), { status: 200 })

  } catch (err) {
    console.error("Webhook Error:", err)
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})
