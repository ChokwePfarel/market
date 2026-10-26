import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const VALID_PURCHASE_EVENTS = [
  "INITIAL_PURCHASE",
  "NON_RENEWING_PURCHASE",
  "RENEWAL",
  "PRODUCT_CHANGE",
];

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function jsonResponse(
  body: unknown,
  status = 200,
) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ==========================================
    // Environment Variables
    // ==========================================

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const webhookSecret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl) {
      throw new Error("SUPABASE_URL missing");
    }

    if (!webhookSecret) {
      throw new Error("REVENUECAT_WEBHOOK_SECRET missing");
    }

    if (!serviceRoleKey) {
      throw new Error("SUPABASE_SERVICE_ROLE_KEY missing");
    }

    // ==========================================
    // Verify Webhook
    // ==========================================

    const authHeader = req.headers.get("Authorization");

    if (!authHeader || authHeader !== `Bearer ${webhookSecret}`) {
      return jsonResponse(
        {
          error: "Unauthorized webhook request",
        },
        401,
      );
    }

    // ==========================================
    // Parse Payload
    // ==========================================

    const body = await req.json();

    console.log(
      "RevenueCat Webhook Payload:",
      JSON.stringify(body),
    );

    const event = body.event;

    if (!event) {
      return jsonResponse(
        {
          error: "Missing event payload",
        },
        400,
      );
    }

    const eventType = event.type;
    const appUserId = event.app_user_id;

    if (!VALID_PURCHASE_EVENTS.includes(eventType)) {
      console.log(`Ignoring event type: ${eventType}`);
      return jsonResponse({
        message: `Ignored event: ${eventType}`,
      });
    }

    // ==========================================
    // Product ID Lookup
    // ==========================================

    const url = new URL(req.url);

    const productId =
      url.searchParams.get("productId") ??
      event.subscriber_attributes?.productId?.value ??
      null;

    // ==========================================
    // Admin Client
    // ==========================================

    const supabase = createClient(
      supabaseUrl,
      serviceRoleKey,
    );

    // ==========================================
    // Activate Explicit Product
    // ==========================================

    if (productId) {
      console.log(`Activating product by ID: ${productId}`);

      const { error } = await supabase
        .from("products")
        .update({
          status: "active",
        })
        .eq("id", productId);

      if (error) throw error;

      return jsonResponse({
        success: true,
        message: "Product activated",
      });
    }

    // ==========================================
    // Activate Latest Pending Product
    // ==========================================

    if (!appUserId) {
      return jsonResponse({
        success: true,
        message: "No productId or app_user_id supplied",
      });
    }

    // Validate if appUserId is a valid UUID before querying PostgreSQL UUID column
    if (!UUID_REGEX.test(appUserId)) {
      console.warn(
        `Warning: app_user_id "${appUserId}" is not a valid UUID (likely an anonymous RevenueCat ID). Please ensure Purchases.logIn() is called upon user authentication.`,
      );

      return jsonResponse({
        success: false,
        message: "Skipped activation: app_user_id is not a valid UUID",
      });
    }

    console.log(`Finding pending product for user UUID ${appUserId}`);

    const {
      data: pendingProduct,
      error: fetchError,
    } = await supabase
      .from("products")
      .select("id")
      .eq("seller_id", appUserId)
      .eq("status", "pending_payment")
      .order("created_at", {
        ascending: false,
      })
      .limit(1)
      .maybeSingle();

    if (fetchError) {
      throw fetchError;
    }

    if (!pendingProduct) {
      console.log(`No pending products for ${appUserId}`);

      return jsonResponse({
        success: true,
        message: "No pending products found",
      });
    }

    console.log(`Activating product ${pendingProduct.id}`);

    const { error: updateError } = await supabase
      .from("products")
      .update({
        status: "active",
      })
      .eq("id", pendingProduct.id);

    if (updateError) {
      throw updateError;
    }

    return jsonResponse({
      success: true,
      message: "Payment verified and product activated",
    });
  } catch (error) {
    console.error("RevenueCat Webhook Error:", error);

    return jsonResponse(
      {
        error: error instanceof Error ? error.message : "Unknown error",
      },
      500,
    );
  }
});
