import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/product_repository.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final ProductRepository _productRepository;
  Timer? _debounce;

  SearchBloc(this._productRepository) : super(SearchInitial()) {
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<ClearSearch>(_onClearSearch);
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    _debounce?.cancel();
    
    if (event.query.isEmpty) {
      emit(SearchInitial());
      return;
    }

    final completer = Completer<void>();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!completer.isCompleted) completer.complete();
    });

    await completer.future;
    
    // The Emitter checks if it's still active. If a new event came in, 
    // the previous one's execution will continue but we should check state.
    if (emit.isDone) return;
    
    emit(SearchLoading());

    try {
      final results = await _productRepository.searchProducts(
        query: event.query,
        university: event.university,
      );
      if (!emit.isDone) {
        emit(SearchResultsLoaded(products: results, query: event.query));
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(SearchError(e.toString()));
      }
    }
  }

  void _onClearSearch(ClearSearch event, Emitter<SearchState> emit) {
    _debounce?.cancel();
    emit(SearchInitial());
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
