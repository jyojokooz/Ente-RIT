// ===============================
// FILE PATH: lib/helpers/app_cache_manager.dart
// ===============================

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class AppCacheManager {
  // Unique key for the custom cache configuration
  static const String key = 'enteRitAggressiveCache';

  // Singleton instance of the CacheManager
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30), // Keep images in cache for 30 days
      maxNrOfCacheObjects: 1000, // Store up to 1000 images locally
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}
