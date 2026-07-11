import 'package:jameofit/features/payments/data/datasources/payment_data_source.dart';
import 'package:jameofit/features/payments/domain/entities/payment_entities.dart';
import 'package:jameofit/features/payments/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl({required this.dataSource});

  final PaymentDataSource dataSource;

  @override
  Future<bool> checkActiveSubscription() {
    return dataSource.checkActiveSubscription();
  }

  @override
  Future<UserSubscription?> getSubscriptionDetails() {
    return dataSource.getSubscriptionDetails();
  }

  @override
  Future<Map<String, dynamic>> createSubscription({
    required String planType,
    required String billingCycle,
  }) {
    return dataSource.createSubscription(
      planType: planType,
      billingCycle: billingCycle,
    );
  }

  @override
  Future<void> cancelSubscription(int subscriptionId) {
    return dataSource.cancelSubscription(subscriptionId);
  }

  @override
  Future<void> renewSubscription(int subscriptionId) {
    return dataSource.renewSubscription(subscriptionId);
  }

  @override
  Future<List<Invoice>> getInvoices() {
    return dataSource.getInvoices();
  }

  @override
  Future<bool> checkPremiumAccess() {
    return dataSource.checkPremiumAccess();
  }
}
