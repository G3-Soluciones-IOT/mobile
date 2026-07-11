import 'dart:ui';

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.period,
    required this.features,
    required this.isPopular,
    required this.pricePerDay,
  });

  final String id;
  final String name;
  final double price;
  final String currency;
  final String period;
  final List<String> features;
  final bool isPopular;
  final double pricePerDay;

  factory SubscriptionPlan.free() {
    return const SubscriptionPlan(
      id: 'free',
      name: 'Gratis',
      price: 0,
      currency: 'USD',
      period: 'FREE',
      features: [
        '✅ Recetas básicas',
        '✅ Seguir plan del nutricionista',
        '✅ Registrar comidas manualmente',
        '✅ Conectar dispositivos IoT',
        '❌ Recomendaciones IA',
        '❌ Análisis avanzado de datos',
        '❌ Recetas premium',
      ],
      isPopular: false,
      pricePerDay: 0,
    );
  }

  factory SubscriptionPlan.monthly() {
    return const SubscriptionPlan(
      id: 'monthly',
      name: 'Premium Mensual',
      price: 19.9,
      currency: 'USD',
      period: 'MONTHLY',
      features: [
        '✅ Todas las funcionalidades Free',
        '✅ Recomendaciones con IA personalizadas',
        '✅ Análisis nutricional avanzado',
        '✅ Recetas exclusivas',
        '✅ Planes automáticos basados en objetivos',
        '✅ Notificaciones predictivas',
        '✅ Reportes detallados',
        '✅ Prioridad en soporte',
      ],
      isPopular: true,
      pricePerDay: 0.66,
    );
  }

  factory SubscriptionPlan.annual() {
    return const SubscriptionPlan(
      id: 'annual',
      name: 'Premium Anual',
      price: 199.0,
      currency: 'USD',
      period: 'ANNUAL',
      features: [
        '✅ Todas las funcionalidades Free',
        '✅ Recomendaciones con IA personalizadas',
        '✅ Análisis nutricional avanzado',
        '✅ Recetas exclusivas',
        '✅ Planes automáticos basados en objetivos',
        '✅ Notificaciones predictivas',
        '✅ Reportes detallados',
        '✅ Prioridad en soporte',
        '✅ Ahorra 33% vs plan mensual',
        '✅ 2 meses gratis',
      ],
      isPopular: false,
      pricePerDay: 6.63,
    );
  }

  static List<SubscriptionPlan> get allPlans {
    return [
      SubscriptionPlan.free(),
      SubscriptionPlan.monthly(),
      SubscriptionPlan.annual(),
    ];
  }
}

class UserSubscription {
  const UserSubscription({
    required this.id,
    required this.userId,
    required this.planType,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.autoRenew,
  });

  final int id;
  final int userId;
  final String planType;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final bool autoRenew;

  bool get isActive => status == 'ACTIVE' && endDate.isAfter(DateTime.now());
  bool get isPremium => planType != 'FREE' && isActive;
  bool get isFree => planType == 'FREE' || !isActive;
  bool get isExpired => status == 'EXPIRED' || endDate.isBefore(DateTime.now());

  int get daysRemaining {
    if (isExpired) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  String get statusDisplay {
    if (isActive) return 'Activo';
    if (isExpired) return 'Expirado';
    return 'Cancelado';
  }
}

class Invoice {
  const Invoice({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.date,
    required this.description,
    required this.invoiceUrl,
  });

  final int id;
  final double amount;
  final String currency;
  final String status;
  final DateTime date;
  final String description;
  final String? invoiceUrl;

  String get statusDisplay {
    switch (status) {
      case 'PAID':
        return 'Pagado';
      case 'PENDING':
        return 'Pendiente';
      case 'FAILED':
        return 'Fallido';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'PAID':
        return const Color(0xFF16B548);
      case 'PENDING':
        return const Color(0xFFFF9900);
      case 'FAILED':
        return const Color(0xFFE46B6B);
      default:
        return const Color(0xFF74819A);
    }
  }
}
