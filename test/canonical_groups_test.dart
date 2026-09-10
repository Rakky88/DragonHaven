import 'dart:async';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/services/canonical_groups.dart';
import 'package:dragon_haven/services/canonical_game_connection.dart';
import 'package:dragon_haven/services/canonical_game_intent.dart';
import 'package:flutter_test/flutter_test.dart';

class Connection implements CanonicalGameConnection {
  @override
  String? currentOwner = 'owner';
  @override
  int sessionEpoch = 1;
  final changes = StreamController<int>.broadcast(sync: true);
  @override
  Stream<int> get accountChanges => changes.stream;
  void switchAccount(String? owner) {
    currentOwner = owner;
    sessionEpoch++;
    changes.add(sessionEpoch);
  }

  @override
  Future<Object?> read(Map<String, dynamic> request) =>
      throw UnimplementedError();
  @override
  Future<CanonicalGameHttpReply> send(CanonicalGameIntent intent) =>
      throw UnimplementedError();
  @override
  Future<Object?> recover(String id) => throw UnimplementedError();
  @override
  Future<void> dispose() => changes.close();
}

class Source implements CanonicalGroupsSource {
  final requests = <({
    String owner,
    Completer<GroupAdventureStatus> status,
    Completer<List<GroupAdventureLobby>> lobbies
  })>[];
  @override
  Future<GroupAdventureStatus> status(String owner) {
    final status = Completer<GroupAdventureStatus>();
    final lobbies = Completer<List<GroupAdventureLobby>>();
    requests.add((owner: owner, status: status, lobbies: lobbies));
    return status.future;
  }

  @override
  Future<List<GroupAdventureLobby>> lobbies(String owner) =>
      requests.last.lobbies.future;
  void finish(int i, String adventure) {
    requests[i].status.complete(GroupAdventureStatus(
        slot: i, adventureId: adventure, alreadyCompleted: false));
    requests[i].lobbies.complete(const []);
  }
}

void main() {
  test('coalesces reads and drops both old-account and old-epoch replies',
      () async {
    final connection = Connection();
    final source = Source();
    final groups = CanonicalGroups(connection: connection, source: source);
    final old = groups.refresh();
    expect(identical(old, groups.refresh()), isTrue);
    expect(source.requests.length, 1);
    connection.switchAccount('other');
    expect(groups.status, isNull);
    expect(groups.loading, isFalse);
    final current = groups.refresh();
    source.finish(1, 'group_2');
    await current;
    expect(groups.status!.adventureId, 'group_2');
    source.finish(0, 'group_1');
    await old;
    expect(groups.status!.adventureId, 'group_2');
    final stale = groups.refresh();
    connection.switchAccount(null);
    connection.switchAccount('other');
    source.finish(2, 'group_3');
    await stale;
    expect(groups.status, isNull);
    expect(groups.lobbies, isEmpty);
    groups.dispose();
    await connection.dispose();
  });
  test(
      'failed refresh removes stale actionable offers and dispose ignores late reads',
      () async {
    final connection = Connection();
    final source = Source();
    final groups = CanonicalGroups(connection: connection, source: source);
    final first = groups.refresh();
    source.finish(0, 'group_1');
    await first;
    final failed = groups.refresh();
    source.requests[1].status.completeError(StateError('offline'));
    source.requests[1].lobbies.complete(const []);
    await failed;
    expect(groups.status, isNull);
    expect(groups.error, 'game_connection_failed');
    expect(groups.loading, isFalse);
    final late = groups.refresh();
    groups.dispose();
    source.finish(2, 'group_2');
    await late;
    expect(groups.status, isNull);
    await connection.dispose();
  });
}
