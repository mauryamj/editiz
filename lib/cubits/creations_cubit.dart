import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:editiz/models/creation.dart';
import 'package:editiz/repositories/creations_repository.dart';

// Class: base state for CreationsCubit.
abstract class CreationsState {
  const CreationsState();
}

// Class: loading state while reading creations from Hive.
class CreationsLoading extends CreationsState {
  const CreationsLoading();
}

// Class: loaded state containing the list of creations.
class CreationsLoaded extends CreationsState {
  // Field: list of saved creation models.
  final List<Creation> creations;

  // Constructor: requires creations list.
  const CreationsLoaded(this.creations);
}

// Class: error state when creations fail to load or delete.
class CreationsFailure extends CreationsState {
  // Field: error message.
  final String message;

  // Constructor: requires error message.
  const CreationsFailure(this.message);
}

// Class: cubit managing the list of user creations.
class CreationsCubit extends Cubit<CreationsState> {
  // Field: repository for creations.
  final CreationsRepository _repository;

  // Constructor: starts in loading state and initiates fetch.
  CreationsCubit({required this._repository})
      : super(const CreationsLoading()) {
    loadCreations();
  }

  // Method: loads or reloads creations from repository.
  Future<void> loadCreations() async {
    emit(const CreationsLoading());
    try {
      final list = await _repository.getCreations();
      if (!isClosed) {
        emit(CreationsLoaded(list));
      }
    } catch (_) {
      if (!isClosed) {
        emit(const CreationsFailure('Failed to load creations.'));
      }
    }
  }

  // Method: deletes a creation and refreshes list.
  Future<void> deleteCreation(Creation creation) async {
    try {
      await _repository.deleteCreation(creation);
      await loadCreations();
    } catch (_) {
      if (!isClosed) {
        emit(const CreationsFailure('Failed to delete creation.'));
      }
    }
  }
}
