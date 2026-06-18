import 'package:flutter/material.dart';
import 'package:jameofit/app/theme/app_theme.dart';
import 'package:jameofit/features/iot/data/datasources/mock_iot_data_source.dart';
import 'package:jameofit/features/iot/data/repositories/iot_repository_impl.dart';
import 'package:jameofit/features/iot/presentation/controllers/iot_controller.dart';
import 'package:jameofit/features/iot/presentation/pages/iot_shell_page.dart';

class JameoFitApp extends StatefulWidget {
  const JameoFitApp({super.key});

  @override
  State<JameoFitApp> createState() => _JameoFitAppState();
}

class _JameoFitAppState extends State<JameoFitApp> {
  late final IoTController _controller;

  @override
  void initState() {
    super.initState();
    _controller = IoTController(
      repository: IoTRepositoryImpl(
        dataSource: MockIoTDataSource(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
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
      home: IoTShellPage(controller: _controller),
    );
  }
}
