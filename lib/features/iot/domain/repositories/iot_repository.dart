import 'package:jameofit/features/iot/domain/entities/iot_entities.dart';

abstract class IoTRepository {
  Future<IoTOverview> getOverview();
  Future<RegisteredIoTDevice> registerDevice({
    required int userId,
    required String deviceId,
    required String deviceType,
  });
}
