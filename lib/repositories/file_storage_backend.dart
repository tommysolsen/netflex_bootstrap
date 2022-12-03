import 'dart:io';

import 'package:flutter_bootstrap/flutter_bootstrap.dart';
import 'package:path_provider/path_provider.dart';

enum StorageLocation {
  temporaryDirectory,
  documentsDirectory,
  applicationSupportDirectory
}

/// Stores data in a directory on drive
extension StorageLocationDirectory on StorageLocation {
  Future<Directory> getDirectory() async {
    switch (this) {
      case StorageLocation.temporaryDirectory:
        return await getTemporaryDirectory();
      case StorageLocation.documentsDirectory:
        return await getApplicationDocumentsDirectory();
      case StorageLocation.applicationSupportDirectory:
        return await getApplicationSupportDirectory();
    }
  }
}

/// The [FileStorageBackend] will store the data in the temporary directory
/// for the application and try to restore it from there
class FileStorageBackend extends StorageBackend {

  final StorageLocation storageLocation;

  FileStorageBackend([this.storageLocation = StorageLocation.temporaryDirectory]);

  @override
  Future<String?> getData(String key) async {
    var file = await _getFile(key);

    if (await file.exists()) {
      return await file.readAsString();
    }

    return null;
  }

  @override
  Future<void> deleteData(String key) async {
    var file = await _getFile(key);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> saveData(String key, String contents) async {
    var file = await _getFile(key);
    await file.writeAsString(contents);
    return;
  }

  Future<File> _getFile(String key) async =>
      File("${(await storageLocation.getDirectory()).path}/$key");
}
