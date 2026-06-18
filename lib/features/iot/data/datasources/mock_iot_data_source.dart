import 'dart:async';

import 'package:jameofit/features/iot/domain/entities/iot_entities.dart';

class MockIoTDataSource {
  Future<IoTOverview> fetchOverview() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return const IoTOverview(
      userName: 'Carlos',
      liveModeLabel: 'EN DIRECTO',
      integrationStatus: IntegrationStatus(
        isConnected: false,
        sourceLabel: 'Mock local',
        message: 'Pendiente de conectar tracking-service',
      ),
      linkedDevices: [
        LinkedDevice(
          name: 'Bebedor Inteligente',
          type: 'Bebedor S1',
          status: 'Activo',
          lastSync: 'Conectado · Batería 82%',
          battery: 82,
          accentHex: 0xFF16B548,
        ),
        LinkedDevice(
          name: 'Balanza Inteligente',
          type: 'Scale Pro',
          status: 'Activo',
          lastSync: 'Conectado · Última sinc. hoy',
          battery: 100,
          accentHex: 0xFF1E9ADF,
        ),
      ],
      dailySummary: DailySummary(
        waterLiters: 1.4,
        weightKg: 67.2,
        hint: 'Bebe 600ml más para alcanzar tu meta diaria',
      ),
      hydration: HydrationDetail(
        consumedLiters: 1.4,
        goalLiters: 2.0,
        goalPercent: 70,
        statusLabel: 'Sincronizado',
        reminder: 'Recuerda: debes alcanzar 2.0L antes de las 10pm',
        records: [
          HydrationRecord(
            time: '08:12',
            title: 'Toma matutina',
            subtitle: 'Registrado por sensor',
            amountMl: 350,
          ),
          HydrationRecord(
            time: '12:45',
            title: 'Durante almuerzo',
            subtitle: 'Registrado por sensor',
            amountMl: 500,
          ),
          HydrationRecord(
            time: '16:30',
            title: 'Tarde',
            subtitle: 'Registrado por sensor',
            amountMl: 550,
          ),
        ],
      ),
      weight: WeightDetail(
        weightKg: 67.2,
        imc: 22.1,
        lastMeasurement: 'Última medición: hoy 07:20am',
        weekLabels: ['L', 'M', 'X', 'J', 'V', 'S', 'H'],
        weekValues: [67.8, 67.9, 68.0, 67.7, 68.1, 68.2, 67.2],
        composition: [
          BodyCompositionMetric(
            label: 'Masa muscular',
            percent: 42,
            accentHex: 0xFF16B548,
          ),
          BodyCompositionMetric(
            label: 'Masa grasa',
            percent: 22,
            accentHex: 0xFF1E9ADF,
          ),
          BodyCompositionMetric(
            label: 'Agua corporal',
            percent: 58,
            accentHex: 0xFFA02CC8,
          ),
        ],
        insight: 'Excelente: perdiste 0.3kg esta semana',
      ),
      coach: CoachConversation(
        status: 'En línea',
        messages: [
          CoachMessage(
            text: 'Hola Carlos 👋 Hoy bebiste solo 1.4L. Te recomiendo tomar 300ml ahora antes de tu cena.',
            isAssistant: true,
          ),
          CoachMessage(
            text: '¿Cuánto debo comer en la cena?',
            isAssistant: false,
          ),
          CoachMessage(
            text: 'Según tu balanza (67.2kg) y tu meta de bajar 0.5kg/semana, tu cena ideal es: 400-450kcal. Sugiero proteína + verduras.',
            isAssistant: true,
          ),
          CoachMessage(
            text: 'Sí, genera el plan',
            isAssistant: false,
          ),
          CoachMessage(
            text: 'Basado en tus datos del bebedor y balanza, te sugiero: Pollo grillado 150g + ensalada + quinoa 60g. Total: 420kcal.',
            isAssistant: true,
          ),
        ],
      ),
      alertCenter: AlertCenter(
        summary: '4 notificaciones hoy',
        notifications: [
          AlertNotification(
            title: 'Hidratación baja detectada',
            subtitle: 'Solo 900ml en 6h · Bebedor',
            timeLabel: '14:20',
            accentHex: 0xFFFFCC7A,
          ),
          AlertNotification(
            title: 'Peso sincronizado',
            subtitle: '67.2kg · Balanza · Tendencia ↓',
            timeLabel: '07:20',
            accentHex: 0xFFCFEFDB,
          ),
          AlertNotification(
            title: 'Recomendación IA generada',
            subtitle: 'Plan de cena ajustado · 420kcal',
            timeLabel: '13:00',
            accentHex: 0xFFD9EDFB,
          ),
          AlertNotification(
            title: '¡Meta semanal cumplida!',
            subtitle: 'Hidratación 7 días consecutivos',
            timeLabel: 'Ayer',
            accentHex: 0xFFE8DEF8,
          ),
        ],
        toggles: [
          SettingToggle(label: 'Alerta de hidratación baja', enabled: true),
          SettingToggle(label: 'Sincronización de peso', enabled: true),
          SettingToggle(label: 'Sugerencias IA automáticas', enabled: false),
        ],
      ),
      settings: IoTSettings(
        deviceToggles: [
          SettingToggle(label: 'Auto-registro habilitado', enabled: true),
          SettingToggle(label: 'Notificaciones de hidratación', enabled: true),
        ],
        scaleToggles: [
          SettingToggle(label: 'Sincronización automática', enabled: true),
          SettingToggle(label: 'Mostrar composición corporal', enabled: true),
        ],
        tags: {
          'Meta diaria de agua': '2.0 L',
          'Frecuencia de alerta': 'Diaria',
          'Máx. sugerencias por día': '5 mensajes',
        },
      ),
      history: HistoryFeed(
        todayLabel: 'HOY · 3 REGISTROS',
        yesterdayLabel: 'AYER · 2 REGISTROS',
        todayEntries: [
          HistoryEntry(
            time: '08:12',
            title: 'Toma automática',
            subtitle: 'Sensor de flujo · Bebedor S1',
            value: '350ml',
            accentHex: 0xFFD9EDFB,
          ),
          HistoryEntry(
            time: '12:45',
            title: 'Toma automática',
            subtitle: 'Sensor de flujo · Bebedor S1',
            value: '500ml',
            accentHex: 0xFFD9EDFB,
          ),
          HistoryEntry(
            time: '16:30',
            title: 'Toma automática',
            subtitle: 'Sensor de flujo · Bebedor S1',
            value: '550ml',
            accentHex: 0xFFD9EDFB,
          ),
        ],
        yesterdayEntries: [
          HistoryEntry(
            time: '07:20',
            title: 'Medición de peso',
            subtitle: 'Balanza Inteligente S1',
            value: '67.5kg',
            accentHex: 0xFFCFEFDB,
          ),
          HistoryEntry(
            time: '08:00',
            title: 'Toma matutina',
            subtitle: 'Sensor de flujo · Bebedor S1',
            value: '400ml',
            accentHex: 0xFFD9EDFB,
          ),
        ],
      ),
      setup: DeviceSetup(
        searchLabel: 'Buscando dispositivos cerca...',
        steps: [
          SetupStep(order: 1, title: 'Bluetooth activado en tu teléfono', isDone: true, isActive: false),
          SetupStep(order: 2, title: 'Dispositivo en modo de emparejamiento', isDone: true, isActive: false),
          SetupStep(order: 3, title: 'Selecciona tu dispositivo', isDone: false, isActive: true),
          SetupStep(order: 4, title: 'Confirmar vinculación', isDone: false, isActive: false),
        ],
        foundDevice: LinkedDevice(
          name: 'JameoFit Bottle S1',
          type: 'Bebedor inteligente',
          status: 'Encontrado',
          lastSync: 'Listo para conectar',
          battery: 100,
          accentHex: 0xFF16B548,
        ),
      ),
    );
  }
}
