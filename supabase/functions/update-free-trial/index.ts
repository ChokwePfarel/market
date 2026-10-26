import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");

    if (!supabaseUrl) {
      throw new Error("SUPABASE_URL missing");
    }

    if (!anonKey) {
      throw new Error("SUPABASE_ANON_KEY missing");
    }

    // Authenticate user
    const authHeader = req.headers.get("Authorization");

    if (!authHeader) {
      return jsonResponse(
        { error: "Missing Authorization header" },
        401,
      );
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: {
        headers: {
          Authorization: authHeader,
        },
      },
    });

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();

    if (userError || !user) {
      return jsonResponse(
        { error: "Unauthorized: Invalid token" },
        401,
      );
    }

    const userId = user.id;

    const { error: updateError } = await userClient
      .from("profiles")
      .update({ has_free_trial: false })
      .eq("id", userId);

    if (updateError) {
      throw updateError;
    }

    return jsonResponse(
      {
        success: true,
        message: "Free trial status updated",
      },
      200,
    );
  } catch (error) {
    return jsonResponse(
      {
        error: error instanceof Error
          ? error.message
          : "Unknown error",
      },
      500,
    );
  }
});

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