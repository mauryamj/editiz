import 'package:flutter/foundation.dart';
import 'package:editiz/models/creation.dart';
import 'package:editiz/repositories/creations_repository.dart';

/// Simple controller managing saved creations.
class CreationsController extends ChangeNotifier {
  final CreationsRepository repository;

  List<Creation> creations = [];
  bool isLoading = true;
  String? errorMessage;

  CreationsController({required this.repository}) {
    loadCreations();
  }

  /// Loads creations from database
  Future<void> loadCreations() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      creations = await repository.getCreations();
    } catch (_) {
      errorMessage = 'Failed to load creations.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes a creation
  Future<void> deleteCreation(Creation creation) async {
    try {
      await repository.deleteCreation(creation);
      creations.removeWhere((c) => c.id == creation.id);
      notifyListeners();
    } catch (_) {
      errorMessage = 'Failed to delete creation.';
      notifyListeners();
    }
  }
}
