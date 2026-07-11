import 'package:flutter/material.dart';
import 'package:jameofit/app/theme/app_theme.dart';
import 'package:jameofit/features/auth/data/profile_onboarding_data_source.dart';

class ProfileOnboardingPage extends StatefulWidget {
  const ProfileOnboardingPage({
    super.key,
    required this.username,
    required this.pendingOnboarding,
    required this.isLoading,
    required this.onSubmit,
    this.errorMessage,
  });

  final String username;
  final PendingOnboarding pendingOnboarding;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function(ProfileOnboardingSubmission submission) onSubmit;

  @override
  State<ProfileOnboardingPage> createState() => _ProfileOnboardingPageState();
}

class _ProfileOnboardingPageState extends State<ProfileOnboardingPage> {
  static const _goalOptions = [
    _GoalOption(
      goalObjective: 'LOSE_WEIGHT',
      label: 'Bajar de peso',
      helper: 'Reducir grasa corporal de forma progresiva.',
    ),
    _GoalOption(
      goalObjective: 'MAINTAIN_WEIGHT',
      label: 'Mantener mi peso',
      helper: 'Sostener tu peso con buenos hábitos diarios.',
    ),
    _GoalOption(
      goalObjective: 'GAIN_MUSCLE',
      label: 'Ganar masa muscular',
      helper: 'Aumentar masa magra con nutrición y entrenamiento.',
    ),
  ];

  final _formKey = GlobalKey<FormState>();
  final _birthDateController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  late String _gender;
  late int? _activityLevelId;
  late String _goalObjective;
  late String _goalPace;
  late String _dietPreset;
  late Set<int> _selectedAllergyIds;
  DateTime? _birthDate;

  List<CatalogOption> get _activityLevels =>
      widget.pendingOnboarding.activityLevels;
  List<CatalogOption> get _backendObjectives =>
      widget.pendingOnboarding.objectives;
  List<CatalogOption> get _allergies => widget.pendingOnboarding.allergies;

  _GoalOption get _selectedGoalOption {
    for (final option in _goalOptions) {
      if (option.goalObjective == _goalObjective) return option;
    }
    return _goalOptions.last;
  }

