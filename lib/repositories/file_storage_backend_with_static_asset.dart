import 'package:flutter/services.dart';
import 'package:flutter_bootstrap/flutter_bootstrap.dart';

Future<String?> Function (String) _getRootBundleContent(String filename) =>
        (key) => rootBundle.loadString(filename, cache: false);

/// The [StorageBackendWithStaticFallback] wraps another [StorageBackend] but
/// it will attempt to resolve static assets if no more recent data is stored
/// and can be retrieved from the other storage backend
///
/// The [StorageBackendWithStaticFallback.rootBundle] constructor is a built
/// in shorthand to get things from the root bundle.
class StorageBackendWithStaticFallback extends StorageBackend {
  final StorageBackend storageBackend;
  final Future<String?> Function(String) contentGetter;

  StorageBackendWithStaticFallback(this.storageBackend,
      {required this.contentGetter});

  StorageBackendWithStaticFallback.rootBundle(this.storageBackend,
      String filename) : contentGetter = _getRootBundleContent(filename);

  @override
  Future<void> deleteData(String key) async {
    await storageBackend.deleteData(key);
  }

  @override
  Future<String?> getData(String key) async {
    return (await storageBackend.getData(key)) ?? (await contentGetter(key));
  }

  @override
  Future<void> saveData(String key, String contents) async {
    return (await storageBackend.saveData(key, contents));
  }
}
