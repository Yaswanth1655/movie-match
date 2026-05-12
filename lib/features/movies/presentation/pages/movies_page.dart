import 'package:basic_app/app/di/injection.dart';
import 'package:basic_app/app/router/app_router.dart';
import 'package:basic_app/app/router/route_args.dart';
import 'package:basic_app/common/constants/enum/service_enum.dart';
import 'package:basic_app/core/database/app_database.dart';
import 'package:basic_app/features/movies/data/repository/movies_repository.dart';
import 'package:basic_app/features/movies/presentation/cubit/movies_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class MoviesPage extends StatelessWidget {
  const MoviesPage({required this.userId, super.key});
  final int userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MoviesCubit>()..init(),
      child: _MoviesPageView(userId: userId),
    );
  }
}

class _MoviesPageView extends StatelessWidget {
  const _MoviesPageView({required this.userId});
  final int userId;

  SliverAppBar _appBar(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      expandedHeight: 120,

      backgroundColor:
          theme.colorScheme.surface.withOpacity(0.9),

      surfaceTintColor: Colors.transparent,

      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),

      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final settings =
              context.dependOnInheritedWidgetOfExactType<
                  FlexibleSpaceBarSettings>();

          final currentExtent = settings?.currentExtent ?? 120;
          final minExtent = settings?.minExtent ?? kToolbarHeight;
          final maxExtent = settings?.maxExtent ?? 120;

          final progress =
              ((currentExtent - minExtent) /
                      (maxExtent - minExtent))
                  .clamp(0.0, 1.0);

          final expandedVisible = progress > 0.35;

          return Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.surface.withOpacity(0.95),
                      theme.colorScheme.surfaceVariant.withOpacity(0.75),
                    ],
                  ),
                ),
              ),

              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 72,
                    bottom: 16,
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: expandedVisible ? 1.0 : 0.0,
                    child: Transform.scale(
                      alignment: Alignment.centerLeft,
                      scale: 1.0 + (0.25 * progress),
                      child: const Text(
                        'Movies',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),

      title: LayoutBuilder(
        builder: (context, constraints) {
          final settings =
              context.dependOnInheritedWidgetOfExactType<
                  FlexibleSpaceBarSettings>();

          final currentExtent = settings?.currentExtent ?? 120;
          final minExtent = settings?.minExtent ?? kToolbarHeight;
          final maxExtent = settings?.maxExtent ?? 120;

          final progress =
              ((currentExtent - minExtent) /
                      (maxExtent - minExtent))
                  .clamp(0.0, 1.0);

          final collapsedVisible = progress <= 0.35;

          return AnimatedOpacity(
            duration: const Duration(milliseconds: 120),
            opacity: collapsedVisible ? 1.0 : 0.0,
            child: const Text('Movies'),
          );
        },
      ),

      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(
            context,
            AppRouter.userSavedMovies,
            arguments: SavedMoviesRouteArgs(userId),
          ),
          icon: const Icon(CupertinoIcons.heart_fill,color: Colors.red,),
        ),
      ],
    );
  }
    
  SliverGridDelegate get _gridDelegate =>
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocBuilder<MoviesCubit, MoviesState>(
        builder: (context, state) {
          if (state.status == Status.loading && state.movies.isEmpty) {
            return CustomScrollView(
              slivers: [
                _appBar(context),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid.builder(
                    gridDelegate: _gridDelegate,
                    itemCount: 8,
                    itemBuilder: (_, __) => const _MovieCardShimmer(),
                  ),
                ),
              ],
            );
          }

          if (state.movies.isEmpty) {
            return CustomScrollView(
              slivers: [
                _appBar(context),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.movie_filter_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No movies found',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  final cubit = context.read<MoviesCubit>();
                  final s = cubit.state;
                  if (s.loadingMore || !s.hasMore) return false;
                  if (notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 220) {
                    cubit.loadMore();
                  }
                  return false;
                },
                child: CustomScrollView(
                  slivers: [
                    _appBar(context),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      sliver: SliverGrid.builder(
                        gridDelegate: _gridDelegate,
                        itemCount: state.movies.length,
                        itemBuilder: (context, index) {
                          final movie = state.movies[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(
                              milliseconds: 200 + (index.clamp(0, 10) * 20),
                            ),
                            builder: (_, value, child) => Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            ),
                            child: _MovieCard(
                              movie: movie,
                              userId: userId,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (state.loadingMore && state.hasMore)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(minHeight: 3),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  const _MovieCard({
    required this.movie,
    required this.userId,
  });

  final Movy movie;
  final int userId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPoster = movie.posterPath.startsWith('http');
    final releaseYear = movie.releaseDate.isEmpty
        ? '-'
        : movie.releaseDate.split('-').first;

    return StreamBuilder<int>(
      stream: sl<MoviesRepository>().watchMovieSaveCount(movie.tmdbId),
      builder: (_, countSnap) {
        final count = countSnap.data ?? 0;
        return StreamBuilder<bool>(
          stream: sl<MoviesRepository>().watchIsMovieSavedForUser(
            userLocalId: userId,
            tmdbId: movie.tmdbId,
          ),
          builder: (_, savedSnap) {
            final isSaved = savedSnap.data ?? false;
            return Card(
              clipBehavior: Clip.antiAlias,
              elevation: 0,
              color: theme.colorScheme.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'movie_${movie.tmdbId}',
                      child: hasPoster
                          ? CachedNetworkImage(
                              imageUrl: movie.posterPath,
                              fit: BoxFit.cover,
                              fadeInDuration:
                                  const Duration(milliseconds: 300),
                              placeholder: (_, __) => Container(
                                color: theme.colorScheme.surfaceVariant,
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: theme.colorScheme.surfaceVariant,
                                child: Icon(
                                  Icons.movie,
                                  size: 48,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : Container(
                              color: theme.colorScheme.surfaceVariant,
                              child: Icon(
                                Icons.movie,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Color(0x66000000),
                            Color(0xCC000000),
                          ],
                          stops: [0.0, 0.55, 0.8, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Container(
                          key: ValueKey(count),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$count saved',
                            style:
                                theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 48,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            movie.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            releaseYear,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: IconButton(
                        onPressed: () => context
                            .read<MoviesCubit>()
                            .toggleSave(
                              userId: userId,
                              tmdbId: movie.tmdbId,
                            ),
                        icon: Icon(
                          isSaved
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart_fill,
                          color: isSaved ? Colors.red : Colors.white,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              Colors.black.withOpacity(0.35),
                          foregroundColor:
                              isSaved ? Colors.red : Colors.white,
                          shape: const CircleBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MovieCardShimmer extends StatelessWidget {
  const _MovieCardShimmer();

  @override
  Widget build(BuildContext context) {
    const baseColor = Colors.grey;
    final highlightColor = Colors.grey.shade300;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(color: baseColor),
      ),
    );
  }
}
