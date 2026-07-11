import 'package:jameofit/features/appointments/data/datasources/appointment_data_source.dart';
import 'package:jameofit/features/appointments/domain/entities/appointment_entities.dart';
import 'package:jameofit/features/appointments/domain/repositories/appointment_repository.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  AppointmentRepositoryImpl({required this.dataSource});

  final AppointmentDataSource dataSource;

  @override
  Future<List<Nutritionist>> getNutritionists() {
    return dataSource.getNutritionists();
  }

  @override
  Future<List<Nutritionist>> getNutritionistsByUser() {
    return dataSource.getNutritionistsByUser();
  }

  @override
  Future<NutritionistPatient> createNutritionistPatient({
    required int nutritionistId,
    required String serviceType,
    required DateTime startDate,
    required DateTime scheduledAt,
  }) {
    return dataSource.createNutritionistPatient(
      nutritionistId: nutritionistId,
      serviceType: serviceType,
      startDate: startDate,
      scheduledAt: scheduledAt,
    );
  }

  @override
  Future<List<Appointment>> getMyAppointments({
    String? status,
    DateTime? from,
    DateTime? to,
  }) {
    return dataSource.getMyAppointments(status: status, from: from, to: to);
  }

  @override
  Future<Appointment> createAppointment({
    required int nutritionistPatientId,
    required DateTime scheduledAt,
    required int durationMinutes,
    required String reason,
    String? notes,
    String? meetingUrl,
  }) {
    return dataSource.createAppointment(
      nutritionistPatientId: nutritionistPatientId,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      reason: reason,
      notes: notes,
      meetingUrl: meetingUrl,
    );
  }

  @override
  Future<Appointment?> getAppointmentDetail(int appointmentId) {
    return dataSource.getAppointmentDetail(appointmentId);
  }

  @override
  Future<List<NutritionistPatient>> getNutritionistPatientsByPatient() {
    return dataSource.getNutritionistPatientsByPatient();
  }
}
