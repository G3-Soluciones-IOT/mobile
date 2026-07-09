import 'package:flutter/material.dart';
import 'package:jameofit/app/theme/app_theme.dart';
import 'package:jameofit/features/iot/data/datasources/remote_iot_data_source.dart';
import 'package:jameofit/features/iot/data/repositories/iot_repository_impl.dart';
import 'package:jameofit/features/iot/presentation/bloc/iot_bloc.dart';
import 'package:jameofit/features/iot/presentation/bloc/iot_event.dart';
import 'package:jameofit/features/iot/presentation/pages/iot_shell_page.dart';

class JameoFitApp extends StatefulWidget {
  const JameoFitApp({super.key});

  @override
  State<JameoFitApp> createState() => _JameoFitAppState();
}

class _JameoFitAppState extends State<JameoFitApp> {
  late final IoTBloc _iotBloc;

  @override
  void initState() {
    super.initState();
    const userId = int.fromEnvironment('JAMEOFIT_USER_ID', defaultValue: 1);
    const authToken = String.fromEnvironment('JAMEOFIT_AUTH_TOKEN');
    _iotBloc = IoTBloc(
      repository: IoTRepositoryImpl(
        dataSource: RemoteIoTDataSource(
          userId: userId,
          authToken: authToken,
        ),
      ),
    )..add(const IoTOverviewRequested());
  }

  @override
  void dispose() {
    _iotBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JameoFit IoT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.0),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: IoTShellPage(bloc: _iotBloc),
    );
  }
}
