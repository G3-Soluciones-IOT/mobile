abstract class PaymentEvent {
  const PaymentEvent();
}

class CheckSubscriptionStatus extends PaymentEvent {
  const CheckSubscriptionStatus();
}

class LoadSubscriptionDetails extends PaymentEvent {
  const LoadSubscriptionDetails();
}

class CreateSubscription extends PaymentEvent {
  const CreateSubscription({
    required this.planType,
    required this.billingCycle,
  });
  final String planType;
  final String billingCycle;
}

class CancelSubscription extends PaymentEvent {
  const CancelSubscription({required this.subscriptionId});
  final int subscriptionId;
}

class RenewSubscription extends PaymentEvent {
  const RenewSubscription({required this.subscriptionId});
  final int subscriptionId;
}

class LoadInvoices extends PaymentEvent {
  const LoadInvoices();
}

class ResetPaymentState extends PaymentEvent {
  const ResetPaymentState();
}
