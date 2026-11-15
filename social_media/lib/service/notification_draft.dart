/// `@Scope('prototype')` pod — a fresh draft per injection/lookup.
///
/// Demonstrates prototypes resolving correctly (framework fix in
/// `jetleaf_core`: the scope marker is now emitted by `jl build` and honored
/// by the container).
library;

import 'package:jetleaf/jetleaf.dart';

@Scope('prototype')
@Component()
class NotificationDraft {
  String? _title;
  String? _body;
  String? _recipient;

  static int created = 0;

  NotificationDraft() {
    created++;
  }

  NotificationDraft title(String value) => this.._title = value;
  NotificationDraft body(String value) => this.._body = value;
  NotificationDraft recipient(String value) => this.._recipient = value;

  bool get isComplete =>
      _title != null && _title!.isNotEmpty && _body != null && _body!.isNotEmpty;

  Map<String, Object?> build() => {
        'title': _title,
        'body': _body,
        'recipient': _recipient,
        'complete': isComplete,
      };

  @PostConstruct()
  void onCreate() {
    // Fires exactly once per prototype instance.
  }
}
