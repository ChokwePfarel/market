import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

abstract class PaymentRemoteDataSource {
  Future<String> createCheckoutSession(int amountInCents, String productId);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final http.Client client;

  PaymentRemoteDataSourceImpl({required this.client});

  @override
  Future<String> createCheckoutSession(int amountInCents, String productId) async {
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || anonKey == null) {
      throw Exception('Supabase credentials not found in .env');
    }

    debugPrint('PaymentRemoteDataSource: Calling Supabase Edge Function to create YOCO checkout...');
    
    final response = await client.post(
      Uri.parse('$supabaseUrl/functions/v1/create-yoco-checkout'),
      headers: {
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': amountInCents,
        'productId': productId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['redirectUrl'] as String;
    } else {
      debugPrint('Edge Function Error Response: ${response.body}');
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to generate payment link');
    }
  }
}
