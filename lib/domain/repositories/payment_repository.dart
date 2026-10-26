abstract class PaymentRepository {
  Future<void> init();
  Future<void> logIn(String userId);
  Future<bool> purchaseListingFee({String? productId});
}
