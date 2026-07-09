import 'package:jameofit/features/iot/domain/entities/iot_entities.dart';

abstract class IoTState {
  const IoTState();
}

class IoTInitial extends IoTState {
  const IoTInitial();
}

class IoTLoading extends IoTState {
  const IoTLoading();
}

class IoTLoaded extends IoTState {
  const IoTLoaded({required this.overview});

  final IoTOverview overview;
}

class IoTFailure extends IoTState {
  const IoTFailure({required this.message});

  final String message;
}
