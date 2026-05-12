import 'package:basic_app/common/bloc/active_user_cubit/active_user_cubit.dart';
import 'package:basic_app/common/bloc/connectivity_cubit/connectivity_cubit.dart';
import 'package:basic_app/common/bloc/sync_cubit/sync_cubit.dart';
import 'package:basic_app/core/database/app_database.dart';
import 'package:basic_app/core/internet_connectivity/connectivity_service.dart';
import 'package:basic_app/data/source/network/network_api_service.dart';
import 'package:basic_app/data/source/network/retry_dio_factory.dart';
import 'package:basic_app/features/matches/presentation/cubit/matches_cubit.dart';
import 'package:basic_app/features/movies/data/repository/movie_remote_source.dart';
import 'package:basic_app/features/movies/data/repository/movies_repository.dart';
import 'package:basic_app/features/saved_movies/data/repository/saved_movies_repository.dart';
import 'package:basic_app/features/movies/presentation/cubit/movie_detail_cubit.dart';
import 'package:basic_app/features/movies/presentation/cubit/movies_cubit.dart';
import 'package:basic_app/features/users/data/repository/reqres_user_remote_source.dart';
import 'package:basic_app/features/users/data/repository/users_repository.dart';
import 'package:basic_app/features/users/presentation/cubit/add_user_cubit.dart';
import 'package:basic_app/features/users/presentation/cubit/saved_movies_cubit.dart';
import 'package:basic_app/features/users/presentation/cubit/users_cubit.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  if (sl.isRegistered<AppDatabase>()) return;

  sl.registerLazySingleton<Dio>(RetryDioFactory.create);
  sl.registerLazySingleton<AppDatabase>(AppDatabase.new);
  sl.registerLazySingleton<Network>(() => Network(dio: sl<Dio>()));
  // Registered eagerly so the very first repository call has a primed
  // connectivity snapshot (vs. lazy + a flash of "online" on cold-start).
  sl.registerSingleton<ConnectivityService>(ConnectivityService());

  sl.registerLazySingleton<ReqresUserRemoteSource>(
    () => ReqresUserRemoteSource(sl()),
  );
  sl.registerLazySingleton<MovieRemoteSource>(
    () => MovieRemoteSource(sl()),
  );
  sl.registerLazySingleton<SavedMoviesRepository>(
    () => SavedMoviesRepository(sl()),
  );

  sl.registerLazySingleton<UsersRepository>(
    () => UsersRepository(sl(), sl(), sl()),
  );
  sl.registerLazySingleton<MoviesRepository>(
    () => MoviesRepository(
      sl.get<AppDatabase>(),
      sl.get<MovieRemoteSource>(),
      sl.get<SavedMoviesRepository>(),
      sl.get<ConnectivityService>(),
    ),
  );

  sl.registerLazySingleton<ActiveUserCubit>(ActiveUserCubit.new);
  sl.registerLazySingleton<ConnectivityCubit>(() => ConnectivityCubit(sl()));
  sl.registerLazySingleton<SyncCubit>(() => SyncCubit(sl(), sl()));

  sl.registerFactory<UsersCubit>(() => UsersCubit(sl()));
  sl.registerFactory<AddUserCubit>(() => AddUserCubit(sl()));
  sl.registerFactory<MoviesCubit>(() => MoviesCubit(sl()));
  sl.registerFactory<MovieDetailCubit>(() => MovieDetailCubit(sl()));
  sl.registerFactory<SavedMoviesCubit>(
    () => SavedMoviesCubit(sl.get<SavedMoviesRepository>()),
  );
  sl.registerFactory<MatchesCubit>(() => MatchesCubit(sl()));
}
