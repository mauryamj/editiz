import 'package:editiz/data/tips_remote_source.dart';

// Class: repository providing tips for the editor workflow.
class TipsRepository {
  // Field: remote data source.
  final TipsRemoteSource _remoteSource;

  // Constructor: requires TipsRemoteSource.
  const TipsRepository({
    required this._remoteSource,
  });

  // Method: fetches the current tip from remote source.
  Future<Map<String, String>> getTip() => _remoteSource.fetchTip();
}
