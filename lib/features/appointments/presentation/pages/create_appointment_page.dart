import 'package:flutter/material.dart';
import 'package:jameofit/app/theme/app_theme.dart';
import 'package:jameofit/features/appointments/domain/entities/appointment_entities.dart';
import 'package:jameofit/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:collection/collection.dart';

class CreateAppointmentPage extends StatefulWidget {
  const CreateAppointmentPage({
    super.key,
    required this.repository,
    required this.nutritionist,
    required this.userId,
  });

  final AppointmentRepository repository;
  final Nutritionist nutritionist;
  final int userId;

  @override
  State<CreateAppointmentPage> createState() => _CreateAppointmentPageState();
}

class _CreateAppointmentPageState extends State<CreateAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  final _meetingUrlController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _durationMinutes = 30;
  String _serviceType = 'DIET_PLAN';
  bool _isSubmitting = false;

  final List<String> _serviceTypes = [
    'DIET_PLAN',
    'PERSONAL_CONSULT',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    _meetingUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.brandGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.brandGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final scheduledAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final relationships = await widget.repository
          .getNutritionistPatientsByPatient();
      final existingRelation = relationships.firstWhereOrNull(
            (r) => r.nutritionistId == widget.nutritionist.id && r.accepted,
      );

      int relationId;
      if (existingRelation != null) {
        relationId = existingRelation.id;
      } else {
        final relation = await widget.repository.createNutritionistPatient(
          nutritionistId: widget.nutritionist.id,
          serviceType: _serviceType,
          startDate: DateTime.now(),
          scheduledAt: scheduledAt,
        );
        relationId = relation.id;
      }

      await widget.repository.createAppointment(
        nutritionistPatientId: relationId,
        scheduledAt: scheduledAt,
        durationMinutes: _durationMinutes,
        reason: _reasonController.text,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        meetingUrl: _meetingUrlController.text.isNotEmpty
            ? _meetingUrlController.text
            : 'meeting-${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Cita creada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _getServiceTypeLabel(String type) {
    switch (type) {
      case 'DIET_PLAN':
        return 'Plan de alimentación';
      case 'PERSONAL_CONSULT':
        return 'Consulta personalizada';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Cita con ${widget.nutritionist.fullName}',
          style: const TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildNutritionistInfo(),
            const SizedBox(height: 20),
            _buildDateTimeSelector(),
            const SizedBox(height: 16),
            _buildDurationSelector(),
            const SizedBox(height: 16),
            _buildServiceTypeSelector(),
            const SizedBox(height: 16),
            _buildReasonField(),
            const SizedBox(height: 16),
            _buildNotesField(),
            const SizedBox(height: 16),
            _buildMeetingUrlField(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionistInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
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
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nutritionist.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.nutritionist.specialtyLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          _buildSelectorRow(
            icon: Icons.calendar_today,
            label: 'Fecha',
            value: _formatDate(_selectedDate),
            onTap: _selectDate,
          ),
          const Divider(height: 24),
          _buildSelectorRow(
            icon: Icons.access_time,
            label: 'Hora',
            value: _formatTime(_selectedTime),
            onTap: _selectTime,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppTheme.brandGreen, size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.muted,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppTheme.muted, size: 20),
        ],
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Duración',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildDurationChip(30),
              const SizedBox(width: 8),
              _buildDurationChip(45),
              const SizedBox(width: 8),
              _buildDurationChip(60),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChip(int minutes) {
    final isSelected = _durationMinutes == minutes;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _durationMinutes = minutes),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.brandGreen : const Color(0xFFF1F4F8),
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? null
                : Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Center(
            child: Text(
              '${minutes}min',
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.ink,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Tipo de servicio',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ..._serviceTypes.map((type) {
            final isSelected = _serviceType == type;
            return GestureDetector(
              onTap: () => setState(() => _serviceType = type),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.brandGreen
                              : AppTheme.muted,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.brandGreen,
                          ),
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getServiceTypeLabel(type),
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? AppTheme.ink : AppTheme.muted,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMeetingUrlField() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'URL de reunión',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _meetingUrlController,
            decoration: InputDecoration(
              hintText: 'URL de la reunión',
              hintStyle: TextStyle(color: AppTheme.muted),
              filled: true,
              fillColor: const Color(0xFFF1F4F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Si no ingresas una URL, se generará automáticamente.',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonField() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Motivo de la cita',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _reasonController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Describe el motivo de tu cita...',
              hintStyle: TextStyle(color: AppTheme.muted),
              filled: true,
              fillColor: const Color(0xFFF1F4F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresa el motivo de la cita';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Notas adicionales',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Información adicional (opcional)...',
              hintStyle: TextStyle(color: AppTheme.muted),
              filled: true,
              fillColor: const Color(0xFFF1F4F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isSubmitting ? null : _submit,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.brandGreen,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: _isSubmitting
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Text(
          'Crear cita',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
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

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
