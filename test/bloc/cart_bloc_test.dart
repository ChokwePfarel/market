import 'package:flutter_test/flutter_test.dart';
import 'package:market/domain/entities/product_entity.dart';
import 'package:market/domain/repositories/cart_repository.dart';
import 'package:market/features/cart/bloc/cart_bloc.dart';
import 'package:market/features/cart/bloc/cart_event.dart';
import 'package:market/features/cart/bloc/cart_state.dart';

class FakeCartRepository implements CartRepository {
  List<ProductEntity> cartProductsToReturn = [];
  bool shouldThrow = false;

  @override
  Future<List<ProductEntity>> getCartProducts(String userId) async {
    if (shouldThrow) throw Exception('Database error fetching cart');
    return cartProductsToReturn;
  }

  @override
  Future<void> addToCart(String userId, String productId) async {
    if (shouldThrow) throw Exception('Database error adding to cart');
  }

  @override
  Future<void> removeFromCart(String userId, String productId) async {
    if (shouldThrow) throw Exception('Database error removing from cart');
  }

  @override
  Future<void> clearCart(String userId) async {
    if (shouldThrow) throw Exception('Database error clearing cart');
  }
}

void main() {
  late FakeCartRepository fakeCartRepository;
  late CartBloc cartBloc;

  final sampleProduct = ProductEntity(
    id: 'prod-101',
    name: 'Calculus Textbook',
    description: '10th Edition',
    price: 350.0,
    category: 'Books',
    university: 'UCT',
    imageUrls: const ['https://example.com/book.jpg'],
    sellerId: 'seller-1',
    status: 'active',
    createdAt: DateTime.now(),
  );

  setUp(() {
    fakeCartRepository = FakeCartRepository();
    cartBloc = CartBloc(fakeCartRepository);
  });

  tearDown(() {
    cartBloc.close();
  });

  group('CartBloc Critical Flow Tests', () {
    test('initial state is CartInitial', () {
      expect(cartBloc.state, isA<CartInitial>());
    });

    test('LoadCart event emits CartLoaded with products', () async {
      fakeCartRepository.cartProductsToReturn = [sampleProduct];

      final expected = [
        isA<CartLoaded>().having((s) => s.products.length, 'products length', 1),
      ];

      expectLater(cartBloc.stream, emitsInOrder(expected));

      cartBloc.add(const LoadCart('user-1'));
    });

    test('AddToCart adds product to cart state', () async {
      cartBloc.add(LoadCart('user-1'));
      await cartBloc.stream.firstWhere((s) => s is CartLoaded);

      cartBloc.add(AddToCart(userId: 'user-1', product: sampleProduct));

      final state = await cartBloc.stream.firstWhere((s) => s is CartLoaded) as CartLoaded;
      expect(state.products.length, 1);
      expect(state.products.first.id, 'prod-101');
      expect(state.message, contains('Added "Calculus Textbook" to cart'));
    });

    test('RemoveFromCart removes product from cart state', () async {
      fakeCartRepository.cartProductsToReturn = [sampleProduct];
      cartBloc.add(const LoadCart('user-1'));
      await cartBloc.stream.firstWhere((s) => s is CartLoaded);

      cartBloc.add(const RemoveFromCart(userId: 'user-1', productId: 'prod-101'));

      final state = await cartBloc.stream.firstWhere((s) => s is CartLoaded) as CartLoaded;
      expect(state.products, isEmpty);
    });

    test('ClearCart empties all products from cart state', () async {
      fakeCartRepository.cartProductsToReturn = [sampleProduct];
      cartBloc.add(const LoadCart('user-1'));
      await cartBloc.stream.firstWhere((s) => s is CartLoaded);

      cartBloc.add(const ClearCart('user-1'));

      final state = await cartBloc.stream.firstWhere((s) => s is CartLoaded) as CartLoaded;
      expect(state.products, isEmpty);
    });
  });
}
