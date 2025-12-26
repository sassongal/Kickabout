import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/premium/empty_state.dart';
import 'package:kattrick/core/providers/complex_providers.dart';
import 'package:kattrick/models/models.dart';

/// Hub rules screen - displays hub rules in a dedicated page
class HubRulesScreen extends ConsumerWidget {
  final String hubId;

  const HubRulesScreen({super.key, required this.hubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubAsync = ref.watch(hubStreamProvider(hubId));

    return hubAsync.when(
      data: (hub) {
        if (hub == null) {
          return AppScaffold(
            title: 'חוקי ההאב',
            body: Center(
              child: Text('Hub לא נמצא'),
            ),
          );
        }
        return _buildContent(context, hub);
      },
      loading: () => AppScaffold(
        title: 'חוקי ההאב',
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => AppScaffold(
        title: 'חוקי ההאב',
        body: Center(
          child: Text('שגיאה בטעינת חוקי ההאב'),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Hub hub) {
    if (hub.hubRules == null || hub.hubRules!.isEmpty) {
      return AppScaffold(
        title: 'חוקי ההאב',
        body: PremiumEmptyState(
          icon: Icons.rule,
          title: 'אין חוקים מוגדרים',
          message: 'מנהל ה-Hub עדיין לא הגדיר חוקים',
        ),
      );
    }

    return AppScaffold(
      title: 'חוקי ההאב',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.rule,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'חוקי ההאב',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  hub.hubRules!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

