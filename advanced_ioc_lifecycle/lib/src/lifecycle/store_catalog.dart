import 'package:jetleaf/jetleaf.dart';

import 'stores.dart';

/// Demonstrates [@Primary] default resolution and [@Qualifier] disambiguation
/// for competing implementations of the same interface.
@Service()
class StoreCatalog {
  /// Resolved via @Primary (InMemoryDataStore).
  @Autowired()
  @TargetType<DataStore>()
  late DataStore defaultStore;

  /// Resolved via @Qualifier('fileStore') (FileDataStore).
  @Autowired()
  @TargetType<DataStore>()
  @Qualifier('fileStore')
  late DataStore fileStore;

  Map<String, Object?> describe() => {
        'defaultStore': defaultStore.name,
        'fileStore': fileStore.name,
      };
}
