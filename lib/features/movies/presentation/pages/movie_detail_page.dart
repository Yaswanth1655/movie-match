import 'package:basic_app/app/di/injection.dart';
import 'package:basic_app/common/constants/enum/service_enum.dart';
import 'package:basic_app/features/movies/data/repository/movies_repository.dart';
import 'package:basic_app/features/movies/presentation/cubit/movie_detail_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class MovieDetailPage extends StatelessWidget {
  const MovieDetailPage({
    required this.tmdbId,
    required this.userId,
    this.initialPosterPath,
    this.initialTitle,
    super.key,
  });
  final String tmdbId;
  final int userId;
  final String? initialPosterPath;
  final String? initialTitle;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MovieDetailCubit>()..init(tmdbId),
      child: _MovieDetailView(
        tmdbId: tmdbId,
        userId: userId,
        initialPosterPath: initialPosterPath,
        initialTitle: initialTitle,
      ),
    );
  }
}

class _MovieDetailView extends StatelessWidget {
  const _MovieDetailView({
    required this.tmdbId,
    required this.userId,
    this.initialPosterPath,
    this.initialTitle,
  });

  final String tmdbId;
  final int userId;
  final String? initialPosterPath;
  final String? initialTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocBuilder<MovieDetailCubit, MovieDetailState>(
        builder: (context, state) {
          final loadingDetail = state.movie == null &&
              (state.status == Status.loading ||
                  state.status == Status.initial);
          if (loadingDetail) {
            final title = (initialTitle != null && initialTitle!.isNotEmpty)
                ? initialTitle!
                : 'Movie';
            return CustomScrollView(
              slivers: [
                _DetailAppBar(
                  title: title,
                  posterUrl: initialPosterPath,
                  heroTag: 'movie_$tmdbId',
                ),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 120),
                  sliver: SliverToBoxAdapter(
                    child: _MovieDetailBodyShimmer(),
                  ),
                ),
              ],
            );
          }
          final movie = state.movie;
          if (movie == null) {
            return CustomScrollView(
              slivers: [
                _DetailAppBar(
                  title: 'Movie Detail',
                  posterUrl: null,
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Movie not found',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          final hasPoster = movie.posterPath.startsWith('http');
          final releaseYear = movie.releaseDate.isEmpty
              ? 'Unknown'
              : movie.releaseDate.split('-').first;

          return CustomScrollView(
            slivers: [
              _DetailAppBar(
                title: movie.title,
                posterUrl: hasPoster ? movie.posterPath : null,
                heroTag: 'movie_${movie.tmdbId}',
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                sliver: SliverToBoxAdapter(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 400),
                    builder: (_, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - value)),
                        child: child,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          style:
                              theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    releaseYear,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedSwitcher(
                              duration:
                                  const Duration(milliseconds: 250),
                              child: Container(
                                key: ValueKey(state.saveCount),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      CupertinoIcons.heart_fill,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${state.saveCount} saved',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Overview',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                movie.overview.isEmpty
                                    ? 'No description available.'
                                    : movie.overview,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(
                                  color: theme
                                      .colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            state.saveCount > 0
                                ? '${state.saveCount} ${state.saveCount > 1 ? "users" : "user"} want to watch this'
                                : 'Be the first to save this!',
                            key: ValueKey(state.saveCount),
                            style: theme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Wrap(
                            key: ValueKey(state.watchers.length),
                            spacing: 10,
                            runSpacing: 10,
                            children: state.watchers
                                .map(
                                  (u) => Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            theme.colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: theme
                                          .colorScheme.surfaceVariant,
                                      backgroundImage:
                                          u.avatar.isNotEmpty
                                              ? CachedNetworkImageProvider(
                                                  u.avatar,
                                                )
                                              : null,
                                      child: u.avatar.isEmpty
                                          ? Text(
                                              u.firstName.isEmpty
                                                  ? 'U'
                                                  : u.firstName[0],
                                              style: theme
                                                  .textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
      floatingActionButton: BlocBuilder<MovieDetailCubit, MovieDetailState>(
        builder: (context, state) {
          final movie = state.movie;
          if (movie == null) return const SizedBox.shrink();
          return StreamBuilder<bool>(
            stream: sl<MoviesRepository>().watchIsMovieSavedForUser(
              userLocalId: userId,
              tmdbId: movie.tmdbId,
            ),
            builder: (_, snap) {
              final isSaved = snap.data ?? false;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: FilledButton.icon(
                  key: ValueKey(isSaved),
                  onPressed: () => context.read<MovieDetailCubit>().toggleSave(
                        userId: userId,
                        tmdbId: movie.tmdbId,
                      ),
                  icon: Icon(
                    isSaved ? CupertinoIcons.heart : CupertinoIcons.heart_fill,
                  ),
                  label: Text(isSaved ? 'Saved' : 'Save'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(180, 52),
                    shape: const StadiumBorder(),
                    backgroundColor: isSaved
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DetailAppBar extends StatelessWidget {
  const _DetailAppBar({
    required this.title,
    required this.posterUrl,
    this.heroTag,
  });

  final String title;
  final String? posterUrl;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPoster = posterUrl != null && posterUrl!.startsWith('http');
    final useHero = heroTag != null;

    final iconColor =
        hasPoster ? Colors.white : theme.colorScheme.onSurface;

    Widget heroChild() {
      if (hasPoster) {
        return CachedNetworkImage(
          imageUrl: posterUrl!,
          fit: BoxFit.contain,
          fadeInDuration: const Duration(milliseconds: 300),
          placeholder: (_, __) => Container(
            color: theme.colorScheme.surfaceVariant,
          ),
          errorWidget: (_, __, ___) => Container(
            color: theme.colorScheme.surfaceVariant,
            child: Icon(
              Icons.movie,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }
      return Container(
        color: theme.colorScheme.surfaceVariant,
        alignment: Alignment.center,
        child: Icon(
          Icons.movie,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    Widget flexibleBackground() {
      if (useHero) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: heroTag!,
              child: heroChild(),
            ),
            if (hasPoster)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x66000000),
                      Colors.transparent,
                      Colors.transparent,
                      Color(0xCC000000),
                    ],
                    stops: [0.0, 0.3, 0.6, 1.0],
                  ),
                ),
              ),
          ],
        );
      }
      if (hasPoster) {
        return Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: posterUrl!,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 300),
              placeholder: (_, __) => Container(
                color: theme.colorScheme.surfaceVariant,
              ),
              errorWidget: (_, __, ___) => Container(
                color: theme.colorScheme.surfaceVariant,
                child: Icon(
                  Icons.movie,
                  size: 64,
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
                    Color(0x66000000),
                    Colors.transparent,
                    Colors.transparent,
                    Color(0xCC000000),
                  ],
                  stops: [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
          ],
        );
      }
      return Container(
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
      );
    }

    return SliverAppBar(
      leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      onPressed: () => Navigator.pop(context),
    ),
      pinned: true,
      floating: false,
      snap: false,
      expandedHeight: hasPoster ? 360 : 120,
      backgroundColor: theme.colorScheme.surface.withOpacity(0.9),
      foregroundColor: iconColor,
      iconTheme: IconThemeData(color: iconColor),
      actionsIconTheme: IconThemeData(color: iconColor),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        // title: Text(
        //   title,
        //   maxLines: 1,
        //   overflow: TextOverflow.ellipsis,
        //   style: theme.textTheme.titleMedium?.copyWith(
        //     color: hasPoster ? Colors.white : theme.colorScheme.onSurface,
        //     fontWeight: FontWeight.w600,
        //   ),
        // ),
        background: flexibleBackground(),
      ),
    );
  }
}

class _MovieDetailBodyShimmer extends StatelessWidget {
  const _MovieDetailBodyShimmer();

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey.shade300;
    final highlightColor = Colors.grey.shade100;

    BoxDecoration boxDecoration() => BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        );

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 28,
            width: MediaQuery.sizeOf(context).width * 0.72,
            decoration: boxDecoration(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                height: 28,
                width: 100,
                decoration: boxDecoration(),
              ),
              const SizedBox(width: 8),
              Container(
                height: 28,
                width: 88,
                decoration: boxDecoration(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 18,
                  width: 88,
                  decoration: boxDecoration(),
                ),
                const SizedBox(height: 12),
                ...List.generate(
                  4,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      height: 14,
                      width: double.infinity,
                      decoration: boxDecoration(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 22,
            width: 220,
            decoration: boxDecoration(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              5,
              (_) => Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
