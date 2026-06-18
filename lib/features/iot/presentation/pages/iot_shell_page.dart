import 'package:flutter/material.dart';
import 'package:jameofit/app/theme/app_theme.dart';
import 'package:jameofit/features/iot/domain/entities/iot_entities.dart';
import 'package:jameofit/features/iot/presentation/controllers/iot_controller.dart';
import 'package:jameofit/features/iot/presentation/widgets/iot_widgets.dart';

class IoTShellPage extends StatefulWidget {
  const IoTShellPage({super.key, required this.controller});

  final IoTController controller;

  @override
  State<IoTShellPage> createState() => _IoTShellPageState();
}

class _IoTShellPageState extends State<IoTShellPage> {
  int _index = 2;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        if (widget.controller.isLoading || widget.controller.overview == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF2F3EE),
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.brandGreen),
            ),
          );
        }

        if (widget.controller.error != null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF2F3EE),
            body: Center(child: Text(widget.controller.error!)),
          );
        }

        final overview = widget.controller.overview!;
        final pages = [
          _SimpleHomePage(),
          _HistoryPage(history: overview.history),
          _DashboardPage(
            overview: overview,
            openPage: (page) {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
            },
          ),
          _CoachPage(conversation: overview.coach),
        ];

        return Scaffold(
          backgroundColor: const Color(0xFFF1F2EC),
          body: SafeArea(
            child: Center(
              child: Container(
                width: 360,
                height: 730,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: const Color(0xFFD9D9D9), width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 28,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Column(
                    children: [
                      const SizedBox(height: 14),
                      Container(
                        width: 88,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF262626),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(child: pages[_index]),
                      _BottomNav(
                        index: _index,
                        onChanged: (index) => setState(() => _index = index),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({
    required this.overview,
    required this.openPage,
  });

  final IoTOverview overview;
  final void Function(Widget page) openPage;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ScreenHeader(
          title: 'Smart Tracking',
          subtitle: 'Dispositivos vinculados',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...overview.linkedDevices.map(
                (device) => DeviceCard(
                  device: device,
                  onTap: () {
                    if (device.name.contains('Bebedor')) {
                      openPage(_HydrationPage(hydration: overview.hydration));
                    } else {
                      openPage(_ScalePage(weight: overview.weight));
                    }
                  },
                ),
              ),
              const SectionTitle('RESUMEN DEL DÍA'),
              Row(
                children: [
                  SummaryCard(
                    value: '${overview.dailySummary.waterLiters.toStringAsFixed(1)}L',
                    label: 'Agua',
                    accent: AppTheme.skyBlue,
                  ),
                  const SizedBox(width: 10),
                  SummaryCard(
                    value: overview.dailySummary.weightKg.toStringAsFixed(1),
                    label: 'Peso kg',
                    accent: AppTheme.brandGreen,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.softOrange,
                  borderRadius: BorderRadius.circular(14),
                  border: const Border(
                    left: BorderSide(color: Color(0xFFFF9900), width: 4),
                  ),
                ),
                child: Text(
                  overview.dailySummary.hint,
                  style: const TextStyle(
                    color: Color(0xFFE66300),
                    fontSize: 15,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              PrimaryAction(
                label: '+ Agregar dispositivo',
                onPressed: () => openPage(_LinkDevicePage(setup: overview.setup)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HydrationPage extends StatelessWidget {
  const _HydrationPage({required this.hydration});

  final HydrationDetail hydration;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ScreenHeader(
            title: 'Hidratación',
            subtitle: 'Bebedor Inteligente · Hoy',
            tag: hydration.statusLabel,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ProgressRing(
                    progress: hydration.goalPercent / 100,
                    center: '${hydration.consumedLiters.toStringAsFixed(1)}L',
                    bottom: 'de ${hydration.goalLiters.toStringAsFixed(1)}L',
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Text('Meta diaria'),
                    const Spacer(),
                    Text(
                      '${hydration.goalPercent}%',
                      style: const TextStyle(color: AppTheme.skyBlue),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: hydration.goalPercent / 100,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFEAEAEA),
                    color: AppTheme.skyBlue,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.softOrange,
                    borderRadius: BorderRadius.circular(14),
                    border: const Border(
                      left: BorderSide(color: Color(0xFFFF9900), width: 4),
                    ),
                  ),
                  child: Text(
                    hydration.reminder,
                    style: const TextStyle(
                      color: Color(0xFFE66300),
                      fontSize: 15,
                      height: 1.25,
                    ),
                  ),
                ),
                const SectionTitle('REGISTROS AUTOMÁTICOS DE HOY'),
                ...hydration.records.map(
                  (record) => TimelineEntryTile(
                    time: record.time,
                    title: record.title,
                    subtitle: record.subtitle,
                    value: '${record.amountMl}ml',
                    accent: AppTheme.skyBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScalePage extends StatelessWidget {
  const _ScalePage({required this.weight});

  final WeightDetail weight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ScreenHeader(
            title: 'Balanza Inteligente',
            subtitle: weight.lastMeasurement,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SummaryCard(
                      value: weight.weightKg.toStringAsFixed(1),
                      label: 'Peso kg',
                      accent: AppTheme.brandGreen,
                    ),
                    const SizedBox(width: 10),
                    SummaryCard(
                      value: weight.imc.toStringAsFixed(1),
                      label: 'IMC',
                      accent: const Color(0xFFA22BC6),
                    ),
                  ],
                ),
                const SectionTitle('EVOLUCIÓN SEMANAL'),
                LineChartCard(labels: weight.weekLabels, values: weight.weekValues),
                const SectionTitle('COMPOSICIÓN CORPORAL'),
                ...weight.composition.map((item) {
                  final color = Color(item.accentHex);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(item.label),
                            const Spacer(),
                            Text('${item.percent}%'),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: item.percent / 100,
                            minHeight: 8,
                            color: color,
                            backgroundColor: const Color(0xFFEAEAEA),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.softGreen,
                    borderRadius: BorderRadius.circular(14),
                    border: const Border(
                      left: BorderSide(color: AppTheme.brandGreen, width: 4),
                    ),
                  ),
                  child: Text(
                    '${weight.insight} 🎉',
                    style: const TextStyle(
                      color: Color(0xFF1E6B33),
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachPage extends StatelessWidget {
  const _CoachPage({required this.conversation});

  final CoachConversation conversation;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ScreenHeader(
          title: 'Coach Nutricional IA',
          subtitle: 'Basado en tus datos IoT',
          tag: conversation.status,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            children: [
              ...conversation.messages.map((message) => MessageBubble(message: message)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFEBEBEB)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const CircleAvatar(
                    radius: 17,
                    backgroundColor: AppTheme.brandGreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AlertsPage extends StatelessWidget {
  const _AlertsPage({required this.alertCenter});

  final AlertCenter alertCenter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ScreenHeader(
            title: 'Alertas IoT',
            subtitle: alertCenter.summary,
            tag: 'US-11 · US-16',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...alertCenter.notifications.map((notification) {
                  final accent = Color(notification.accentHex);
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFEDEDED))),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
                              ),
                              Text(
                                notification.subtitle,
                                style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          notification.timeLabel,
                          style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                const SectionTitle('CONFIGURAR ALERTAS IOT'),
                ...alertCenter.toggles.map(
                  (toggle) => ToggleRow(label: toggle.label, value: toggle.enabled),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.settings});

  final IoTSettings settings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const ScreenHeader(
            title: 'Configuración IoT',
            subtitle: '',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('BEBEDOR INTELIGENTE'),
                ...settings.deviceToggles.map(
                  (toggle) => ToggleRow(label: toggle.label, value: toggle.enabled),
                ),
                SettingTagRow(
                  label: 'Meta diaria de agua',
                  value: settings.tags['Meta diaria de agua']!,
                ),
                const SectionTitle('BALANZA INTELIGENTE'),
                ...settings.scaleToggles.map(
                  (toggle) => ToggleRow(label: toggle.label, value: toggle.enabled),
                ),
                SettingTagRow(
                  label: 'Frecuencia de alerta',
                  value: settings.tags['Frecuencia de alerta']!,
                ),
                const SectionTitle('LÍMITE DE INTERACCIÓN IA'),
                SettingTagRow(
                  label: 'Máx. sugerencias por día',
                  value: settings.tags['Máx. sugerencias por día']!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryPage extends StatelessWidget {
  const _HistoryPage({required this.history});

  final HistoryFeed history;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const ScreenHeader(
          title: 'Historial IoT',
          subtitle: 'Registros automáticos de dispositivos',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFDADADA)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_drink_outlined, color: AppTheme.brandGreen, size: 17),
                    SizedBox(width: 8),
                    Text('Filtrado: IoT'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SectionTitle(history.todayLabel),
              ...history.todayEntries.map(
                (entry) => TimelineEntryTile(
                  time: entry.time,
                  title: entry.title,
                  subtitle: entry.subtitle,
                  value: entry.value,
                  accent: Color(entry.accentHex),
                ),
              ),
              const SizedBox(height: 6),
              SectionTitle(history.yesterdayLabel),
              ...history.yesterdayEntries.map(
                (entry) => TimelineEntryTile(
                  time: entry.time,
                  title: entry.title,
                  subtitle: entry.subtitle,
                  value: entry.value,
                  accent: Color(entry.accentHex),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LinkDevicePage extends StatelessWidget {
  const _LinkDevicePage({required this.setup});

  final DeviceSetup setup;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const ScreenHeader(
            title: 'Vincular dispositivo',
            subtitle: '',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFFC8C8C8),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      setup.searchLabel,
                      style: const TextStyle(color: AppTheme.muted),
                    ),
                  ),
                ),
                const SectionTitle('PASOS DE CONFIGURACIÓN'),
                ...setup.steps.map((step) => SetupStepTile(step: step)),
                DeviceCard(device: setup.foundDevice, onTap: () {}),
                PrimaryAction(
                  label: 'Conectar dispositivo',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Inicio',
        style: TextStyle(fontSize: 18, color: AppTheme.muted),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <String>['Inicio', 'Historial', 'IoT', 'Coach IA'];
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE7E7E7))),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (itemIndex) {
          final selected = itemIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(itemIndex),
              child: Center(
                child: Text(
                  items[itemIndex],
                  style: TextStyle(
                    color: selected ? AppTheme.brandGreen : const Color(0xFFC8C1BB),
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
