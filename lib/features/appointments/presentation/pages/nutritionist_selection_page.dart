import 'package:flutter/material.dart';
import 'package:jameofit/app/theme/app_theme.dart';
import 'package:jameofit/features/appointments/domain/entities/appointment_entities.dart';
import 'package:jameofit/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:jameofit/features/appointments/presentation/pages/create_appointment_page.dart';

enum SelectionMode { request, appointment }

class NutritionistSelectionPage extends StatefulWidget {
  const NutritionistSelectionPage({
    super.key,
    required this.repository,
    required this.userId,
    this.mode = SelectionMode.request,
  });

  final AppointmentRepository repository;
  final int userId;
  final SelectionMode mode;

  @override
  State<NutritionistSelectionPage> createState() =>
      _NutritionistSelectionPageState();
}

class _NutritionistSelectionPageState
    extends State<NutritionistSelectionPage> {
  List<Nutritionist> _nutritionists = [];
  List<int> _userNutritionistIds = [];
  List<NutritionistPatient> _myRelationships = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final nutritionists = await widget.repository.getNutritionists();

      final relationships = await widget.repository
          .getNutritionistPatientsByPatient();

      final acceptedIds = relationships
          .where((r) => r.accepted)
          .map((r) => r.nutritionistId)
          .toList();

      setState(() {
        _nutritionists = nutritionists;
        _userNutritionistIds = acceptedIds;
        _myRelationships = relationships;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Nutritionist> get _filteredNutritionists {
    List<Nutritionist> list = _nutritionists;

    if (widget.mode == SelectionMode.appointment) {
      list = list.where((n) => _userNutritionistIds.contains(n.id)).toList();
    }

    if (_searchQuery.isEmpty) return list;
    return list.where((n) {
      final name = n.fullName.toLowerCase();
      final specialty = n.specialtyLabel.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || specialty.contains(query);
    }).toList();
  }

  String get _pageTitle {
    if (widget.mode == SelectionMode.appointment) {
      return 'Seleccionar Nutricionista';
    }
    return 'Buscar Nutricionista';
  }

  String get _emptyMessage {
    if (widget.mode == SelectionMode.appointment) {
      return 'No tienes nutricionistas asignados';
    }
    return 'No hay nutricionistas disponibles';
  }

  String get _emptySubMessage {
    if (widget.mode == SelectionMode.appointment) {
      return 'Primero debes solicitar un nutricionista';
    }
    return 'Intenta más tarde';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _pageTitle,
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
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.brandGreen,
              ),
            )
                : _filteredNutritionists.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredNutritionists.length,
              itemBuilder: (context, index) {
                final nutritionist = _filteredNutritionists[index];
                final isAlreadyAdded = _userNutritionistIds
                    .contains(nutritionist.id);
                return _NutritionistCard(
                  nutritionist: nutritionist,
                  isAlreadyAdded: isAlreadyAdded,
                  mode: widget.mode,
                  onTap: () {
                    if (widget.mode == SelectionMode.request) {
                      if (isAlreadyAdded) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Ya tienes este nutricionista asignado',
                            ),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      } else {
                        _showRequestDialog(context, nutritionist);
                      }
                    } else {
                      if (isAlreadyAdded) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateAppointmentPage(
                              repository: widget.repository,
                              nutritionist: nutritionist,
                              userId: widget.userId,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Primero debes solicitar a este nutricionista',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Buscar nutricionista...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.muted),
          filled: true,
          fillColor: const Color(0xFFF1F4F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppTheme.muted,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? _emptyMessage : 'No se encontraron nutricionistas',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty ? _emptySubMessage : 'Prueba con otra búsqueda',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.muted,
            ),
          ),
          if (widget.mode == SelectionMode.request && _searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
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

  void _showRequestDialog(BuildContext context, Nutritionist nutritionist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Solicitar a ${nutritionist.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Deseas enviar una solicitud a este nutricionista?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.softGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.brandGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El nutricionista debe aceptar tu solicitud para poder agendar citas.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _requestNutritionist(context, nutritionist);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.brandGreen,
            ),
            child: const Text('Solicitar'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestNutritionist(
      BuildContext context, Nutritionist nutritionist) async {
    try {
      final relation = await widget.repository.createNutritionistPatient(
        nutritionistId: nutritionist.id,
        serviceType: 'DIET_PLAN',
        startDate: DateTime.now(),
        scheduledAt: DateTime.now().add(const Duration(days: 7)),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Solicitud enviada a ${nutritionist.fullName}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al enviar solicitud: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _NutritionistCard extends StatelessWidget {
  const _NutritionistCard({
    required this.nutritionist,
    required this.isAlreadyAdded,
    required this.mode,
    required this.onTap,
  });

  final Nutritionist nutritionist;
  final bool isAlreadyAdded;
  final SelectionMode mode;
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
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nutritionist.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nutritionist.specialtyLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: AppTheme.brandGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${nutritionist.yearsExperience} años de experiencia',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isAlreadyAdded)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.softGreen,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    mode == SelectionMode.appointment ? 'Disponible' : 'Asignado',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.brandGreen,
                    ),
                  ),
                )
              else if (nutritionist.acceptingNewPatients)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.softGreen,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Disponible',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.brandGreen,
                    ),
                  ),
                ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final hasValidImage = nutritionist.profilePictureUrl != null &&
        nutritionist.profilePictureUrl!.isNotEmpty &&
        (nutritionist.profilePictureUrl!.startsWith('http') ||
            nutritionist.profilePictureUrl!.startsWith('https'));

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.softGreen,
        borderRadius: BorderRadius.circular(14),
        image: hasValidImage
            ? DecorationImage(
          image: NetworkImage(nutritionist.profilePictureUrl!),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: !hasValidImage
          ? Icon(
        Icons.person,
        color: AppTheme.brandGreen,
        size: 28,
      )
          : null,
    );
  }
}
