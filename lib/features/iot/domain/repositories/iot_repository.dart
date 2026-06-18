import 'package:jameofit/features/iot/domain/entities/iot_entities.dart';

abstract class IoTRepository {
  Future<IoTOverview> getOverview();
}
