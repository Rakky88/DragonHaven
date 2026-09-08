import 'canonical_game_intent.dart';

class CanonicalGameHttpReply {
  const CanonicalGameHttpReply(this.status, this.body);
  final int status;
  final Object? body;
}

/// Account-bound access to the detached server game. Implementations validate
/// Auth and fence every response against account/session changes.
abstract interface class CanonicalGameConnection {
  String? get currentOwner;
  int get sessionEpoch;
  Stream<int> get accountChanges;
  Future<Object?> read(Map<String, dynamic> request);
  Future<CanonicalGameHttpReply> send(CanonicalGameIntent intent);
  Future<Object?> recover(String requestId);
  Future<void> dispose();
}
