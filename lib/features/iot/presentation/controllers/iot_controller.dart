import 'package:flutter/foundation.dart';
import 'package:jameofit/features/iot/domain/entities/iot_entities.dart';
import 'package:jameofit/features/iot/domain/repositories/iot_repository.dart';

class IoTController extends ChangeNotifier {
  IoTController({required IoTRepository repository}) : _repository = repository;

  final IoTRepository _repository;

  IoTOverview? overview;
  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      overview = await _repository.getOverview();
    } catch (_) {
      error = 'No se pudo cargar la experiencia IoT.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
