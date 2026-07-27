import 'package:flutter/material.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(children: children);
  }
}
