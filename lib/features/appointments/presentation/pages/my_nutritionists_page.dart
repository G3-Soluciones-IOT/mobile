import 'package:flutter/material.dart';
import 'package:jameofit/app/theme/app_theme.dart';
import 'package:jameofit/features/appointments/domain/entities/appointment_entities.dart';
import 'package:jameofit/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:jameofit/features/appointments/presentation/pages/nutritionist_selection_page.dart';

class MyNutritionistsPage extends StatefulWidget {
  const MyNutritionistsPage({
    super.key,
    required this.repository,
    required this.userId,
  });

  final AppointmentRepository repository;
  final int userId;

  @override
  State<MyNutritionistsPage> createState() => _MyNutritionistsPageState();
}

class _MyNutritionistsPageState extends State<MyNutritionistsPage> {
  List<NutritionistPatient> _relationships = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final relationships = await widget.repository
          .getNutritionistPatientsByPatient();
      setState(() {
        _relationships = relationships;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<NutritionistPatient> get _acceptedRelationships {
    return _relationships.where((r) => r.accepted).toList();
  }

  List<NutritionistPatient> get _pendingRelationships {
    return _relationships.where((r) => !r.accepted).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mis Nutricionistas',
          style: TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.brandGreen),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NutritionistSelectionPage(
                    repository: widget.repository,
                    userId: widget.userId,
                    mode: SelectionMode.request,
                  ),
                ),
              ).then((_) => _loadData());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppTheme.brandGreen),
      )
          : _relationships.isEmpty
          ? _buildEmptyState()
          : _buildRelationshipList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppTheme.muted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aún no tienes nutricionistas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Busca y solicita la atención de un nutricionista',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NutritionistSelectionPage(
                    repository: widget.repository,
                    userId: widget.userId,
                    mode: SelectionMode.request,
                  ),
                ),
              ).then((_) => _loadData());
            },
            icon: const Icon(Icons.search),
            label: const Text('Buscar nutricionistas'),
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

  Widget _buildRelationshipList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_acceptedRelationships.isNotEmpty) ...[
          _buildSectionHeader('Aceptados', _acceptedRelationships.length),
          ..._acceptedRelationships.map((r) => _buildRelationshipCard(r)),
          const SizedBox(height: 16),
        ],

        if (_pendingRelationships.isNotEmpty) ...[
          _buildSectionHeader('Pendientes', _pendingRelationships.length),
          ..._pendingRelationships.map((r) => _buildRelationshipCard(r)),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: title == 'Aceptados'
                  ? AppTheme.brandGreen.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: title == 'Aceptados'
                    ? AppTheme.brandGreen
                    : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipCard(NutritionistPatient relationship) {
    final isAccepted = relationship.accepted;
    final name = relationship.nutritionistName ??
        'Nutricionista #${relationship.nutritionistId}';
    final specialty = relationship.nutritionistSpecialty ?? 'Especialidad no especificada';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isAccepted ? AppTheme.softGreen : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isAccepted ? Icons.check_circle : Icons.pending,
                color: isAccepted ? AppTheme.brandGreen : Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    specialty,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isAccepted
                    ? AppTheme.brandGreen.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isAccepted ? 'Aceptado' : 'Pendiente',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isAccepted ? AppTheme.brandGreen : Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
