import 'dart:async';

import 'package:basic_app/app/di/injection.dart';
import 'package:basic_app/app/router/app_router.dart';
import 'package:basic_app/app/router/route_args.dart';
import 'package:basic_app/common/bloc/active_user_cubit/active_user_cubit.dart';
import 'package:basic_app/common/constants/enum/service_enum.dart';
import 'package:basic_app/core/database/app_database.dart';
import 'package:basic_app/features/saved_movies/data/repository/saved_movies_repository.dart';
import 'package:basic_app/features/users/presentation/cubit/users_cubit.dart';
import 'package:basic_app/features/users/presentation/cubit/users_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

String _userSubtitle(User user) {
  final parts = <String>[];
  if (user.email.isNotEmpty) parts.add(user.email);
  if (user.movieTaste.isNotEmpty) parts.add(user.movieTaste);
  if (parts.isEmpty) return 'No movie taste yet';
  return parts.join(' · ');
}

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<UsersCubit>()..init(),
      child: const _UsersPageView(),
    );
  }
}

class _UsersPageView extends StatefulWidget {
  const _UsersPageView();

  @override
  State<_UsersPageView> createState() => _UsersPageViewState();
}

class _UsersPageViewState extends State<_UsersPageView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final cubit = context.read<UsersCubit>();
    final position = _scrollController.position;

    if (position.pixels >= position.maxScrollExtent - 200) {
      cubit.loadNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();

    super.dispose();
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      expandedHeight: 120,
      automaticallyImplyLeading: false,
      backgroundColor: theme.colorScheme.surface.withOpacity(0.9),
      surfaceTintColor: Colors.transparent,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final top = constraints.biggest.height;
          final collapsed = top <=
              kToolbarHeight + MediaQuery.of(context).padding.top + 10;

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
              Positioned(
                left: 20,
                bottom: 16,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: collapsed ? 0.0 : 1.0,
                  child: const Text(
                    "Who's Watching?",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                bottom: 16,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: collapsed ? 1.0 : 0.0,
                  child: const Text(
                    "Who's Watching?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(CupertinoIcons.heart_fill),
          onPressed: () => Navigator.pushNamed(
            context,
            AppRouter.matches,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocBuilder<UsersCubit, UsersState>(
        builder: (context, state) {
          if (state.status == Status.loading && state.users.isEmpty) {
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildAppBar(context),
                SliverList.builder(
                  itemCount: 8,
                  itemBuilder: (_, __) => const _UserCardShimmer(),
                ),
              ],
            );
          }

          if (state.users.isEmpty) {
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildAppBar(context),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.group_off_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No users yet — add one!',
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
            children: [
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _buildAppBar(context),
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 8, bottom: 120),
                    sliver: SliverList.builder(
                      itemCount: state.users.length,
                      itemBuilder: (context, index) {
                        final user = state.users[index];

                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration:
                              Duration(milliseconds: 200 + (index * 20)),
                          builder: (_, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: Card(
                              elevation: 0,
                              color: theme.colorScheme.surfaceVariant,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  context
                                      .read<ActiveUserCubit>()
                                      .setActiveUser(user.localId);

                                  Navigator.pushNamed(
                                    context,
                                    AppRouter.movies,
                                    arguments:
                                        MoviesRouteArgs(user.localId),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
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
                                          radius: 24,
                                          backgroundImage:
                                              user.avatar.isNotEmpty
                                                  ? CachedNetworkImageProvider(
                                                      user.avatar,
                                                    )
                                                  : null,
                                          child: user.avatar.isEmpty
                                              ? Text(
                                                  user.firstName.isEmpty
                                                      ? 'U'
                                                      : user.firstName[0],
                                                )
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${user.firstName} ${user.lastName}'
                                                  .trim(),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: theme
                                                  .textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _userSubtitle(user),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: theme
                                                  .textTheme.bodySmall
                                                  ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      StreamBuilder<int>(
                                        stream: sl
                                            .get<SavedMoviesRepository>()
                                            .watchForUser(user.localId)
                                            .map((e) => e.length),
                                        builder: (_, snap) {
                                          return AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 220,
                                            ),
                                            child: Container(
                                              key: ValueKey(
                                                snap.data ?? 0,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: theme
                                                    .colorScheme.primary,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  20,
                                                ),
                                              ),
                                              child: Text(
                                                '${snap.data ?? 0} saved',
                                                style: theme
                                                    .textTheme.labelMedium
                                                    ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 28,
                left: 0,
                right: 0,
                child: Center(
                  child: _AddUserFab(
                    scrollController: _scrollController,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AddUserFab extends StatefulWidget {
  const _AddUserFab({
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  State<_AddUserFab> createState() => _AddUserFabState();
}

class _AddUserFabState extends State<_AddUserFab> {
  bool _visible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_visible) {
      setState(() => _visible = false);
    }

    _hideTimer?.cancel();

    _hideTimer = Timer(
      const Duration(milliseconds: 600),
      () {
        if (mounted) {
          setState(() => _visible = true);
        }
      },
    );
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 1.5),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: FilledButton.icon(
          onPressed: () => Navigator.pushNamed(
            context,
            AppRouter.addUser,
          ),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Add User'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
            ),
            shape: const StadiumBorder(),
          ),
        ),
      ),
    );
  }
}

class _UserCardShimmer extends StatelessWidget {
  const _UserCardShimmer();

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey.shade300;
    final highlightColor = Colors.grey.shade100;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 100,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}