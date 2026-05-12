import 'package:flutter/material.dart';

class AssignmentPlaceholderScaffold extends StatelessWidget {
  const AssignmentPlaceholderScaffold({
    required this.title,
    required this.description,
    this.actions = const [],
    this.fab,
    super.key,
  });

  final String title;
  final String description;
  final List<Widget> actions;
  final Widget? fab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      floatingActionButton: fab,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            description,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
