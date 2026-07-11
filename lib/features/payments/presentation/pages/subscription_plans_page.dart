import 'package:flutter/material.dart';
import 'package:jameofit/app/theme/app_theme.dart';
import 'package:jameofit/features/payments/domain/entities/payment_entities.dart';
import 'package:jameofit/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:jameofit/features/payments/presentation/bloc/payment_event.dart';
import 'package:jameofit/features/payments/presentation/bloc/payment_state.dart';

class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({
    super.key,
    required this.bloc,
  });

  final PaymentBloc bloc;

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  int _selectedPlanIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.85);
  bool _loadingDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _listenToStateChanges();
  }

  void _listenToStateChanges() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.bloc.stream.listen((state) {
        if (state is PaymentLoading) {
          if (!_loadingDialogOpen && mounted) {
            _loadingDialogOpen = true;
            _showLoadingDialog(context);
          }
        } else if (state is PaymentSuccess || state is PaymentFailure) {
          if (_loadingDialogOpen && mounted) {
            _loadingDialogOpen = false;
            Navigator.of(context, rootNavigator: true).pop();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    if (_loadingDialogOpen) {
      _loadingDialogOpen = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Planes Premium',
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
      ),
      body: StreamBuilder<PaymentState>(
        stream: widget.bloc.stream,
        initialData: widget.bloc.state,
        builder: (context, snapshot) {
          final state = snapshot.data;

          if (state is PaymentLoading) {
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
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) Navigator.pop(context);
              });
            });
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.brandGreen,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '¡Operación exitosa!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Redirigiendo...',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
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
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.ink),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      widget.bloc.add(const CheckSubscriptionStatus());
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is PaymentLoaded) {
            final plans = state.plans;
            final isPremium = state.isPremium;

            return Column(
              children: [
                if (isPremium) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.softGreen,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.brandGreen),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified,
                            color: AppTheme.brandGreen,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🎉 ¡Ya eres Premium!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                if (state.subscription != null)
                                  Text(
                                    'Válido hasta ${_formatDate(state.subscription!.endDate)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.muted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Volver'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Elige el plan perfecto para ti',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Desbloquea todas las funcionalidades premium',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _selectedPlanIndex = index;
                            });
                          },
                          itemCount: plans.length,
                          itemBuilder: (context, index) {
                            final plan = plans[index];
                            final isSelected = _selectedPlanIndex == index;
                            final isCurrentPlan = isPremium &&
                                state.subscription?.planType == plan.period;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: isSelected ? 0 : 20,
                              ),
                              transform: Matrix4.identity()..scale(isSelected ? 1.0 : 0.95),
                              child: _PlanCard(
                                plan: plan,
                                isSelected: isSelected,
                                isCurrentPlan: isCurrentPlan,
                                onTap: () {
                                  _pageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          plans.length,
                              (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: _selectedPlanIndex == index ? 24 : 6,
                            decoration: BoxDecoration(
                              color: _selectedPlanIndex == index
                                  ? AppTheme.brandGreen
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isPremium
                                ? () => _handleSubscription(context)
                                : _selectedPlanIndex == 0
                                ? null
                                : () => _handleSubscription(context),
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
                              disabledBackgroundColor: Colors.grey.shade300,
                            ),
                            child: Text(
                              isPremium
                                  ? 'Cambiar plan'
                                  : _selectedPlanIndex == 0
                                  ? 'Plan gratuito actual'
                                  : 'Continuar con ${plans[_selectedPlanIndex].name}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isPremium ? AppTheme.brandGreen : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            );
          }

          return const Center(
            child: CircularProgressIndicator(color: AppTheme.brandGreen),
          );
        },
      ),
    );
  }

  void _handleSubscription(BuildContext context) {
    final currentState = widget.bloc.state;
    final plan = SubscriptionPlan.allPlans[_selectedPlanIndex];

    if (plan.period == 'FREE') {
      if (currentState is PaymentLoaded && !currentState.isPremium) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ℹ️ Ya estás en el plan gratuito'),
            backgroundColor: Colors.blue,
          ),
        );
        return;
      }
      if (currentState is PaymentLoaded && currentState.isPremium) {
        _showChangeToFreeDialog(context);
        return;
      }
      return;
    }

    if (currentState is PaymentLoaded && currentState.isPremium) {
      _showChangePlanDialog(context, plan);
      return;
    }

    if (currentState is PaymentLoaded && currentState.subscription != null) {
      _showUpgradeFromFreeDialog(context, plan);
      return;
    }

    _showPaymentModal(context, plan);
  }

  void _showChangeToFreeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar a plan Gratuito'),
        content: const Text(
          '¿Estás seguro que deseas cancelar tu suscripción Premium '
              'y cambiar al plan Gratuito? Perderás todas las funcionalidades premium.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              final state = widget.bloc.state;
              if (state is PaymentLoaded && state.subscription != null) {
                widget.bloc.add(
                  CancelSubscription(
                    subscriptionId: state.subscription!.id,
                  ),
                );
                Future.delayed(const Duration(milliseconds: 500), () {
                  widget.bloc.add(
                    CreateSubscription(
                      planType: 'FREE',
                      billingCycle: 'MONTHLY',
                    ),
                  );
                });
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cambiar a Gratis'),
          ),
        ],
      ),
    );
  }

  void _showChangePlanDialog(BuildContext context, SubscriptionPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar plan'),
        content: Text(
          '¿Deseas cambiar tu plan actual a "${plan.name}"? '
              'Tu suscripción actual será cancelada y se creará una nueva.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              final state = widget.bloc.state;
              if (state is PaymentLoaded && state.subscription != null) {
                widget.bloc.add(
                  CancelSubscription(
                    subscriptionId: state.subscription!.id,
                  ),
                );
                Future.delayed(const Duration(milliseconds: 500), () {
                  _showPaymentModal(context, plan);
                });
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.brandGreen,
            ),
            child: const Text('Cambiar plan'),
          ),
        ],
      ),
    );
  }

  void _showUpgradeFromFreeDialog(BuildContext context, SubscriptionPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Actualizar a Premium'),
        content: Text(
          'Actualmente tienes el plan Gratuito. '
              '¿Deseas actualizar a "${plan.name}" por \$${plan.price.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              final state = widget.bloc.state;
              if (state is PaymentLoaded && state.subscription != null) {
                widget.bloc.add(
                  CancelSubscription(
                    subscriptionId: state.subscription!.id,
                  ),
                );
                Future.delayed(const Duration(milliseconds: 500), () {
                  _showPaymentModal(context, plan);
                });
              } else {
                _showPaymentModal(context, plan);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.brandGreen,
            ),
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _showPaymentModal(BuildContext context, SubscriptionPlan plan) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isDismissible: false,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(
              Icons.verified,
              size: 48,
              color: AppTheme.brandGreen,
            ),
            const SizedBox(height: 12),
            const Text(
              'Confirmar suscripción',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Plan ${plan.name}',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${plan.price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.brandGreen,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.bloc.add(
                        CreateSubscription(
                          planType: plan.period,
                          billingCycle: plan.period,
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.brandGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                  'Pago seguro con Stripe',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppTheme.brandGreen,
            ),
            const SizedBox(height: 16),
            const Text(
              'Procesando pago...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esto puede tomar unos segundos',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.muted,
              ),
            ),
          ],
        ),
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.isCurrentPlan,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final bool isSelected;
  final bool isCurrentPlan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isFree = plan.period == 'FREE';
    final isPopular = plan.isPopular;
    final color = isFree ? AppTheme.muted : AppTheme.brandGreen;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppTheme.brandGreen : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.brandGreen.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Stack(
          children: [
            if (isPopular)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(24),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'MÁS POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isCurrentPlan)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.softGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Plan actual',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.brandGreen,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    plan.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!isFree) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${plan.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '/ ${plan.period.toLowerCase()}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${plan.pricePerDay.toStringAsFixed(2)}/día',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  ...plan.features.take(4).map(
                        (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            feature.contains('✅')
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 18,
                            color: feature.contains('✅')
                                ? AppTheme.brandGreen
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              feature.replaceAll('✅ ', '').replaceAll('❌ ', ''),
                              style: TextStyle(
                                fontSize: 13,
                                color: feature.contains('❌')
                                    ? Colors.grey.shade400
                                    : AppTheme.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (plan.features.length > 4) ...[
                    const SizedBox(height: 4),
                    Text(
                      '+${plan.features.length - 4} beneficios más',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
