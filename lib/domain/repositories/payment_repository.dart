abstract class PaymentRepository {
  Future<void> init();
  Future<bool> purchaseListingFee();
}

