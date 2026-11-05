import 'package:equatable/equatable.dart';

class ReviewEntity extends Equatable {
  final String id;
  final String serviceId;
  final String reviewerId;
  final int rating; // e.g. 1 to 5
  final String comment;
  final DateTime createdAt;

  const ReviewEntity({
    required this.id,
    required this.serviceId,
    required this.reviewerId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  ReviewEntity copyWith({
    String? id,
    String? serviceId,
    String? reviewerId,
    int? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return ReviewEntity(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      reviewerId: reviewerId ?? this.reviewerId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        serviceId,
        reviewerId,
        rating,
        comment,
        createdAt,
      ];
}
