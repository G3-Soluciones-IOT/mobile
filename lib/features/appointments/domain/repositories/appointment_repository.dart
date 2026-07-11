import 'package:jameofit/features/appointments/domain/entities/appointment_entities.dart';

abstract class AppointmentRepository {
  Future<List<Nutritionist>> getNutritionists();
  Future<List<NutritionistPatient>> getNutritionistPatientsByPatient();
  Future<NutritionistPatient> createNutritionistPatient({
    required int nutritionistId,
    required String serviceType,
    required DateTime startDate,
    required DateTime scheduledAt,
  });
  Future<List<Appointment>> getMyAppointments({
    String? status,
    DateTime? from,
    DateTime? to,
  });
  Future<Appointment> createAppointment({
    required int nutritionistPatientId,
    required DateTime scheduledAt,
    required int durationMinutes,
    required String reason,
    String? notes,
    String? meetingUrl,
  });
  Future<Appointment?> getAppointmentDetail(int appointmentId);
}
