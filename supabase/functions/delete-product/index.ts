import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { productId } = await req.json()

    // 1. Get the product to find the image URLs
    const { data: product, error: fetchError } = await supabaseClient
      .from('products')
      .select('image_urls, seller_id')
      .eq('id', productId)
      .single()

    if (fetchError || !product) throw new Error('Product not found')

    // 2. Extract storage paths from URLs
    // Ensure we are working with an array (Postgres arrays can sometimes return as strings)
    let imageUrls = product.image_urls || []
    if (typeof imageUrls === 'string') {
      if (imageUrls.startsWith('{') && imageUrls.endsWith('}')) {
        imageUrls = imageUrls.substring(1, imageUrls.length - 1).split(',').map(s => s.trim().replace(/^"|"$/g, ''))
      } else {
        try {
          imageUrls = JSON.parse(imageUrls)
        } catch (e) {
          imageUrls = [imageUrls]
        }
      }
    }

    const pathsToDelete = (Array.isArray(imageUrls) ? imageUrls : [])
      .map((url: string) => {
        const parts = url.split('user-images/')
        return parts.length > 1 ? parts[1] : null
      })
      .filter(Boolean)

    // 3. Delete files from Storage bucket
    if (pathsToDelete.length > 0) {
      const { error: storageError } = await supabaseClient
        .storage
        .from('user-images')
        .remove(pathsToDelete)

      if (storageError) console.error('Storage deletion warning:', storageError)
    }

    // 4. Delete image metadata from product_images table
    await supabaseClient
      .from('product_images')
      .delete()
      .in('url', Array.isArray(imageUrls) ? imageUrls : [])

    // 5. Delete the product row
    const { error: deleteError } = await supabaseClient
      .from('products')
      .delete()
      .eq('id', productId)

    if (deleteError) throw deleteError

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
