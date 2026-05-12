import 'package:basic_app/app/di/injection.dart';
import 'package:basic_app/app/router/app_router.dart';
import 'package:basic_app/app/router/route_args.dart';
import 'package:basic_app/common/constants/enum/service_enum.dart';
import 'package:basic_app/core/database/app_database.dart';
import 'package:basic_app/features/users/presentation/cubit/saved_movies_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

String _savedMoviesHeaderSubtitle(User user) {
  final parts = <String>[];
  if (user.email.isNotEmpty) parts.add(user.email);
  if (user.movieTaste.isNotEmpty) parts.add(user.movieTaste);
  return parts.isEmpty ? 'No movie taste set' : parts.join(' · ');
}

class UserSavedMoviesPage extends StatelessWidget {
  const UserSavedMoviesPage({required this.userId, super.key});
  final int userId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: (sl<AppDatabase>().select(sl<AppDatabase>().users)
            ..where((u) => u.localId.equals(userId)))
          .getSingleOrNull(),
      builder: (context, snap) {
        final user = snap.data;
        return BlocProvider(
          create: (_) => sl<SavedMoviesCubit>()..watchForUser(userId),
          child: Scaffold(
            appBar: AppBar(title: const Text('Saved Movies'),leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),),
            body: BlocBuilder<SavedMoviesCubit, SavedMoviesState>(
              builder: (context, state) {
                if (state.status == Status.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.movies.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No saved movies yet'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRouter.movies,
                            arguments: MoviesRouteArgs(userId),
                          ),
                          child: const Text('Browse movies'),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    if (user != null)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 300),
                        builder: (_, value, child) => Opacity(opacity: value, child: child),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                user.avatar.isNotEmpty ? CachedNetworkImageProvider(user.avatar) : null,
                            child: user.avatar.isEmpty
                                ? Text(user.firstName.isEmpty ? 'U' : user.firstName[0])
                                : null,
                          ),
                          title: Text('${user.firstName} ${user.lastName}'.trim()),
                          subtitle: Text(
                            _savedMoviesHeaderSubtitle(user),
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.movies.length,
                        itemBuilder: (context, index) {
                          final movie = state.movies[index];
                          final hasPoster = movie.posterPath.startsWith('http');
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 200 + (index * 20)),
                            builder: (_, value, child) => Opacity(opacity: value, child: child),
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: ListTile(
                                leading: Hero(
                                  tag: 'movie_${movie.tmdbId}',
                                  child: hasPoster
                                      ? CachedNetworkImage(
                                          imageUrl: movie.posterPath,
                                          width: 44,
                                          fadeInDuration: const Duration(milliseconds: 250),
                                          errorWidget: (_, __, ___) => const Icon(Icons.movie),
                                        )
                                      : const Icon(Icons.movie),
                                ),
                                title: Text(movie.title),
                                subtitle: Text(
                                  movie.releaseDate.isEmpty ? '-' : movie.releaseDate.split('-').first,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.bookmark_remove, color: Colors.red),
                                  onPressed: () => context
                                      .read<SavedMoviesCubit>()
                                      .toggleSave(userId: userId, tmdbId: movie.tmdbId),
                                ),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRouter.movieDetail,
                                  arguments: MovieDetailRouteArgs(
                                    tmdbId: movie.tmdbId,
                                    userId: userId,
                                    posterPath: movie.posterPath,
                                    title: movie.title,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
