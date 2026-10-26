

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // =====================================================
    // Environment Variables
    // =====================================================
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl) {
      throw new Error("SUPABASE_URL missing");
    }

    if (!anonKey) {
      throw new Error("SUPABASE_ANON_KEY missing");
    }

    if (!serviceRoleKey) {
      throw new Error("SUPABASE_SERVICE_ROLE_KEY missing");
    }

    // =====================================================
    // Authenticate User
    // =====================================================

    const authHeader = req.headers.get("Authorization");
    console.log("Authorization Header:", authHeader);

    if (!authHeader) {
      return jsonResponse(
        { error: "Missing Authorization header" },
        401,
      );
    }

    const userClient = createClient(
      supabaseUrl,
      anonKey,
      {
        global: {
          headers: {
            Authorization: authHeader,
          },
        },
      },
    );

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();

    console.log("User Error:", userError);
    console.log("User:", user);


    if (userError || !user) {

      return jsonResponse(
        { error: "Unauthorized: Invalid token" },
        401,
      );
    }

    // =====================================================
    // Parse Request
    // =====================================================
    const { productId } = await req.json();

    if (!productId) {
      return jsonResponse(
        { error: "Missing productId parameter" },
        400,
      );
    }

    // =====================================================
    // Get Product (RLS Protected)
    // =====================================================
    const {
      data: product,
      error: fetchError,
    } = await userClient
      .from("products")
      .select("id, seller_id, image_urls")
      .eq("id", productId)
      .single();

    if (fetchError || !product) {
      return jsonResponse(
        { error: "Product not found" },
        404,
      );
    }

    // =====================================================
    // Ownership Check
    // =====================================================
    if (product.seller_id !== user.id) {
      return jsonResponse(
        { error: "Forbidden: You do not own this product" },
        403,
      );
    }

    // =====================================================
    // Admin Client
    // Used ONLY for operations requiring elevated privileges
    // =====================================================

    const adminClient = createClient(
      supabaseUrl,
      serviceRoleKey,
    );

    // =====================================================
    // Extract Image Paths
    // =====================================================
    let imageUrls = product.image_urls ?? [];

    if (typeof imageUrls === "string") {
      try {
        imageUrls = JSON.parse(imageUrls);
      } catch {
        imageUrls = [imageUrls];
      }
    }

    const pathsToDelete = (Array.isArray(imageUrls)
      ? imageUrls
      : [])
      .map((url: string) => {
        const parts = url.split("user-images/");
        return parts.length > 1 ? parts[1] : null;
      })
      .filter(Boolean);

    // =====================================================
    // Delete Storage Files
    // =====================================================
    if (pathsToDelete.length > 0) {
      const { error: storageError } = await adminClient
        .storage
        .from("user-images")
        .remove(pathsToDelete);

      if (storageError) {
        console.error(storageError);
      }
    }

    // =====================================================
    // Delete Image Metadata
    // RLS should allow owner deletion
    // =====================================================
    const { error: imageDeleteError } = await userClient
      .from("product_images")
      .delete()
      .in(
        "url",
        Array.isArray(imageUrls) ? imageUrls : [],
      );

    if (imageDeleteError) {
      throw imageDeleteError;
    }

    // =====================================================
    // Delete Product
    // RLS should allow owner deletion
    // =====================================================
    const { error: productDeleteError } = await userClient
      .from("products")
      .delete()
      .eq("id", productId);

    if (productDeleteError) {
      throw productDeleteError;
    }

    return jsonResponse(
      {
        success: true,
        message: "Product and associated images deleted",
      },
      200,
    );
  } catch (error) {
    console.error(error);

    return jsonResponse(
      {
        error:
          error instanceof Error
            ? error.message
            : "Unknown error",
      },
      500,
    );
  }
});

// =====================================================
// Helper Function
// =====================================================
function jsonResponse(data: unknown, status: number) {
  return new Response(
    JSON.stringify(data),
    {
      status,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
      },
    },
  );
}
