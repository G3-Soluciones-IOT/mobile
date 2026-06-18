import 'package:jameofit/features/iot/data/datasources/mock_iot_data_source.dart';
import 'package:jameofit/features/iot/domain/entities/iot_entities.dart';
import 'package:jameofit/features/iot/domain/repositories/iot_repository.dart';

class IoTRepositoryImpl implements IoTRepository {
  IoTRepositoryImpl({
    required MockIoTDataSource dataSource,
  }) : _dataSource = dataSource;

  final MockIoTDataSource _dataSource;

  @override
  Future<IoTOverview> getOverview() {
    return _dataSource.fetchOverview();
  }
}
