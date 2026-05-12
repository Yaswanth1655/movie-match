import 'package:basic_app/app/router/app_router.dart';
import 'package:basic_app/common/bloc/active_user_cubit/active_user_cubit.dart';
import 'package:basic_app/common/bloc/connectivity_cubit/connectivity_cubit.dart';
import 'package:basic_app/common/bloc/sync_cubit/sync_cubit.dart';
import 'package:basic_app/common/bloc/theme_cubit/cubit/theme_cubit.dart';
import 'package:basic_app/data/source/network/retry_dio_factory.dart';
import 'package:basic_app/app/di/injection.dart';
import 'package:basic_app/core/config/theme/theme.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlatformCommonsApp extends StatelessWidget {
  const PlatformCommonsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider.value(value: sl<ActiveUserCubit>()),
        BlocProvider.value(value: sl<ConnectivityCubit>()),
        BlocProvider.value(value: sl<SyncCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Movie Match',
            locale: DevicePreview.locale(context),
            builder: (context, child) {
              final app = DevicePreview.appBuilder(context, child);
              return SafeArea(
                  child: Stack(
                children: [
                  app,
                  const _ReconnectingBanner(),
                ],
              ));
            },
            theme: AppTheme.lightThemeMode,
            darkTheme: AppTheme.darkThemeMode,
            themeMode: themeMode,
            initialRoute: AppRouter.splash,
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}

/// A slim, non-blocking status bar shown at the top of the screen whenever the
/// app is *transparently recovering* — either a Dio request is in its retry
/// backoff window, or [SyncCubit] is pushing pending offline writes upstream.
///
/// Deliberately not a `MaterialBanner` / dialog: per the offline-sync spec,
/// users should "barely notice anything went wrong" — no full-screen errors,
/// no modal pop-ups, no input blocking. We just expose enough signal for
/// curious users to know the app is fixing itself.
///
/// Suppressed entirely while [ConnectivityCubit] reports offline: airplane
/// mode is a deliberate user state, not a "recovering" state, so spamming
/// "Reconnecting…" there would be both wrong and annoying.
class _ReconnectingBanner extends StatelessWidget {
  const _ReconnectingBanner();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, bool>(
      builder: (context, isOnline) {
        if (!isOnline) {
          return const SizedBox.shrink();
        }
        return StreamBuilder<bool>(
          stream: RetryDioFactory.retryingStream,
          initialData: RetryDioFactory.isRetrying,
          builder: (context, retrySnap) {
            final retrying = retrySnap.data == true;
            return BlocBuilder<SyncCubit, bool>(
              builder: (context, syncing) {
                final showing = retrying || syncing;
                return IgnorePointer(
                  ignoring: true,
                  child: AnimatedSlide(
                    offset: showing ? Offset.zero : const Offset(0, -1),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: AnimatedOpacity(
                      opacity: showing ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: SafeArea(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                            child: Material(
                              elevation: 2,
                              color: Colors.black.withOpacity(0.78),
                              shape: const StadiumBorder(),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      syncing && !retrying
                                          ? 'Syncing…'
                                          : 'Reconnecting…',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
