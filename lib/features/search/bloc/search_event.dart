import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchQueryChanged extends SearchEvent {
  final String query;
  final String university;

  const SearchQueryChanged({required this.query, required this.university});

  @override
  List<Object?> get props => [query, university];
}

class ClearSearch extends SearchEvent {}
