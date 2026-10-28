import 'package:flutter/foundation.dart';
import 'package:editiz/models/app_exception.dart';
import 'package:editiz/repositories/tips_repository.dart';

/// Simple controller fetching remote tips.
class TipsController extends ChangeNotifier {
  final TipsRepository repository;

  String title = '';
  String body = '';
  bool isLoading = true;
  String? errorMessage;

  TipsController({required this.repository}) {
    loadTip();
  }

  /// Fetches a tip from the remote API
  Future<void> loadTip() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final tip = await repository.getTip();
      title = tip['title'] ?? 'Editing Tip';
      body = tip['body'] ?? '';
    } on AppException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Could not load tip.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
