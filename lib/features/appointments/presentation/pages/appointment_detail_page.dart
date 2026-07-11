import 'package:flutter/material.dart';
import 'package:jameofit/app/theme/app_theme.dart';
import 'package:jameofit/features/appointments/domain/entities/appointment_entities.dart';
import 'package:jameofit/features/appointments/domain/repositories/appointment_repository.dart';

class AppointmentDetailPage extends StatefulWidget {
  const AppointmentDetailPage({
    super.key,
    required this.repository,
    required this.appointmentId,
  });

  final AppointmentRepository repository;
  final int appointmentId;

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  Appointment? _appointment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointment();
  }

  Future<void> _loadAppointment() async {
    setState(() => _isLoading = true);
    try {
      final appointment = await widget.repository
          .getAppointmentDetail(widget.appointmentId);
      setState(() {
        _appointment = appointment;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Detalle de Cita',
          style: TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppTheme.brandGreen),
      )
          : _appointment == null
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.muted),
          const SizedBox(height: 16),
          const Text(
            'No se pudo cargar la cita',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAppointment,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final appointment = _appointment!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatusCard(appointment),
          const SizedBox(height: 16),
          _buildInfoCard(appointment),
          const SizedBox(height: 16),
          _buildActionButtons(appointment),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Appointment appointment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: appointment.statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(appointment.status),
              color: appointment.statusColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            appointment.statusLabel,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: appointment.statusColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(appointment.scheduledAt),
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Appointment appointment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            icon: Icons.person,
            label: 'Nutricionista',
            value: appointment.nutritionistName ??
                'ID: ${appointment.nutritionistId}',
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.access_time,
            label: 'Hora',
            value: _formatTime(appointment.scheduledAt),
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.timer,
            label: 'Duración',
            value: '${appointment.durationMinutes} minutos',
          ),
          if (appointment.reason.isNotEmpty) ...[
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.description,
              label: 'Motivo',
              value: appointment.reason,
              isMultiLine: true,
            ),
          ],
          if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.note,
              label: 'Notas',
              value: appointment.notes!,
              isMultiLine: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMultiLine = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, color: AppTheme.muted, size: 20),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.muted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Appointment appointment) {
    if (appointment.status == 'REQUESTED') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancelar cita'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.brandGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Abrir chat'),
            ),
          ),
        ],
      );
    }

    if (appointment.status == 'CONFIRMED' || appointment.status == 'COMPLETED') {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.brandGreen,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Abrir chat con nutricionista'),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'REQUESTED':
        return Icons.pending;
      case 'CONFIRMED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      case 'CANCELLED':
        return Icons.block;
      case 'COMPLETED':
        return Icons.done_all;
      default:
        return Icons.info;
    }
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
