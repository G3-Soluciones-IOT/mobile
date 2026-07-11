import 'package:flutter/material.dart';
import 'package:jameofit/app/theme/app_theme.dart';

class EmptyAppointments extends StatelessWidget {
  const EmptyAppointments({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: AppTheme.muted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'No tienes citas programadas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agenda una cita con un nutricionista',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
            },
            icon: const Icon(Icons.add),
            label: const Text('Agendar cita'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.brandGreen,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
