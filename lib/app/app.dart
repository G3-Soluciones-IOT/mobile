import 'package:flutter/material.dart';
import 'package:jameofit/app/theme/app_theme.dart';
import 'package:jameofit/features/auth/data/auth_data_source.dart';
import 'package:jameofit/features/auth/presentation/pages/login_page.dart';
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
  final _authDataSource = const AuthDataSource();
  IoTBloc? _iotBloc;
  AuthSession? _session;
  bool _isAuthenticating = false;
  String? _authError;

  IoTBloc _createIoTBloc(AuthSession session) {
    return IoTBloc(
      repository: IoTRepositoryImpl(
        dataSource: RemoteIoTDataSource(
          userId: session.userId,
          username: session.username,
          authToken: session.token,
        ),
      ),
    )..add(const IoTOverviewRequested());
  }

  @override
  void dispose() {
    _iotBloc?.close();
    super.dispose();
  }

  Future<void> _signIn({
    required String username,
    required String password,
  }) async {
    setState(() {
      _isAuthenticating = true;
      _authError = null;
    });

    try {
      final session = await _authDataSource.signIn(
        username: username,
        password: password,
      );
      _iotBloc?.close();
      final bloc = _createIoTBloc(session);
      setState(() {
        _session = session;
        _iotBloc = bloc;
      });
    } on AuthException catch (error) {
      setState(() {
        _authError = error.message;
      });
    } catch (_) {
      setState(() {
        _authError = 'No se pudo iniciar sesion en este momento.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  Future<void> _signUp({
    required String username,
    required String password,
  }) async {
    setState(() {
      _isAuthenticating = true;
      _authError = null;
    });

    try {
      final session = await _authDataSource.signUp(
        username: username,
        password: password,
      );
      _iotBloc?.close();
      final bloc = _createIoTBloc(session);
      setState(() {
        _session = session;
        _iotBloc = bloc;
      });
    } on AuthException catch (error) {
      setState(() {
        _authError = error.message;
      });
    } catch (_) {
      setState(() {
        _authError = 'No se pudo crear la cuenta en este momento.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  void _logout() {
    _iotBloc?.close();
    setState(() {
      _iotBloc = null;
      _session = null;
      _authError = null;
    });
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
      home: _session == null || _iotBloc == null
          ? LoginPage(
              isLoading: _isAuthenticating,
              errorMessage: _authError,
              onSignIn: _signIn,
              onSignUp: _signUp,
            )
          : IoTShellPage(
              bloc: _iotBloc!,
              session: _session!,
              onLogout: _logout,
            ),
    );
  }
}
