import 'package:test/test.dart';

import 'package:advanced_ioc_lifecycle/src/lifecycle/stores.dart';

void main() {
  group('DataStore implementations', () {
    test('InMemoryDataStore reports its name and returns values', () {
      final store = InMemoryDataStore();
      expect(store.name, contains('primary'));
      final result = store.fetch('k');
      expect(result['store'], contains('primary'));
      expect(result['value'], 'in-memory-value');
    });

    test('FileDataStore reports qualified name and returns values', () {
      final store = FileDataStore();
      expect(store.name, contains('fileStore'));
      final result = store.fetch('k');
      expect(result['store'], contains('fileStore'));
      expect(result['value'], 'file-backed-value');
    });
  });
}
