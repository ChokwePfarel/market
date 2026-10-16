import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''


    // Verifying User Authentication via Bearer token

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing Authorization header' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      })
    }

    const token = authHeader.replace('Bearer ', '')
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    })

    const { data: { user }, error: userError } = await userClient.auth.getUser(token)

    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized: Invalid token' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      })
    }

    // Admin client to perform privileged storage and DB deletions
    const adminClient = createClient( supabaseUrl, serviceRoleKey)

    const { productId } = await req.json()
    if (!productId) {
      return new Response(JSON.stringify({ error: 'Missing productId parameter' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    // 2 Fetch product details to find image URLs and verify ownership
    const { data: product, error: fetchError } = await adminClient
      .from('products')
      .select('image_urls, seller_id')
      .eq('id', productId)
      .single()

    if (fetchError || !product) {
      return new Response(JSON.stringify({ error: 'Product not found' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 404,
      })
    }

    // 3 Verify Ownership: Ensure the authenticated user owns the product
    if (product.seller_id !== user.id) {
      return new Response(JSON.stringify({ error: 'Forbidden: You do not own this product' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 403,
      })
    }

    // 4 Extract storage paths from URLs
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

    // 5   Delete files from Storage bucket
    if (pathsToDelete.length > 0) {
      const { error: storageError } = await adminClient
        .storage
        .from('user-images')
        .remove(pathsToDelete)

      if (storageError) console.error('Storage deletion warning:', storageError)
    }

    // 6  Delete image metadata from product_images table
    await adminClient
      .from('product_images')
      .delete()
      .in('url', Array.isArray(imageUrls) ? imageUrls : [])

    // 7    Delete the product row
    const { error: deleteError } = await adminClient
      .from('products')
      .delete()
      .eq('id', productId)

    if (deleteError) throw deleteError

    return new Response(JSON.stringify({ success: true, message: 'Product and associated images deleted' }), {
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
