class IoTOverview {
  const IoTOverview({
    required this.userName,
    required this.liveModeLabel,
    required this.integrationStatus,
    required this.linkedDevices,
    required this.dailySummary,
    required this.hydration,
    required this.weight,
    required this.coach,
    required this.alertCenter,
    required this.settings,
    required this.history,
    required this.setup,
  });

  final String userName;
  final String liveModeLabel;
  final IntegrationStatus integrationStatus;
  final List<LinkedDevice> linkedDevices;
  final DailySummary dailySummary;
  final HydrationDetail hydration;
  final WeightDetail weight;
  final CoachConversation coach;
  final AlertCenter alertCenter;
  final IoTSettings settings;
  final HistoryFeed history;
  final DeviceSetup setup;
}

class IntegrationStatus {
  const IntegrationStatus({
    required this.isConnected,
    required this.sourceLabel,
    required this.message,
  });

  final bool isConnected;
  final String sourceLabel;
  final String message;
}

class LinkedDevice {
  const LinkedDevice({
    required this.name,
    required this.type,
    required this.status,
    required this.lastSync,
    required this.battery,
    required this.accentHex,
  });

  final String name;
  final String type;
  final String status;
  final String lastSync;
  final int battery;
  final int accentHex;
}

class DailySummary {
  const DailySummary({
    required this.waterLiters,
    required this.weightKg,
    required this.hint,
  });

  final double waterLiters;
  final double weightKg;
  final String hint;
}

class HydrationDetail {
  const HydrationDetail({
    required this.consumedLiters,
    required this.goalLiters,
    required this.goalPercent,
    required this.statusLabel,
    required this.reminder,
    required this.records,
  });

  final double consumedLiters;
  final double goalLiters;
  final int goalPercent;
  final String statusLabel;
  final String reminder;
  final List<HydrationRecord> records;
}

class HydrationRecord {
  const HydrationRecord({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.amountMl,
  });

  final String time;
  final String title;
  final String subtitle;
  final int amountMl;
}

class WeightDetail {
  const WeightDetail({
    required this.weightKg,
    required this.imc,
    required this.lastMeasurement,
    required this.weekLabels,
    required this.weekValues,
    required this.composition,
    required this.insight,
  });

  final double weightKg;
  final double imc;
  final String lastMeasurement;
  final List<String> weekLabels;
  final List<double> weekValues;
  final List<BodyCompositionMetric> composition;
  final String insight;
}

class BodyCompositionMetric {
  const BodyCompositionMetric({
    required this.label,
    required this.percent,
    required this.accentHex,
  });

  final String label;
  final int percent;
  final int accentHex;
}

class CoachConversation {
  const CoachConversation({
    required this.status,
    required this.messages,
  });

  final String status;
  final List<CoachMessage> messages;
}

class CoachMessage {
  const CoachMessage({
    required this.text,
    required this.isAssistant,
  });

  final String text;
  final bool isAssistant;
}

class AlertCenter {
  const AlertCenter({
    required this.summary,
    required this.notifications,
    required this.toggles,
  });

  final String summary;
  final List<AlertNotification> notifications;
  final List<SettingToggle> toggles;
}

class AlertNotification {
  const AlertNotification({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.accentHex,
  });

  final String title;
  final String subtitle;
  final String timeLabel;
  final int accentHex;
}

class SettingToggle {
  const SettingToggle({
    required this.label,
    required this.enabled,
  });

  final String label;
  final bool enabled;
}

class IoTSettings {
  const IoTSettings({
    required this.deviceToggles,
    required this.scaleToggles,
    required this.tags,
  });

  final List<SettingToggle> deviceToggles;
  final List<SettingToggle> scaleToggles;
  final Map<String, String> tags;
}

class HistoryFeed {
  const HistoryFeed({
    required this.todayLabel,
    required this.yesterdayLabel,
    required this.todayEntries,
    required this.yesterdayEntries,
  });

  final String todayLabel;
  final String yesterdayLabel;
  final List<HistoryEntry> todayEntries;
  final List<HistoryEntry> yesterdayEntries;
}

class HistoryEntry {
  const HistoryEntry({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.accentHex,
  });

  final String time;
  final String title;
  final String subtitle;
  final String value;
  final int accentHex;
}

class DeviceSetup {
  const DeviceSetup({
    required this.searchLabel,
    required this.steps,
    required this.foundDevice,
  });

  final String searchLabel;
  final List<SetupStep> steps;
  final LinkedDevice foundDevice;
}

class SetupStep {
  const SetupStep({
    required this.order,
    required this.title,
    required this.isDone,
    required this.isActive,
  });

  final int order;
  final String title;
  final bool isDone;
  final bool isActive;
}
