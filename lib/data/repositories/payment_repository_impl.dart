import '../../domain/repositories/payment_repository.dart';
import '../data_source/payment_remote_data_source.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  PaymentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<String> createCheckoutSession(int amountInCents, String productId) async {
    return await remoteDataSource.createCheckoutSession(amountInCents, productId);
  }
}
