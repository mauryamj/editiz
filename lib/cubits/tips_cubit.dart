import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:editiz/models/app_exception.dart';
import 'package:editiz/repositories/tips_repository.dart';

// Class: base state for TipsCubit.
abstract class TipsState {
  const TipsState();
}

// Class: state while tip is loading.
class TipsLoading extends TipsState {
  const TipsLoading();
}

// Class: state when tip was successfully loaded.
class TipsLoaded extends TipsState {
  // Field: tip title.
  final String title;

  // Field: tip content body.
  final String body;

  // Constructor: requires title and body.
  const TipsLoaded({required this.title, required this.body});
}

// Class: state when tip loading failed.
class TipsFailure extends TipsState {
  // Field: error message.
  final String message;

  // Constructor: requires message.
  const TipsFailure(this.message);
}

// Class: cubit fetching editing tips from JSONPlaceholder via TipsRepository.
class TipsCubit extends Cubit<TipsState> {
  // Field: tips repository.
  final TipsRepository _repository;

  // Constructor: starts loading tip immediately.
  TipsCubit({required this._repository})
      : super(const TipsLoading()) {
    loadTip();
  }

  // Method: fetches a tip and emits corresponding state.
  Future<void> loadTip() async {
    emit(const TipsLoading());
    try {
      final tip = await _repository.getTip();
      if (!isClosed) {
        emit(TipsLoaded(
          title: tip['title'] ?? 'Pro Tip',
          body: tip['body'] ?? '',
        ));
      }
    } on AppException catch (e) {
      if (!isClosed) emit(TipsFailure(e.message));
    } catch (_) {
      if (!isClosed) {
        emit(const TipsFailure('Could not load editing tip right now.'));
      }
    }
  }
}
