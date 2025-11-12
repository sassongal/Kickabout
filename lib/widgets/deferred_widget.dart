import 'package:flutter/material.dart';

/// וידג'ט עזר לטעינת ספריות Deferred (טעינה עצלה של מסכים כבדים).
class DeferredWidget extends StatefulWidget {
  final Future<void> Function() loadLibrary;
  final WidgetBuilder builder;
  final WidgetBuilder? errorBuilder;
  final Widget? placeholder;

  const DeferredWidget({
    super.key,
    required this.loadLibrary,
    required this.builder,
    this.errorBuilder,
    this.placeholder,
  });

  @override
  State<DeferredWidget> createState() => _DeferredWidgetState();
}

class _DeferredWidgetState extends State<DeferredWidget> {
  late final Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = widget.loadLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return widget.builder(context);
        }

        if (snapshot.hasError) {
          if (widget.errorBuilder != null) {
            return widget.errorBuilder!(context);
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'אירעה שגיאה בטעינת המסך: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return widget.placeholder ??
            const Center(
              child: CircularProgressIndicator.adaptive(),
            );
      },
    );
  }
}
