import 'dart:ui';

class Nutritionist {
  const Nutritionist({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.licenseNumber,
    required this.specialty,
    required this.yearsExperience,
    required this.acceptingNewPatients,
    required this.bio,
    required this.profilePictureUrl,
  });

  final int id;
  final int userId;
  final String fullName;
  final String licenseNumber;
  final String specialty;
  final int yearsExperience;
  final bool acceptingNewPatients;
  final String bio;
  final String? profilePictureUrl;

  factory Nutritionist.fromJson(Map<String, dynamic> json) {
    return Nutritionist(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      fullName: json['fullName'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      specialty: json['specialty'] ?? 'CLINICAL',
      yearsExperience: json['yearsExperience'] ?? 0,
      acceptingNewPatients: json['acceptingNewPatients'] ?? false,
      bio: json['bio'] ?? '',
      profilePictureUrl: json['profilePictureUrl'],
    );
  }

  String get specialtyLabel {
    switch (specialty) {
      case 'CLINICAL':
        return 'Clínico';
      case 'SPORTS':
        return 'Deportivo';
      case 'PEDIATRIC':
        return 'Pediátrico';
      case 'RENAL':
        return 'Renal';
      case 'OBESITY':
        return 'Obesidad';
      case 'PUBLIC_HEALTH':
        return 'Salud Pública';
      default:
        return specialty;
    }
  }
}

class NutritionistPatient {
  const NutritionistPatient({
    required this.id,
    required this.nutritionistId,
    required this.patientUserId,
    required this.serviceType,
    required this.startDate,
    required this.scheduledAt,
    required this.accepted,
    this.nutritionistName,
    this.nutritionistSpecialty,
  });

  final int id;
  final int nutritionistId;
  final int patientUserId;
  final String serviceType;
  final DateTime startDate;
  final DateTime scheduledAt;
  final bool accepted;
  final String? nutritionistName;
  final String? nutritionistSpecialty;

  factory NutritionistPatient.fromJson(Map<String, dynamic> json) {
    return NutritionistPatient(
      id: json['id'] ?? 0,
      nutritionistId: json['nutritionistId'] ?? 0,
      patientUserId: json['patientUserId'] ?? 0,
      serviceType: json['serviceType'] ?? 'DIET_PLAN',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'])
          : DateTime.now(),
      accepted: json['accepted'] ?? false,
      nutritionistName: json['nutritionistName'],
      nutritionistSpecialty: json['nutritionistSpecialty'],
    );
  }

  String get statusLabel {
    if (accepted) return 'Aceptado';
    return 'Pendiente';
  }

  Color get statusColor {
    if (accepted) return const Color(0xFF16B548);
    return const Color(0xFFFF9900);
  }
}

class Appointment {
  const Appointment({
    required this.id,
    required this.nutritionistPatientId,
    required this.nutritionistId,
    required this.nutritionistUserId,
    required this.patientUserId,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.status,
    required this.reason,
    required this.notes,
    required this.meetingUrl,
    required this.requestedAt,
    required this.confirmedAt,
    required this.cancelledAt,
    this.nutritionistName,
  });

  final int id;
  final int nutritionistPatientId;
  final int nutritionistId;
  final int nutritionistUserId;
  final int patientUserId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String status;
  final String reason;
  final String? notes;
  final String? meetingUrl;
  final DateTime requestedAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final String? nutritionistName;

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] ?? 0,
      nutritionistPatientId: json['nutritionistPatientId'] ?? 0,
      nutritionistId: json['nutritionistId'] ?? 0,
      nutritionistUserId: json['nutritionistUserId'] ?? 0,
      patientUserId: json['patientUserId'] ?? 0,
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'])
          : DateTime.now(),
      durationMinutes: json['durationMinutes'] ?? 30,
      status: json['status'] ?? 'REQUESTED',
      reason: json['reason'] ?? '',
      notes: json['notes'],
      meetingUrl: json['meetingUrl'],
      requestedAt: json['requestedAt'] != null
          ? DateTime.parse(json['requestedAt'])
          : DateTime.now(),
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'])
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'])
          : null,
      nutritionistName: json['nutritionistName'],
    );
  }

  String get statusLabel {
    switch (status) {
      case 'REQUESTED':
        return 'Solicitada';
      case 'CONFIRMED':
        return 'Confirmada';
      case 'REJECTED':
        return 'Rechazada';
      case 'CANCELLED':
        return 'Cancelada';
      case 'COMPLETED':
        return 'Completada';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'REQUESTED':
        return const Color(0xFFFF9900);
      case 'CONFIRMED':
        return const Color(0xFF16B548);
      case 'REJECTED':
        return const Color(0xFFE46B6B);
      case 'CANCELLED':
        return const Color(0xFF74819A);
      case 'COMPLETED':
        return const Color(0xFF1E9ADF);
      default:
        return const Color(0xFF74819A);
    }
  }
}
