import 'package:jameofit/features/iot/data/datasources/remote_iot_data_source.dart';
import 'package:jameofit/features/iot/domain/entities/iot_entities.dart';
import 'package:jameofit/features/iot/domain/repositories/iot_repository.dart';

class IoTRepositoryImpl implements IoTRepository {
  IoTRepositoryImpl({
    required RemoteIoTDataSource dataSource,
  }) : _dataSource = dataSource;

  final RemoteIoTDataSource _dataSource;

  @override
  Future<IoTOverview> getOverview() {
    return _dataSource.fetchOverview();
  }
}
