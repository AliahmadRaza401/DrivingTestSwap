import 'dart:convert';
import 'dart:developer';
import 'package:drivingtestswap/core/constants/stripe_key.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';

class StripePaymentController extends GetxController {
  var isLoading = false.obs;

  Future<void> initPaymentSheet({
    required String amount,
    required String currency,
    required String merchantName,
  }) async {
    try {
      isLoading.value = true;
      log(' Creating payment intent for $amount $currency');
      final paymentIntent = await _createPaymentIntent(amount, currency);
      log(' Payment intent created: ${paymentIntent['id']}');

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: merchantName,
          style: ThemeMode.light,
        ),
      );
      log(' Payment sheet initialized successfully');
      isLoading.value = false;
    } catch (e, stack) {
      isLoading.value = false;
      log(' Stripe initPaymentSheet Error: $e');
      log(' Stack trace: $stack');
      rethrow;
    }
  }

  Future<void> presentPaymentSheet() async {
    try {
      log(' Presenting payment sheet...');
      await Stripe.instance.presentPaymentSheet();
      log(' Payment completed successfully');
    } on StripeException catch (e) {
      log(' StripeException: ${e.error.localizedMessage}');
      rethrow;
    } catch (e, stack) {
      log(' Unknown presentPaymentSheet error: $e');
      log(' Stack trace: $stack');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent(
    String amount,
    String currency,
  ) async {
    try {
      final intAmount = (double.parse(amount) * 100).toInt();
      log("Creating payment intent for $amount $currency");
      final body = {
        'amount': intAmount.toString(),
        'currency': currency,
        'payment_method_types[]': 'card',
      };

      log(' Creating Stripe PaymentIntent...');
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        log(' PaymentIntent response: ${response.body}');
        return jsonDecode(response.body);
      } else {
        log(' Stripe API error (${response.statusCode}): ${response.body}');
        throw Exception('Failed to create Payment Intent: ${response.body}');
      }
    } catch (e, stack) {
      log(' catch error in _createPaymentIntent: $e');
      log(' Stack trace: $stack');
      rethrow;
    }
  }
}
