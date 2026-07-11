import 'package:flutter/material.dart';
import 'package:jameofit/app/theme/app_theme.dart';
import 'package:jameofit/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:jameofit/features/payments/presentation/bloc/payment_state.dart';

class PaymentHistoryPage extends StatelessWidget {
  const PaymentHistoryPage({
    super.key,
    required this.bloc,
  });

  final PaymentBloc bloc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Historial de Pagos',
          style: TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.ink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<PaymentState>(
        stream: bloc.stream,
        initialData: bloc.state,
        builder: (context, snapshot) {
          final state = snapshot.data;

          if (state is PaymentLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.brandGreen),
            );
          }

          if (state is PaymentLoaded) {
            if (state.invoices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: AppTheme.muted,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay facturas disponibles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tus pagos aparecerán aquí',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.invoices.length,
              itemBuilder: (context, index) {
                final invoice = state.invoices[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: invoice.statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                invoice.status == 'PAID'
                                    ? Icons.check_circle
                                    : invoice.status == 'PENDING'
                                    ? Icons.pending
                                    : Icons.error_outline,
                                color: invoice.statusColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    invoice.description,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '${invoice.date.day}/${invoice.date.month}/${invoice.date.year}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${invoice.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: invoice.statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    invoice.statusDisplay,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: invoice.statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (invoice.invoiceUrl != null) ...[
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () {},
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.picture_as_pdf,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Ver factura PDF',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.skyBlue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
