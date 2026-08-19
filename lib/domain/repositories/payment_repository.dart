abstract class PaymentRepository {
  Future<String> createCheckoutSession(int amountInCents, String productId);
}
