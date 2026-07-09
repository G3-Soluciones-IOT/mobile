import 'dart:async';

import 'package:jameofit/features/iot/domain/repositories/iot_repository.dart';
import 'package:jameofit/features/iot/presentation/bloc/iot_event.dart';
import 'package:jameofit/features/iot/presentation/bloc/iot_state.dart';

class IoTBloc {
  IoTBloc({required IoTRepository repository}) : _repository = repository {
    _eventSubscription = _eventController.stream.listen(_handleEvent);
  }

  final IoTRepository _repository;
  final _eventController = StreamController<IoTEvent>();
  final _stateController = StreamController<IoTState>.broadcast();

  late final StreamSubscription<IoTEvent> _eventSubscription;

  IoTState _state = const IoTInitial();

  IoTState get state => _state;

  Stream<IoTState> get stream => _stateController.stream;

  void add(IoTEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  Future<void> _handleEvent(IoTEvent event) async {
    if (event is IoTOverviewRequested) {
      await _loadOverview();
    }
  }

  Future<void> _loadOverview() async {
    _emit(const IoTLoading());

    try {
      final overview = await _repository.getOverview();
      _emit(IoTLoaded(overview: overview));
    } catch (_) {
      _emit(
        const IoTFailure(
          message: 'No se pudo cargar la experiencia IoT.',
        ),
      );
    }
  }

  void _emit(IoTState state) {
    _state = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  void close() {
    _eventSubscription.cancel();
    _eventController.close();
    _stateController.close();
  }
}
