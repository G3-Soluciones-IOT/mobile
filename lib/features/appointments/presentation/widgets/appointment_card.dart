import 'package:flutter/material.dart';
import 'package:jameofit/app/theme/app_theme.dart';
import 'package:jameofit/features/appointments/domain/entities/appointment_entities.dart';

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.onTap,
  });

  final Appointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.nutritionistName ??
                              'Nutricionista #${appointment.nutritionistId}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _formatDate(appointment.scheduledAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: appointment.statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      appointment.statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: appointment.statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppTheme.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(appointment.scheduledAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.muted,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.timer,
                    size: 16,
                    color: AppTheme.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${appointment.durationMinutes} min',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
              if (appointment.reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  appointment.reason,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.muted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.softGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.person,
        color: AppTheme.brandGreen,
        size: 24,
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

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
