import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

export 'file_storage_backend.dart';
export 'file_storage_backend_with_static_asset.dart';
export 'api_resource_cubit.dart';
export 'api_resource_builder.dart';
export 'action_resource.dart';

/// The [BasicApiResourceRepository] implements a simple repository that can
/// fetch data and store it for use later.
///
/// It will store the responses it gets when it gets them and store them in a file
/// which will be reloaded when the app initializes again.
///
/// When initialized or when asked to refresh programmatically the [fetchExternalData]
/// function will be called. The response will be cached and processed and a the results
/// will be propagated
///
abstract class BasicApiResourceRepository<T> {
  /// Represents whether or not this repository has been initialized
  ///
  bool get initialized => _initialized;
  bool _initialized = false;

  final BehaviorSubject<T> repo;

  /// Returns the internal state of the repository
  Stream<T> get stream => repo.stream;

  final StorageBackend backend;

  BasicApiResourceRepository(this.backend) : repo = BehaviorSubject() {
    initialize();
  }

  /// Returns the key used to determine where to look for the data for this
  /// repository.
  ///
  /// This key is often used by the [StorageBackend] to determine things such as
  /// file location on disk. Therefore these names should be something compatible
  /// with your storage backend. If using things such as the file backend, dots
  /// and slashes might break the backend as we do not do any transformations
  /// of the keys
  ///
  /// One idea might be to hash your key if it contains user input
  ///
  String get key;

  /// Initializes the repository.
  /// Should only be done once. Will try to retrieve the state from a [StorageBackend]
  /// then will try to refetch it and store a new state.
  ///
  /// This is a stopgap measure in order reduce latency when fetching large resources
  ///
  Future<void> initialize() async {
    _initialized = true;
    try {
      var value = await _fetchInternalData();

      if (value != null) {
        repo.add(convert(value));
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
      _removeFile();
    }
  }

  Future<void> refresh() async {
    try {
      var data = await fetchExternalData();
      repo.add(convert(data));
      _saveData(data);
    } catch (e) {
      _removeFile();
      rethrow;
    }
  }

  /// Fetches new data and stores it in the [StorageBackend]
  Future<String> fetchExternalData();
  T convert(String data);

  Future<void> _saveData(String contents) async {
    try {
      backend.saveData(key, contents);
    } on Exception {
      if (kDebugMode) {
        rethrow;
      }
      _removeFile();
    }
  }

  Future<void> _removeFile() async {
    try {
      backend.deleteData(key);
    } on Exception {
      if (kDebugMode) {
        rethrow;
      }
    }
  }

  Future<String?> _fetchInternalData() async {
    try {
      return backend.getData(key);
    } on Exception catch (e) {
      if (kDebugMode) {
        rethrow;
      }
      _removeFile();
      return null;
    }
  }
}

/// The [StorageBackend] is a backend that can store data and retreive data for use
/// with the [BasicApiResourceRepositories].
///
abstract class StorageBackend {
  Future<String?> getData(String key);

  Future<void> deleteData(String key);

  Future<void> saveData(String key, String contents);
}
