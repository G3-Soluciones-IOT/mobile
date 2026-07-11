import 'package:flutter/material.dart';
import 'package:jameofit/app/theme/app_theme.dart';
import 'package:jameofit/features/appointments/domain/entities/appointment_entities.dart';
import 'package:jameofit/features/appointments/presentation/pages/nutritionist_selection_page.dart';
import 'package:jameofit/features/appointments/presentation/pages/appointment_detail_page.dart';
import 'package:jameofit/features/appointments/presentation/widgets/appointment_card.dart';
import 'package:jameofit/features/appointments/presentation/widgets/empty_appointments.dart';
import 'package:jameofit/features/appointments/presentation/pages/my_nutritionists_page.dart';

import '../../domain/repositories/appointment_repository.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({
    super.key,
    required this.repository,
    required this.userId,
  });

  final AppointmentRepository repository;
  final int userId;

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  String _selectedStatus = 'Todas';
  final List<String> _filterTabs = ['Todas', 'Solicitadas', 'Confirmadas', 'Completadas'];

  String _getStatusValue(String filter) {
    switch (filter) {
      case 'Solicitadas':
        return 'REQUESTED';
      case 'Confirmadas':
        return 'CONFIRMED';
      case 'Completadas':
        return 'COMPLETED';
      default:
        return '';
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
          'Mis Citas',
          style: TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people, color: AppTheme.brandGreen),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyNutritionistsPage(
                    repository: widget.repository,
                    userId: widget.userId,
                  ),
                ),
              );
            },
            tooltip: 'Mis nutricionistas',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterTabs(),
          Expanded(
            child: _buildAppointmentsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NutritionistSelectionPage(
                repository: widget.repository,
                userId: widget.userId,
                mode: SelectionMode.appointment,
              ),
            ),
          );
        },
        backgroundColor: AppTheme.brandGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva cita',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.brandGreen,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gestiona tus citas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Agenda y administra tus consultas',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: _filterTabs.map((label) {
          final isSelected = _selectedStatus == label;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStatus = label;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.brandGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.muted,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 30));
    final to = now.add(const Duration(days: 60));

    final statusFilter = _getStatusValue(_selectedStatus);

    return FutureBuilder<List<Appointment>>(
      future: widget.repository.getMyAppointments(
        status: statusFilter.isEmpty ? null : statusFilter,
        from: from,
        to: to,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.brandGreen),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppTheme.muted,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar las citas',
                  style: TextStyle(color: AppTheme.muted),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final appointments = snapshot.data ?? [];

        if (appointments.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            return AppointmentCard(
              appointment: appointment,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AppointmentDetailPage(
                      repository: widget.repository,
                      appointmentId: appointment.id,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String message = 'No tienes citas programadas';
    String subMessage = 'Agenda una cita con un nutricionista';

    if (_selectedStatus != 'Todas') {
      message = 'No hay citas ${_selectedStatus.toLowerCase()}';
      subMessage = 'Cambia el filtro para ver otras citas';
    }

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
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subMessage,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.muted,
            ),
          ),
          if (_selectedStatus == 'Todas') ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NutritionistSelectionPage(
                      repository: widget.repository,
                      userId: widget.userId,
                      mode: SelectionMode.appointment,
                    ),
                  ),
                );
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
        ],
      ),
    );
  }
}
