/// Shared contracts between the Flutter client and the Jetleaf API.
///
/// Both sides import this package — the server for its REST payloads and
/// the client for its HTTP models — so field names, nullability and
/// serialization can never drift apart.
library;

export 'src/note.dart';
