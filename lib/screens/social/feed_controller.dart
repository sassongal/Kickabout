import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/data/feed_repository.dart';
import 'package:kattrick/data/repositories_providers.dart';

part 'feed_controller.g.dart';

class FeedFilter {
  final String? hubId;
  final String? region;
  final String
      filterType; // 'all', 'games', 'recruiting', 'achievements', 'posts'

  const FeedFilter({
    this.hubId,
    this.region,
    this.filterType = 'all',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedFilter &&
          runtimeType == other.runtimeType &&
          hubId == other.hubId &&
          region == other.region &&
          filterType == other.filterType;

  @override
  int get hashCode => hubId.hashCode ^ region.hashCode ^ filterType.hashCode;
}

@riverpod
class FeedController extends _$FeedController {
  StreamSubscription<List<FeedPost>>? _subscription;

  @override
  FutureOr<List<FeedPost>> build(FeedFilter filter) async {
    // Cancel previous subscription if any (though build usually creates a new instance or resets)
    _subscription?.cancel();

    final feedRepo = ref.read(feedRepositoryProvider);
    final postType = _getPostTypeFromFilter(filter.filterType);

    Stream<List<FeedPost>> stream;

    // Logic preserved from FeedScreen: if region is present, use regional feed
    if (filter.region != null && filter.region!.isNotEmpty) {
      stream = feedRepo.streamRegionalFeed(
        region: filter.region,
        postType: postType,
      );
    } else if (filter.hubId != null && filter.hubId!.isNotEmpty) {
      stream = feedRepo.watchFeed(filter.hubId!, postType: postType);
    } else {
      return [];
    }

    // Subscribe to the stream
    final completer = Completer<List<FeedPost>>();

    _subscription = stream.listen(
      (data) {
        state = AsyncValue.data(data);
        if (!completer.isCompleted) {
          completer.complete(data);
        }
      },
      onError: (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );

    // Clean up subscription when provider is destroyed
    ref.onDispose(() {
      _subscription?.cancel();
    });

    // Return the first batch of data
    return completer.future;
  }

  String? _getPostTypeFromFilter(String filter) {
    switch (filter) {
      case 'games':
        return 'game_completed';
      case 'recruiting':
        return 'hub_recruiting';
      case 'achievements':
        return 'achievement';
      case 'posts':
        return 'post';
      default:
        return null;
    }
  }
}
