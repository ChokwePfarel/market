import 'package:flutter_test/flutter_test.dart';
import 'package:market/domain/entities/product_entity.dart';
import 'package:market/domain/repositories/product_repository.dart';
import 'package:market/features/product/bloc/my_products_bloc.dart';

class FakeProductRepository implements ProductRepository {

  List<ProductEntity> userProductsToReturn = [];
  bool shouldThrow = false;

  @override
  Future<List<ProductEntity>> getUserProducts(String userId) async {
    if (shouldThrow) {
      throw Exception('Database connection failed');
    }
    return userProductsToReturn;
  }

  @override
  Future<int> getUserProductCount(String userId) async => userProductsToReturn.length;

  @override
  Future<List<ProductEntity>> searchProducts({
    required String query,
    required String university,
  }) async => [];

  @override
  Future<void> updateProductPrice(String productId, double newPrice) async {
    if (shouldThrow) {
      throw Exception('Update price failed');
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    if (shouldThrow) {
      throw Exception('Delete failed');
    }
  }

  @override
  Future<void> activateProduct(String productId) async {
    if (shouldThrow) {
      throw Exception('Activation failed');
    }
  }

  @override
  Future<void> createProduct(ProductEntity product) async {}

  @override
  Future<List<ProductEntity>> getOtherUserProducts(String userId) async => [];

  @override
  Future<List<ProductEntity>> getProducts({
    required String university,
    required String category,
    int limit = 10,
    int offset = 0,
  }) async => [];
}

void main() {
  late FakeProductRepository fakeRepository;
  late MyProductsBloc bloc;

  final sampleProducts = [
    ProductEntity(
      id: 'p-1',
      name: 'Calculator',
      description: 'Scientific Calculator',
      price: 200.0,
      category: 'Electronics',
      university: 'UCT',
      imageUrls: const [],
      sellerId: 'user-1',
      status: 'active',
      createdAt: DateTime.now(),
    ),
    ProductEntity(
      id: 'p-2',
      name: 'Microbiology Book',
      description: 'Hardcover textbook',
      price: 450.0,
      category: 'Books',
      university: 'UCT',
      imageUrls: const [],
      sellerId: 'user-1',
      status: 'pending_payment',
      createdAt: DateTime.now(),
    ),
  ];

  setUp(() {
    fakeRepository = FakeProductRepository();
    bloc = MyProductsBloc(fakeRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('MyProductsBloc Unit Tests', () {

    test('initial state is MyProductsInitial', () {
      expect(bloc.state, isA<MyProductsInitial>());
    });

    test('emits [MyProductsLoading, MyProductsLoaded] on FetchUserProducts success', () async {
      fakeRepository.userProductsToReturn = sampleProducts;

      final expectedStates = [
        isA<MyProductsLoading>(),
        isA<MyProductsLoaded>().having((s) => s.products.length, 'products length', 2),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const FetchUserProducts('user-1'));
    });

    test('emits [MyProductsLoading, MyProductsError] on FetchUserProducts failure', () async {
      fakeRepository.shouldThrow = true;

      final expectedStates = [
        isA<MyProductsLoading>(),
        isA<MyProductsError>().having((s) => s.message, 'error message', contains('Database connection failed')),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const FetchUserProducts('user-1'));
    });

    test('UpdateProductPrice updates item price locally in state', () async {
      fakeRepository.userProductsToReturn = sampleProducts;
      bloc.add(const FetchUserProducts('user-1'));
      await bloc.stream.firstWhere((state) => state is MyProductsLoaded);

      bloc.add(const UpdateProductPrice('p-1', 250.0));

      final updatedState = await bloc.stream.firstWhere((state) => state is MyProductsLoaded) as MyProductsLoaded;
      final updatedItem = updatedState.products.firstWhere((p) => p.id == 'p-1');
      expect(updatedItem.price, 250.0);
    });

    test('DeleteProduct removes item locally from state', () async {
      fakeRepository.userProductsToReturn = sampleProducts;
      bloc.add(const FetchUserProducts('user-1'));
      await bloc.stream.firstWhere((state) => state is MyProductsLoaded);

      bloc.add(const DeleteProduct('p-2'));

      final updatedState = await bloc.stream.firstWhere((state) => state is MyProductsLoaded) as MyProductsLoaded;
      expect(updatedState.products.length, 1);
      expect(updatedState.products.any((p) => p.id == 'p-2'), isFalse);
    });

    test('ActivateMyProduct emits MyProductActivatedSuccess', () async {
      final expectedStates = [
        isA<MyProductActivatedSuccess>(),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const ActivateMyProduct('p-2'));
    });
  });
}
