import 'package:jameofit/features/payments/domain/entities/payment_entities.dart';

abstract class PaymentState {
  const PaymentState();
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

class PaymentLoaded extends PaymentState {
  const PaymentLoaded({
    required this.isPremium,
    this.subscription,
    this.plans = const [],
    this.invoices = const [],
  });

  final bool isPremium;
  final UserSubscription? subscription;
  final List<SubscriptionPlan> plans;
  final List<Invoice> invoices;

  PaymentLoaded copyWith({
    bool? isPremium,
    UserSubscription? subscription,
    List<SubscriptionPlan>? plans,
    List<Invoice>? invoices,
  }) {
    return PaymentLoaded(
      isPremium: isPremium ?? this.isPremium,
      subscription: subscription ?? this.subscription,
      plans: plans ?? this.plans,
      invoices: invoices ?? this.invoices,
    );
  }
}

class PaymentSuccess extends PaymentState {
  const PaymentSuccess({required this.message, this.subscription});
  final String message;
  final UserSubscription? subscription;
}

class PaymentFailure extends PaymentState {
  const PaymentFailure({required this.message});
  final String message;
}
