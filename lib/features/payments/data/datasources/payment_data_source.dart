import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:jameofit/core/microservice_endpoints.dart';
import 'package:jameofit/features/payments/domain/entities/payment_entities.dart';

class PaymentDataSource {
  PaymentDataSource({
    required this.userId,
    this.authToken,
    http.Client? client,
  }) : _client = client;

  static const _requestTimeout = Duration(seconds: 30);

  final int userId;
  final String? authToken;
  final http.Client? _client;

  http.Client get client => _client ?? http.Client();

  Map<String, String> get _headers {
    final token = authToken?.trim();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> checkActiveSubscription() async {
    try {
      final url = MicroserviceEndpoints.subscriptionActive
          .replaceFirst('{userId}', userId.toString());
      final response = await client
          .get(Uri.parse(url), headers: _headers)
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final status = json['status'] ?? 'INACTIVE';
        final isActive = status == 'ACTIVE';
        final plan = json['plan'] as Map<String, dynamic>?;
        final planType = plan?['planType'] ?? 'FREE';
        final isPremium = isActive && planType == 'PREMIUM';
        return isPremium;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<UserSubscription?> getSubscriptionDetails() async {
    try {
      final url = MicroserviceEndpoints.subscriptionActive
          .replaceFirst('{userId}', userId.toString());
      final response = await client
          .get(Uri.parse(url), headers: _headers)
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final plan = json['plan'] as Map<String, dynamic>?;
        final planType = plan?['planType'] ?? 'FREE';

        return UserSubscription(
          id: json['id'] ?? 0,
          userId: userId,
          planType: planType,
          status: json['status'] ?? 'INACTIVE',
          startDate: DateTime.parse(json['startedAt'] ?? DateTime.now().toIso8601String()),
          endDate: DateTime.parse(json['currentPeriodEnd'] ?? DateTime.now().toIso8601String()),
          autoRenew: true,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createSubscription({
    required String planType,
    required String billingCycle,
  }) async {
    final paymentIntent = await _createPaymentIntent(
      planType: planType,
      billingCycle: billingCycle,
    );

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: paymentIntent['clientSecret']!,
        merchantDisplayName: 'JameoFit',
        style: ThemeMode.light,
        applePay: const PaymentSheetApplePay(
          merchantCountryCode: 'US',
        ),
        googlePay: const PaymentSheetGooglePay(
          merchantCountryCode: 'US',
          testEnv: true,
        ),
      ),
    );

    await Stripe.instance.presentPaymentSheet();
    return paymentIntent;
  }

  Future<Map<String, dynamic>> _createPaymentIntent({
    required String planType,
    required String billingCycle,
  }) async {
    final url = MicroserviceEndpoints.subscriptions;

    String backendPlanType;
    if (planType == 'FREE') {
      backendPlanType = 'FREE';
    } else {
      backendPlanType = 'PREMIUM';
    }

    String backendBillingCycle;
    if (billingCycle == 'ANNUAL') {
      backendBillingCycle = 'ANNUALLY';
    } else {
      backendBillingCycle = 'MONTHLY';
    }

    final body = jsonEncode({
      'userId': userId,
      'planType': backendPlanType,
      'billingCycle': backendBillingCycle,
    });

    final response = await client
        .post(
      Uri.parse(url),
      headers: _headers,
      body: body,
    )
        .timeout(_requestTimeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data.containsKey('stripeClientSecret')) {
        return {
          'clientSecret': data['stripeClientSecret'],
          'paymentIntentId': data['stripePaymentIntentId'] ?? '',
          'subscriptionId': data['id'] ?? 0,
          'data': data,
        };
      } else {
        throw PaymentException(
          'El backend no devolvió stripeClientSecret. Respuesta: $data',
        );
      }
    }

    if (response.statusCode == 400) {
      throw PaymentException(
        'Error en la solicitud: Verifica que los datos sean correctos. ${response.body}',
      );
    }

    throw PaymentException(
      'Error al crear la suscripción: ${response.statusCode} - ${response.body}',
    );
  }

  Future<void> cancelSubscription(int subscriptionId) async {
    final url = MicroserviceEndpoints.subscriptionCancel
        .replaceFirst('{subscriptionId}', subscriptionId.toString());
    final response = await client
        .post(Uri.parse(url), headers: _headers)
        .timeout(_requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PaymentException(
        'Error al cancelar la suscripción: ${response.statusCode}',
      );
    }
  }

  Future<void> renewSubscription(int subscriptionId) async {
    final url = MicroserviceEndpoints.subscriptionRenew
        .replaceFirst('{subscriptionId}', subscriptionId.toString());
    final response = await client
        .post(Uri.parse(url), headers: _headers)
        .timeout(_requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PaymentException(
        'Error al renovar la suscripción: ${response.statusCode}',
      );
    }
  }

  Future<List<Invoice>> getInvoices() async {
    try {
      final url = MicroserviceEndpoints.invoices
          .replaceFirst('{userId}', userId.toString());
      final response = await client
          .get(Uri.parse(url), headers: _headers)
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json is List) {
          return json.map((invoice) {
            final map = invoice as Map<String, dynamic>;
            return Invoice(
              id: map['id'] ?? 0,
              amount: (map['amount'] as num?)?.toDouble() ?? 0,
              currency: map['currency'] ?? 'USD',
              status: map['status'] ?? 'PAID',
              date: DateTime.parse(map['issuedAt'] ?? DateTime.now().toIso8601String()),
              description: 'Suscripción #${map['subscriptionId'] ?? ''}',
              invoiceUrl: null,
            );
          }).toList();
        } else if (json is Map<String, dynamic> && json.containsKey('content')) {
          final invoices = json['content'] as List<dynamic>? ?? [];
          return invoices.map((invoice) {
            final map = invoice as Map<String, dynamic>;
            return Invoice(
              id: map['id'] ?? 0,
              amount: (map['amount'] as num?)?.toDouble() ?? 0,
              currency: map['currency'] ?? 'USD',
              status: map['status'] ?? 'PAID',
              date: DateTime.parse(map['issuedAt'] ?? DateTime.now().toIso8601String()),
              description: 'Suscripción #${map['subscriptionId'] ?? ''}',
              invoiceUrl: null,
            );
          }).toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> checkPremiumAccess() async {
    try {
      final url = MicroserviceEndpoints.premiumAccess
          .replaceFirst('{userId}', userId.toString());
      final response = await client
          .get(Uri.parse(url), headers: _headers)
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['hasPremiumAccess'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

class PaymentException implements Exception {
  PaymentException(this.message);
  final String message;

  @override
  String toString() => message;
}
