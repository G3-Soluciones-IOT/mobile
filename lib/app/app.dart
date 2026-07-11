import 'package:flutter/material.dart';
import 'package:jameofit/app/theme/app_theme.dart';
import 'package:jameofit/features/auth/data/auth_data_source.dart';
import 'package:jameofit/features/auth/data/profile_onboarding_data_source.dart';
import 'package:jameofit/features/auth/presentation/pages/login_page.dart';
import 'package:jameofit/features/auth/presentation/pages/profile_onboarding_page.dart';
import 'package:jameofit/features/chat/data/datasources/chat_data_source.dart';
import 'package:jameofit/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:jameofit/features/chat/data/stomp_chat_client.dart';
import 'package:jameofit/features/chat/presentation/chat_controller.dart';
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
  ChatController? _chatController;
  AuthSession? _session;
  bool _isAuthenticating = false;
  String? _authError;
  PendingOnboarding? _pendingOnboarding;
  String? _onboardingError;

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

  ChatController _createChatController(AuthSession session) {
    return ChatController(
      session: session,
      repository: ChatRepositoryImpl(
        dataSource: ChatDataSource(authToken: session.token),
      ),
      transport: StompChatClient(),
      onUnauthorized: _logout,
    );
  }

  @override
  void dispose() {
    _iotBloc?.close();
    _chatController?.close();
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
      await _handleAuthenticatedSession(session);
    } on AuthException catch (error) {
      setState(() {
        _authError = error.message;
      });
    } on ProfileOnboardingException catch (error) {
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
      await _handleAuthenticatedSession(session);
    } on AuthException catch (error) {
      setState(() {
        _authError = error.message;
      });
    } on ProfileOnboardingException catch (error) {
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

  Future<void> _handleAuthenticatedSession(AuthSession session) async {
    final onboardingDataSource = ProfileOnboardingDataSource(
      userId: session.userId,
      authToken: session.token,
    );
    final pendingOnboarding =
        await onboardingDataSource.fetchPendingOnboarding();
    _iotBloc?.close();
    _chatController?.close();

    if (pendingOnboarding != null) {
      setState(() {
        _session = session;
        _pendingOnboarding = pendingOnboarding;
        _iotBloc = null;
        _chatController = null;
        _onboardingError = null;
      });
      return;
    }

    final bloc = _createIoTBloc(session);
    final chatController = _createChatController(session);
    setState(() {
      _session = session;
      _pendingOnboarding = null;
      _iotBloc = bloc;
      _chatController = chatController;
      _onboardingError = null;
    });
  }

  Future<void> _completeOnboarding(
    ProfileOnboardingSubmission submission,
  ) async {
    final session = _session;
    if (session == null) return;

    setState(() {
      _isAuthenticating = true;
      _onboardingError = null;
    });

    try {
      final onboardingDataSource = ProfileOnboardingDataSource(
        userId: session.userId,
        authToken: session.token,
      );
      await onboardingDataSource.saveOnboarding(submission);
      _iotBloc?.close();
      _chatController?.close();
      final bloc = _createIoTBloc(session);
      final chatController = _createChatController(session);
      setState(() {
        _pendingOnboarding = null;
        _iotBloc = bloc;
        _chatController = chatController;
      });
    } on ProfileOnboardingException catch (error) {
      setState(() {
        _onboardingError = error.message;
      });
    } catch (_) {
      setState(() {
        _onboardingError = 'No se pudo guardar tu perfil en este momento.';
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
    _chatController?.close();
    setState(() {
      _iotBloc = null;
      _chatController = null;
      _session = null;
      _authError = null;
      _pendingOnboarding = null;
      _onboardingError = null;
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
      home: _session == null
          ? LoginPage(
              isLoading: _isAuthenticating,
              errorMessage: _authError,
              onSignIn: _signIn,
              onSignUp: _signUp,
            )
          : _pendingOnboarding != null
          ? ProfileOnboardingPage(
              username: _session!.username,
              pendingOnboarding: _pendingOnboarding!,
              isLoading: _isAuthenticating,
              errorMessage: _onboardingError,
              onSubmit: _completeOnboarding,
            )
          : _iotBloc != null
          ? IoTShellPage(
              bloc: _iotBloc!,
              chatController: _chatController!,
              session: _session!,
              onLogout: _logout,
            )
          : const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
    );
  }
}
