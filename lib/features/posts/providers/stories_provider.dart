// ===============================
// FILE PATH: lib/features/stories/providers/stories_provider.dart
// ===============================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project/features/stories/data/stories_service.dart';

/// Provides a single, globally accessible instance of StoriesService
final storiesServiceProvider = Provider<StoriesService>((ref) {
  return StoriesService();
});

/// Streams the active stories from the last 24 hours.
/// Caching this stream prevents the stories bar at the top of the app
/// from flickering and draining memory every time you scroll down the feed.
final activeStoriesProvider = StreamProvider<List<Story>>((ref) {
  final storiesService = ref.watch(storiesServiceProvider);
  return storiesService.getActiveStories();
});
