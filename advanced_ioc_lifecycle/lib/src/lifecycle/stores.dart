import 'package:jetleaf/jetleaf.dart';

/// Data access abstraction with two competing implementations.
/// Exactly one is the default ([@Primary]); the other is selected by qualifier.
abstract interface class DataStore {
  String get name;
  Map<String, Object?> fetch(String key);
}

@Service()
@Primary()
class InMemoryDataStore implements DataStore {
  @override
  String get name => 'in-memory (primary)';

  @override
  Map<String, Object?> fetch(String key) => {
        'key': key,
        'value': 'in-memory-value',
        'store': name,
      };
}

@Service('fileStore')
class FileDataStore implements DataStore {
  @override
  String get name => 'file (qualified "fileStore")';

  @override
  Map<String, Object?> fetch(String key) => {
        'key': key,
        'value': 'file-backed-value',
        'store': name,
      };
}
