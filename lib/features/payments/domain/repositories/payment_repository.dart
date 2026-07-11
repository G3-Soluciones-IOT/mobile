import 'package:jameofit/features/payments/domain/entities/payment_entities.dart';

abstract class PaymentRepository {
  Future<bool> checkActiveSubscription();
  Future<UserSubscription?> getSubscriptionDetails();
  Future<Map<String, dynamic>> createSubscription({
    required String planType,
    required String billingCycle,
  });
  Future<void> cancelSubscription(int subscriptionId);
  Future<void> renewSubscription(int subscriptionId);
  Future<List<Invoice>> getInvoices();
  Future<bool> checkPremiumAccess();
}
