import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/social.dart';
import 'account_scoped_social_reader.dart';
import 'canonical_game_snapshot.dart';

typedef CanonicalPartnerList = ({
  bool canInvite,
  List<SeasonalPairAdventure> pairs
});

abstract interface class CanonicalPartnersSource {
  Future<CanonicalPartnerList> load(String owner);
}

class SupabaseCanonicalPartnersSource implements CanonicalPartnersSource {
  SupabaseCanonicalPartnersSource(this.client);
  final SupabaseClient client;
  @override
  Future<CanonicalPartnerList> load(String owner) async {
    void requireOwner() {
      if (client.auth.currentUser?.id != owner) {
        throw const CanonicalGameException('game_account_changed');
      }
    }

    requireOwner();
    final values = await Future.wait<Object>([
      client.rpc('get_canonical_pair_offer'),
      client.rpc('list_my_seasonal_pair_adventures')
    ]);
    requireOwner();
    final offer = values[0];
    final pairs = values[1];
    if (offer is! bool || pairs is! List || pairs.any((row) => row is! Map)) {
      throw const CanonicalGameException('game_snapshot_invalid');
    }
    return (
      canInvite: offer,
      pairs: List<SeasonalPairAdventure>.unmodifiable(pairs.map((row) =>
          SeasonalPairAdventure.fromJson(
              Map<String, dynamic>.from(row as Map))))
    );
  }
}

class CanonicalPartners
    extends AccountScopedSocialReader<CanonicalPartnerList> {
  CanonicalPartners(
      {required super.connection, required CanonicalPartnersSource source})
      : super(load: source.load);
  bool get canInvite => value?.canInvite == true;
  List<SeasonalPairAdventure> get pairs => value?.pairs ?? const [];
}
