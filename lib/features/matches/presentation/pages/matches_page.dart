import 'package:basic_app/app/di/injection.dart';
import 'package:basic_app/app/router/app_router.dart';
import 'package:basic_app/app/router/route_args.dart';
import 'package:basic_app/common/bloc/active_user_cubit/active_user_cubit.dart';
import 'package:basic_app/common/constants/enum/service_enum.dart';
import 'package:basic_app/core/database/app_database.dart';
import 'package:basic_app/features/matches/presentation/cubit/matches_cubit.dart';
import 'package:basic_app/features/movies/data/repository/movies_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class MatchesPage extends StatelessWidget {
  const MatchesPage({super.key});

  void _openDetail(BuildContext context, Movy movie) {
    final active = context.read<ActiveUserCubit>().state;
    if (active == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a user on the Users tab first.'),
        ),
      );
      return;
    }
    Navigator.pushNamed(
      context,
      AppRouter.movieDetail,
      arguments: MovieDetailRouteArgs(
        tmdbId: movie.tmdbId,
        userId: active,
        posterPath: movie.posterPath,
        title: movie.title,
      ),
    );
  }


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
                        'Movie Matches',
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
            child: const Text('Movie Matches'),
          );
        },
      ),
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

    return BlocProvider(
      create: (_) => sl<MatchesCubit>()..watch(),
      child: Scaffold(
        body: BlocBuilder<MatchesCubit, MatchesState>(
          builder: (context, state) {
            if (state.status == Status.loading) {
              return CustomScrollView(
                slivers: [
                  _appBar(context),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid.builder(
                      gridDelegate: _gridDelegate,
                      itemCount: 6,
                      itemBuilder: (_, __) => const _MatchCardShimmer(),
                    ),
                  ),
                ],
              );
            }

            if (state.matches.isEmpty) {
              return CustomScrollView(
                slivers: [
                  _appBar(context),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
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
                              'No matches yet',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Matches are movies that at least two different '
                              'users have saved. Save the same film as someone '
                              'else and it will show up here automatically.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return CustomScrollView(
              slivers: [
                _appBar(context),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverGrid.builder(
                    gridDelegate: _gridDelegate,
                    itemCount: state.matches.length,
                    itemBuilder: (context, index) {
                      final item = state.matches[index];
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
                        child: _MatchCard(
                          item: item,
                          onTap: () => _openDetail(context, item.movie),
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
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.item,
    required this.onTap,
  });

  final MovieWithCount item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final movie = item.movie;
    final hasPoster = movie.posterPath.startsWith('http');
    final isTopPick = item.isTopPick;
    final releaseYear = movie.releaseDate.isEmpty
        ? '-'
        : movie.releaseDate.split('-').first;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: theme.colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isTopPick
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'movie_${movie.tmdbId}',
              child: hasPoster
                  ? CachedNetworkImage(
                      imageUrl: movie.posterPath,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 300),
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
            if (isTopPick)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'Top pick',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              top: 10,
              right: 10,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: Container(
                  key: ValueKey(item.saveCount),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.heart,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.saveCount}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder<List<User>>(
                    stream: sl<MoviesRepository>()
                        .watchUsersForMovie(movie.tmdbId),
                    builder: (_, snap) {
                      final users = snap.data ?? const [];
                      final shown = users.take(5).toList();
                      if (shown.isEmpty) {
                        return const SizedBox(height: 4);
                      }
                      const double overlap = 14;
                      const double diameter = 26;
                      return SizedBox(
                        height: diameter,
                        width: diameter + (shown.length - 1) * overlap,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (var i = 0; i < shown.length; i++)
                              Positioned(
                                left: i * overlap,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: diameter / 2 - 1,
                                    backgroundImage: shown[i]
                                            .avatar
                                            .isNotEmpty
                                        ? CachedNetworkImageProvider(
                                            shown[i].avatar,
                                          )
                                        : null,
                                    child: shown[i].avatar.isEmpty
                                        ? Text(
                                            shown[i].firstName.isEmpty
                                                ? 'U'
                                                : shown[i].firstName[0],
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
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
          ],
        ),
      ),
    );
  }
}

class _MatchCardShimmer extends StatelessWidget {
  const _MatchCardShimmer();

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey.shade300;
    final highlightColor = Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(color: Colors.white),
      ),
    );
  }
}