  CatalogOption? get _selectedActivityLevel {
    final activityLevelId = _activityLevelId;
    if (activityLevelId == null) return null;
    for (final option in _activityLevels) {
      if (option.id == activityLevelId) return option;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final profile = widget.pendingOnboarding.existingProfile;
    final goal = widget.pendingOnboarding.existingGoal;

    _gender = _normalizeGender(profile?.gender);
    _birthDate = profile?.birthDate;
    _birthDateController.text = _birthDate == null ? '' : _formatDate(_birthDate!);
    _heightController.text = profile != null && profile.heightCm > 0
        ? _formatDouble(profile.heightCm)
        : '';
    _weightController.text = profile != null && profile.weightKg > 0
        ? _formatDouble(profile.weightKg)
        : '';
    _targetWeightController.text = goal != null && goal.targetWeightKg > 0
        ? _formatDouble(goal.targetWeightKg)
        : '';
    _activityLevelId = _resolveActivityLevelId(profile?.activityLevelId);
    _goalObjective = _resolveGoalObjective(profile?.objectiveId, goal?.objective);
    _goalPace = _resolvePace(goal?.pace);
    _dietPreset = _resolveDiet(goal?.dietPreset);
    _selectedAllergyIds = _resolveAllergyIds(profile?.allergyNames);
  }

  @override
  void dispose() {
    _birthDateController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = _birthDate ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 10, now.month, now.day),
    );
    if (picked == null) return;
    setState(() {
      _birthDate = picked;
      _birthDateController.text = _formatDate(picked);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || widget.isLoading) return;
    final birthDate = _birthDate;
    final backendObjective = _resolveBackendObjectiveForGoal(_goalObjective);
    if (birthDate == null) return;
    if (backendObjective == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se encontró un objetivo compatible en el backend. Revisa la configuración del catálogo de objetivos.',
          ),
        ),
      );
      return;
    }

    await widget.onSubmit(
      ProfileOnboardingSubmission(
        profileId: widget.pendingOnboarding.existingProfile?.id,
        gender: _gender,
        birthDate: birthDate,
        heightCm: double.parse(_heightController.text.replaceAll(',', '.')),
        weightKg: double.parse(_weightController.text.replaceAll(',', '.')),
        activityLevelId: _activityLevelId!,
        objectiveId: backendObjective.id,
        userScore: backendObjective.score ?? 0,
        allergyIds: _selectedAllergyIds.toList()..sort(),
        goalObjective: _goalObjective,
        targetWeightKg: double.parse(
          _targetWeightController.text.replaceAll(',', '.'),
        ),
        goalPace: _goalPace,
        dietPreset: _dietPreset,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OnboardingHero(username: widget.username),
              Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 34,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Completa tu perfil',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A2238),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Cuéntanos lo esencial para personalizar tus metas, macros y seguimiento diario.',
                          style: TextStyle(
                            color: Color(0xFF6E7A96),
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                        if (widget.errorMessage != null) ...[
                          const SizedBox(height: 18),
                          _ErrorBanner(message: widget.errorMessage!),
                        ],
                        const SizedBox(height: 24),
                        const _SectionTitle(
                          title: 'Datos personales',
                          subtitle:
                              'Estos datos ayudan a mostrar tu resumen correctamente.',
                        ),
                        const SizedBox(height: 16),
                        const _InputLabel(label: 'Sexo'),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'MALE',
                              label: Text('Masculino'),
                            ),
                            ButtonSegment(
                              value: 'FEMALE',
                              label: Text('Femenino'),
                            ),
                            ButtonSegment(
                              value: 'OTHER',
                              label: Text('Otro'),
                            ),
                          ],
                          selected: {_gender},
                          onSelectionChanged: widget.isLoading
                              ? null
                              : (selection) {
                                  setState(() {
                                    _gender = selection.first;
                                  });
                                },
                        ),
                        const SizedBox(height: 16),
                        const _InputLabel(label: 'Fecha de nacimiento'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _birthDateController,
                          readOnly: true,
                          onTap: widget.isLoading ? null : _pickBirthDate,
                          decoration: _inputDecoration(
                            'Selecciona tu fecha',
                            suffixIcon: const Icon(Icons.calendar_today_outlined),
                          ),
                          validator: (_) {
                            if (_birthDate == null) {
                              return 'Selecciona tu fecha de nacimiento.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricField(
                                controller: _heightController,
                                label: 'Altura',
                                hint: 'Ej. 172',
                                suffix: 'cm',
                                enabled: !widget.isLoading,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricField(
                                controller: _weightController,
                                label: 'Peso actual',
                                hint: 'Ej. 68.5',
                                suffix: 'kg',
                                enabled: !widget.isLoading,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const _InputLabel(label: 'Nivel de actividad'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          initialValue: _activityLevelId,
                          decoration: _inputDecoration('Selecciona tu actividad'),
                          items: _activityLevels
                              .map(
                                (option) => DropdownMenuItem<int>(
                                  value: option.id,
                                  child: Text(option.label),
                                ),
                              )
                              .toList(),
                          onChanged: widget.isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _activityLevelId = value;
                                  });
                                },
                          validator: (value) {
                            if (value == null) {
                              return 'Selecciona tu nivel de actividad.';
                            }
                            return null;
                          },
                        ),
                        if ((_selectedActivityLevel?.description ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _selectedActivityLevel!.description!,
                            style: const TextStyle(
                              color: Color(0xFF6E7A96),
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        const _SectionTitle(
                          title: 'Meta nutricional',
                          subtitle:
                              'La app usará estos datos para personalizar tu plan diario.',
                        ),
                        const SizedBox(height: 16),
                        const _InputLabel(label: 'Objetivo principal'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _goalObjective,
                          decoration: _inputDecoration('Selecciona tu objetivo'),
                          items: _goalOptions
                              .map(
                                (option) => DropdownMenuItem<String>(
                                  value: option.goalObjective,
                                  child: Text(option.label),
                                ),
                              )
                              .toList(),
                          onChanged: widget.isLoading
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _goalObjective = value;
                                  });
                                },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Selecciona tu objetivo.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedGoalOption.helper,
                          style: const TextStyle(
                            color: Color(0xFF6E7A96),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricField(
                                controller: _targetWeightController,
                                label: 'Peso meta',
                                hint: 'Ej. 64',
                                suffix: 'kg',
                                enabled: !widget.isLoading,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _goalPace,
                                decoration: _inputDecoration('Ritmo'),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'SLOW',
                                    child: Text('Suave'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'MODERATE',
                                    child: Text('Moderado'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'FAST',
                                    child: Text('Intenso'),
                                  ),
                                ],
                                onChanged: widget.isLoading
                                    ? null
                                    : (value) {
                                        if (value == null) return;
                                        setState(() {
                                          _goalPace = value;
                                        });
                                      },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const _InputLabel(label: 'Tipo de alimentación'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _dietPreset,
                          decoration: _inputDecoration(
                            'Selecciona tu preferencia',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'OMNIVORE',
                              child: Text('Omnívora'),
                            ),
                            DropdownMenuItem(
                              value: 'VEGETARIAN',
                              child: Text('Vegetariana'),
                            ),
                            DropdownMenuItem(
                              value: 'VEGAN',
                              child: Text('Vegana'),
                            ),
                            DropdownMenuItem(
                              value: 'LOW_CARB',
                              child: Text('Baja en carbohidratos'),
                            ),
                            DropdownMenuItem(
                              value: 'HIGH_PROTEIN',
                              child: Text('Alta en proteína'),
                            ),
                            DropdownMenuItem(
                              value: 'MEDITERRANEAN',
                              child: Text('Mediterránea'),
                            ),
                          ],
                          onChanged: widget.isLoading
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _dietPreset = value;
                                  });
                                },
                        ),
                        const SizedBox(height: 24),
                        const _SectionTitle(
                          title: 'Alergias',
                          subtitle:
                              'Opcional. Solo marca lo que necesitemos considerar.',
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allergies.map((option) {
                            final selected =
                                _selectedAllergyIds.contains(option.id);
                            return FilterChip(
                              label: Text(option.label),
                              selected: selected,
                              onSelected: widget.isLoading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        if (value) {
                                          _selectedAllergyIds.add(option.id);
                                        } else {
                                          _selectedAllergyIds.remove(option.id);
                                        }
                                      });
                                    },
                              selectedColor: AppTheme.softGreen,
                              checkmarkColor: AppTheme.brandGreen,
                              side: BorderSide(
                                color: selected
                                    ? AppTheme.brandGreen
                                    : const Color(0xFFD7DEE8),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F7FB),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Después podrás ajustar tu perfil, metas y preferencias desde la app cuando agreguemos esa sección.',
                            style: TextStyle(
                              color: Color(0xFF6A7690),
                              fontSize: 12.5,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: widget.isLoading ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.brandGreen,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFCAD0D8),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: widget.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Guardar y continuar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF9AA5B5)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF1F4F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.brandGreen, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE46B6B)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE46B6B), width: 1.2),
      ),
    );
  }

  int? _resolveActivityLevelId(int? rawId) {
    if (rawId != null && _activityLevels.any((item) => item.id == rawId)) {
      return rawId;
    }
    return _activityLevels.isNotEmpty ? _activityLevels.first.id : null;
  }

  String _resolveGoalObjective(int? rawProfileId, String? rawGoalObjective) {
    const allowed = {'LOSE_WEIGHT', 'MAINTAIN_WEIGHT', 'GAIN_MUSCLE'};
    if (rawGoalObjective != null && allowed.contains(rawGoalObjective)) {
      return rawGoalObjective;
    }
    if (rawProfileId != null) {
      for (final option in _backendObjectives) {
        if (option.id == rawProfileId && option.goalObjective != null) {
          return option.goalObjective!;
        }
      }
    }
    return 'GAIN_MUSCLE';
  }

  CatalogOption? _resolveBackendObjectiveForGoal(String goalObjective) {
    for (final option in _backendObjectives) {
      if (option.goalObjective == goalObjective) return option;
    }
    return null;
  }

  String _resolvePace(String? raw) {
    const allowed = {'SLOW', 'MODERATE', 'FAST'};
    return allowed.contains(raw) ? raw! : 'MODERATE';
  }

  String _resolveDiet(String? raw) {
    const allowed = {
      'OMNIVORE',
      'VEGETARIAN',
      'VEGAN',
      'LOW_CARB',
      'HIGH_PROTEIN',
      'MEDITERRANEAN',
    };
    return allowed.contains(raw) ? raw! : 'OMNIVORE';
  }

  Set<int> _resolveAllergyIds(List<String>? allergyNames) {
    final names = (allergyNames ?? const <String>[])
        .map((item) => item.trim().toLowerCase())
        .toSet();
    return _allergies
        .where((option) => names.contains(option.label.trim().toLowerCase()))
        .map((option) => option.id)
        .toSet();
  }

  String _normalizeGender(String? raw) {
    const allowed = {'MALE', 'FEMALE', 'OTHER'};
    final upper = raw?.trim().toUpperCase();
    return allowed.contains(upper) ? upper! : 'MALE';
  }

  String _formatDouble(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _GoalOption {
  const _GoalOption({
    required this.goalObjective,
    required this.label,
    required this.helper,
  });

  final String goalObjective;
  final String label;
  final String helper;
}

class _OnboardingHero extends StatelessWidget {
  const _OnboardingHero({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 50),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF173F2D), Color(0xFF2E6B51), Color(0xFF456C5A)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -34,
            top: -26,
            child: Container(
              width: 158,
              height: 158,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                children: [
                  TextSpan(
                    text: 'Jameo',
                    style: TextStyle(color: Color(0xFF16B548)),
                  ),
                  TextSpan(
                    text: 'Fit',
                    style: TextStyle(color: Color(0xFF1E9ADF)),
                  ),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF16B548),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 96),
              Text(
                'Hola, $username',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Activa tu experiencia personalizada con tus datos de salud y tus metas.',
                style: TextStyle(
                  color: Color(0xFFD7E5DE),
                  fontSize: 14.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF6E7A96),
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _MetricField extends StatelessWidget {
  const _MetricField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.suffix,
    required this.enabled,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String suffix;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputLabel(label: label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9AA5B5)),
            suffixText: suffix,
            filled: true,
            fillColor: const Color(0xFFF1F4F8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppTheme.brandGreen,
                width: 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE46B6B)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE46B6B),
                width: 1.2,
              ),
            ),
          ),
          validator: (value) {
            final raw = value?.trim() ?? '';
            if (raw.isEmpty) {
              return 'Completa este campo.';
            }
            final parsed = double.tryParse(raw.replaceAll(',', '.'));
            if (parsed == null || parsed <= 0) {
              return 'Ingresa un valor válido.';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E5),
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: Color(0xFFFF9800), width: 4),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFD96A00),
          fontSize: 13.5,
          height: 1.35,
        ),
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.ink,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }
}
