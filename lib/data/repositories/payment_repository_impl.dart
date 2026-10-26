import '../../domain/repositories/payment_repository.dart';
import '../data_source/payment_remote_data_source.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  PaymentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> init() async {
    await remoteDataSource.init();
  }

  @override
  Future<void> logIn(String userId) async {
    await remoteDataSource.logIn(userId);
  }

  @override
  Future<bool> purchaseListingFee({String? productId}) async {
    return await remoteDataSource.purchaseListingFee(productId: productId);
  }
}
