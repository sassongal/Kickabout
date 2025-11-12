import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Lazy loading utilities for routes
/// This helps reduce initial bundle size by loading screens only when needed

/// Lazy route builder - loads screen only when navigated to
Widget Function(BuildContext, GoRouterState) lazyRouteBuilder(
  Widget Function() screenBuilder,
) {
  return (context, state) => screenBuilder();
}

/// Deferred import helper for code splitting
/// Usage: final screen = await lazyImport(() => import('package:kickadoor/screens/...'));
Future<T> lazyImport<T>(Future<dynamic> Function() importFunction) async {
  final module = await importFunction();
  return module as T;
}

