import 'package:basic_app/app/di/injection.dart';
import 'package:basic_app/common/bloc/connectivity_cubit/connectivity_cubit.dart';
import 'package:basic_app/common/constants/enum/service_enum.dart';
import 'package:basic_app/common/widget/util_widgets/util_widgets.dart';
import 'package:basic_app/features/users/presentation/cubit/add_user_cubit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddUserPage extends StatelessWidget {
  const AddUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AddUserCubit>(),
      child: const _AddUserView(),
    );
  }
}

class _AddUserView extends StatefulWidget {
  const _AddUserView();

  @override
  State<_AddUserView> createState() => _AddUserViewState();
}

class _AddUserViewState extends State<_AddUserView> {
  late final TextEditingController _nameController;
  late final TextEditingController _tasteController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _tasteController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tasteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocConsumer<AddUserCubit, AddUserState>(
        listener: (context, state) {
          if (state.status == Status.success ||
              state.status == Status.failure) {
            final msg = state.message ?? 'Done';
            UtilWidgets.toastMessage(msg);
            if (state.status == Status.success) {
              Navigator.pop(context);
            }
          }
        },
        builder: (context, state) {
          final isLoading = state.status == Status.loading;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
                pinned: true,
                floating: false,
                snap: false,
                expandedHeight: 100,
                backgroundColor: theme.colorScheme.surface.withOpacity(0.9),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  
                  title: const Text('Add User'),
                  background: Container(
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
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                sliver: SliverToBoxAdapter(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 300),
                    builder: (_, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
Container(
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: CupertinoColors.inactiveGray.withOpacity(0.25),
    borderRadius: BorderRadius.circular(24),
  ),
  child: Row(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: CupertinoColors.activeBlue.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          CupertinoIcons.person_add_solid,
          color: CupertinoColors.activeBlue,
        ),
      ),

      const SizedBox(width: 14),

      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New movie buddy',
              style: CupertinoTheme.of(context)
                  .textTheme
                  .navTitleTextStyle
                  .copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
            ),

            const SizedBox(height: 4),

            Text(
              'Add someone to share saved films with.',
              style: CupertinoTheme.of(context)
                  .textTheme
                  .textStyle
                  .copyWith(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
            ),
          ],
        ),
      ),
    ],
  ),
),
                        const SizedBox(height: 24),

CupertinoTextField(
  controller: _nameController,
  placeholder: 'Enter full name',
  decoration: BoxDecoration(
    color: CupertinoColors.systemGrey6,
    borderRadius: BorderRadius.circular(20),
  ),
  prefix: const Padding(
    padding: EdgeInsets.only(left: 12),
    child: Icon(CupertinoIcons.person),
  ),
  padding: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 14,
  ),
  textCapitalization: TextCapitalization.words,
  enabled: !isLoading,
),

const SizedBox(height: 16),

CupertinoTextField(
  controller: _tasteController,
  placeholder: 'e.g., loves horror, no sad endings',
  decoration: BoxDecoration(
    color: CupertinoColors.systemGrey6,
    borderRadius: BorderRadius.circular(20),
  ),
  prefix: const Padding(
    padding: EdgeInsets.only(left: 12),
    child: Icon(CupertinoIcons.film),
  ),
  padding: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 14,
  ),
  maxLines: 2,
  textCapitalization: TextCapitalization.sentences,
  enabled: !isLoading,
),

const SizedBox(height: 12),
                        StreamBuilder<bool>(
                          stream:
                              context.read<ConnectivityCubit>().stream,
                          initialData:
                              context.read<ConnectivityCubit>().state,
                          builder: (_, snap) {
                            final isOnline = snap.data ?? false;
                            final color = isOnline
                                ? Colors.green
                                : theme.colorScheme.tertiary;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isOnline ? Icons.wifi : Icons.wifi_off,
                                    size: 18,
                                    color: color,
                                  ),
                                 const SizedBox(width: 8),

                                Expanded(
                                  child: Text(
                                    isOnline
                                        ? 'Online — will sync immediately'
                                        : 'Offline — will sync when online',
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),],
                                                              
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 54,
                          child: CupertinoButton.filled(
                            borderRadius: BorderRadius.circular(20),
                            onPressed: isLoading
                                ? null
                                : () {
                                    final name = _nameController.text.trim();
                                    final taste = _tasteController.text.trim();

                                    if (name.isEmpty || taste.isEmpty) {
                                      UtilWidgets.toastMessage(
                                        'Please fill all fields',
                                      );
                                      return;
                                    }

                                    final isOffline =
                                        !context.read<ConnectivityCubit>().state;

                                    context.read<AddUserCubit>().submit(
                                          name: name,
                                          movieTaste: taste,
                                          isOffline: isOffline,
                                        );
                                  },
                            child: isLoading
                                ? const CupertinoActivityIndicator(
                                    color: CupertinoColors.white,
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(CupertinoIcons.person_add),
                                      SizedBox(width: 8),
                                      Text('Save User'),
                                    ],
                                  ),
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
    );
  }
}
