import 'package:flutter/material.dart';
import 'package:jameofit/app/theme/app_theme.dart';
import 'package:jameofit/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:jameofit/features/payments/presentation/bloc/payment_event.dart';
import 'package:jameofit/features/payments/presentation/bloc/payment_state.dart';
import 'package:jameofit/features/payments/presentation/pages/subscription_plans_page.dart';
import 'package:jameofit/features/payments/presentation/pages/payment_history_page.dart';

import '../../domain/entities/payment_entities.dart';

class MySubscriptionsPage extends StatelessWidget {
  const MySubscriptionsPage({
    super.key,
    required this.bloc,
  });

  final PaymentBloc bloc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Suscripción',
          style: TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, color: AppTheme.ink),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentHistoryPage(bloc: bloc),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<PaymentState>(
        stream: bloc.stream,
        initialData: bloc.state,
        builder: (context, snapshot) {
          final state = snapshot.data;

          if (state == null || state is PaymentLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.brandGreen),
            );
          }

          if (state is PaymentSuccess) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
              bloc.add(const CheckSubscriptionStatus());
            });
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.brandGreen),
            );
          }

          if (state is PaymentFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.ink),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      bloc.add(const CheckSubscriptionStatus());
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is PaymentLoaded) {
            final isPremium = state.isPremium;
            final subscription = state.subscription;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusHeader(isPremium, subscription),
                  const SizedBox(height: 24),
                  _buildCurrentPlanCard(isPremium, subscription),
                  const SizedBox(height: 24),
                  _buildBenefitsSection(isPremium),
                  const SizedBox(height: 24),
                  _buildActionButton(isPremium, context),
                  const SizedBox(height: 12),
                  _buildFooter(isPremium, subscription, context),
                ],
              ),
            );
          }

          return const Center(
            child: CircularProgressIndicator(color: AppTheme.brandGreen),
          );
        },
      ),
    );
  }

  Widget _buildStatusHeader(bool isPremium, UserSubscription? subscription) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPremium
              ? [
            const Color(0xFF16B548),
            const Color(0xFF0D8C3A),
          ]
              : [
            const Color(0xFF6C7A8A),
            const Color(0xFF4A5568),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPremium ? AppTheme.brandGreen : Colors.grey).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isPremium ? Icons.verified : Icons.star_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPremium ? 'Plan Premium' : 'Plan Gratuito',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPremium
                          ? 'Disfrutas de todas las funcionalidades'
                          : 'Mejora tu experiencia con Premium',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${subscription?.daysRemaining ?? 0}d',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
          if (isPremium && subscription != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.calendar_today,
                  label: 'Renovación',
                  value: _formatDate(subscription.endDate),
                ),
                const SizedBox(width: 10),
                _buildInfoChip(
                  icon: Icons.autorenew,
                  label: 'Auto-renovación',
                  value: subscription.autoRenew ? 'Activada' : 'Desactivada',
                  valueColor: subscription.autoRenew
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: valueColor ?? Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard(bool isPremium, UserSubscription? subscription) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPremium
                  ? AppTheme.softGreen
                  : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPremium ? Icons.workspace_premium : Icons.free_breakfast,
              color: isPremium ? AppTheme.brandGreen : Colors.grey,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium
                      ? 'Plan ${subscription?.planType ?? 'Premium'}'
                      : 'Plan Gratis',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isPremium
                      ? 'Próximo cobro: ${_formatDate(subscription?.endDate ?? DateTime.now())}'
                      : 'Sin costo · Funcionalidades básicas',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.muted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isPremium ? AppTheme.softGreen : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isPremium ? 'Activo' : 'Gratis',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isPremium ? AppTheme.brandGreen : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(bool isPremium) {
    final benefits = isPremium
        ? [
      'Recomendaciones IA personalizadas',
      'Análisis nutricional avanzado',
      'Recetas exclusivas',
      'Planes automáticos personalizados',
      'Notificaciones predictivas de hidratación',
      'Reportes detallados de progreso',
      'Prioridad en soporte técnico',
    ]
        : [
      '✅ Recetas básicas',
      '✅ Seguir plan del nutricionista',
      '✅ Registrar comidas manualmente',
      '✅ Conectar dispositivos IoT',
      '❌ Recomendaciones IA',
      '❌ Análisis avanzado de datos',
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPremium ? Icons.star : Icons.info_outline,
                color: isPremium ? Colors.amber : AppTheme.muted,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isPremium ? 'Beneficios Premium' : 'Qué incluye tu plan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (!isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${benefits.where((b) => b.startsWith('✅')).length}/${benefits.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...benefits.map(
                (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    feature.contains('✅')
                        ? Icons.check_circle
                        : feature.contains('❌')
                        ? Icons.cancel
                        : Icons.star,
                    size: 18,
                    color: feature.contains('✅')
                        ? AppTheme.brandGreen
                        : feature.contains('❌')
                        ? Colors.grey.shade400
                        : Colors.amber,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature.replaceAll('✅ ', '').replaceAll('❌ ', ''),
                      style: TextStyle(
                        fontSize: 13.5,
                        color: feature.contains('❌')
                            ? Colors.grey.shade400
                            : AppTheme.ink,
                        decoration: feature.contains('❌')
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isPremium, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubscriptionPlansPage(bloc: bloc),
            ),
          );
        },
        style: FilledButton.styleFrom(
          backgroundColor: isPremium ? Colors.white : AppTheme.brandGreen,
          foregroundColor: isPremium ? AppTheme.brandGreen : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isPremium ? AppTheme.brandGreen : Colors.transparent,
              width: 2,
            ),
          ),
          elevation: isPremium ? 0 : 4,
          shadowColor: isPremium
              ? Colors.transparent
              : AppTheme.brandGreen.withValues(alpha: 0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPremium ? Icons.swap_horiz : Icons.rocket_launch,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              isPremium ? 'Cambiar plan' : 'Actualizar a Premium',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isPremium, UserSubscription? subscription, BuildContext context) {
    return Column(
      children: [
        if (isPremium && subscription != null)
          TextButton.icon(
            onPressed: () => _showCancelDialog(context),
            icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
            label: const Text(
              'Cancelar suscripción',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security_outlined,
              size: 14,
              color: AppTheme.muted,
            ),
            const SizedBox(width: 6),
            Text(
              'Pagos seguros · Cancelas cuando quieras',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar suscripción'),
        content: const Text(
          '¿Estás seguro que deseas cancelar tu suscripción premium? '
              'Podrás seguir disfrutando de los beneficios hasta el final '
              'del período actual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Seguir con Premium'),
          ),
          FilledButton(
            onPressed: () {
              final state = bloc.state;
              if (state is PaymentLoaded && state.subscription != null) {
                bloc.add(
                  CancelSubscription(
                    subscriptionId: state.subscription!.id,
                  ),
                );
              }
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
