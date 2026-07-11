import 'dart:async';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:jameofit/features/payments/domain/entities/payment_entities.dart';
import 'package:jameofit/features/payments/domain/repositories/payment_repository.dart';
import 'package:jameofit/features/payments/presentation/bloc/payment_event.dart';
import 'package:jameofit/features/payments/presentation/bloc/payment_state.dart';

import '../../data/datasources/payment_data_source.dart';

class PaymentBloc {
  PaymentBloc({required this.repository}) {
    _eventSubscription = _eventController.stream.listen(_handleEvent);
    add(const CheckSubscriptionStatus());
  }

  final PaymentRepository repository;
  final _eventController = StreamController<PaymentEvent>();
  final _stateController = StreamController<PaymentState>.broadcast();

  late final StreamSubscription<PaymentEvent> _eventSubscription;

  PaymentState _state = const PaymentInitial();

  PaymentState get state => _state;

  Stream<PaymentState> get stream => _stateController.stream;

  void add(PaymentEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  Future<void> _handleEvent(PaymentEvent event) async {
    if (event is CheckSubscriptionStatus) {
      await _checkSubscription();
    } else if (event is LoadSubscriptionDetails) {
      await _loadSubscriptionDetails();
    } else if (event is CreateSubscription) {
      await _createSubscription(event);
    } else if (event is CancelSubscription) {
      await _cancelSubscription(event);
    } else if (event is RenewSubscription) {
      await _renewSubscription(event);
    } else if (event is LoadInvoices) {
      await _loadInvoices();
    } else if (event is ResetPaymentState) {
      _emit(const PaymentInitial());
    }
  }

  Future<void> _checkSubscription() async {
    try {
      final isPremium = await repository.checkActiveSubscription();
      final subscription = await repository.getSubscriptionDetails();
      final invoices = await repository.getInvoices();

      _emit(PaymentLoaded(
        isPremium: isPremium,
        subscription: subscription,
        plans: SubscriptionPlan.allPlans,
        invoices: invoices,
      ));
    } catch (e) {
      _emit(PaymentFailure(message: e.toString()));
    }
  }

  Future<void> _loadSubscriptionDetails() async {
    try {
      final subscription = await repository.getSubscriptionDetails();
      final currentState = _state;
      if (currentState is PaymentLoaded) {
        _emit(currentState.copyWith(subscription: subscription));
      }
    } catch (e) {
      _emit(PaymentFailure(message: e.toString()));
    }
  }

  Future<void> _createSubscription(CreateSubscription event) async {
    try {
      final currentState = _state;
      if (currentState is PaymentLoaded && currentState.subscription != null) {
        try {
          await repository.cancelSubscription(currentState.subscription!.id);
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          // Ignorar error al cancelar
        }
      }

      await repository.createSubscription(
        planType: event.planType,
        billingCycle: event.billingCycle,
      );

      await _checkSubscription();

      _emit(PaymentSuccess(
        message: '¡Suscripción activada exitosamente! 🎉',
      ));
    } on StripeException catch (e) {
      await _checkSubscription();
      final currentState = _state;
      if (currentState is PaymentLoaded && currentState.isPremium) {
        _emit(PaymentSuccess(
          message: '¡Suscripción activada exitosamente! 🎉',
        ));
      } else {
        _emit(PaymentFailure(
          message: 'Error en el pago: ${e.error.localizedMessage ?? 'Intenta nuevamente'}',
        ));
      }
    } on PaymentException catch (e) {
      if (e.message.contains('409') || e.message.contains('already has an active subscription')) {
        await _checkSubscription();
        final currentState = _state;
        if (currentState is PaymentLoaded && currentState.isPremium) {
          _emit(PaymentSuccess(
            message: 'Ya tienes una suscripción activa. ✅',
          ));
        } else {
          _emit(PaymentFailure(
            message: 'Ya tienes una suscripción activa. Revisa "Mis Suscripciones".',
          ));
        }
      } else {
        _emit(PaymentFailure(message: e.message));
      }
    } catch (e) {
      await _checkSubscription();
      final currentState = _state;
      if (currentState is PaymentLoaded && currentState.isPremium) {
        _emit(PaymentSuccess(
          message: '¡Suscripción activada exitosamente! 🎉',
        ));
      } else {
        _emit(PaymentFailure(
          message: 'Error al procesar el pago. Intenta nuevamente.',
        ));
      }
    }
  }

  Future<void> _cancelSubscription(CancelSubscription event) async {
    try {
      await repository.cancelSubscription(event.subscriptionId);
      await Future.delayed(const Duration(milliseconds: 800));
      await _checkSubscription();
      _emit(PaymentSuccess(
        message: 'Suscripción cancelada exitosamente',
      ));
    } catch (e) {
      await _checkSubscription();
      _emit(PaymentFailure(message: 'Error al cancelar la suscripción: $e'));
    }
  }

  Future<void> _renewSubscription(RenewSubscription event) async {
    try {
      await repository.renewSubscription(event.subscriptionId);
      await _checkSubscription();
      _emit(PaymentSuccess(
        message: 'Suscripción renovada exitosamente',
      ));
    } catch (e) {
      await _checkSubscription();
      _emit(PaymentFailure(message: 'Error al renovar la suscripción: $e'));
    }
  }

  Future<void> _loadInvoices() async {
    try {
      final invoices = await repository.getInvoices();
      final currentState = _state;
      if (currentState is PaymentLoaded) {
        _emit(currentState.copyWith(invoices: invoices));
      }
    } catch (e) {
      _emit(PaymentFailure(message: 'Error al cargar facturas: $e'));
    }
  }

  void _emit(PaymentState state) {
    _state = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  void close() {
    _eventSubscription.cancel();
    _eventController.close();
    _stateController.close();
  }
}
