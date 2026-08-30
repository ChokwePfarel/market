import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/repositories/payment_repository.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../../user/user_bloc.dart';
import '../../user/user_state.dart';

class MyProductsPage extends StatefulWidget {
  const MyProductsPage({super.key});

  @override
  State<MyProductsPage> createState() => _MyProductsPageState();
}

class _MyProductsPageState extends State<MyProductsPage> {
  String? _processingProductId;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    final userState = context.read<UserBloc>().state;
    if (userState is UserLoaded) {
      context.read<ProductBloc>().add(FetchUserProducts(userState.user.id));
    }
  }

  Future<void> _handleRetryPayment(String productId) async {
    setState(() => _processingProductId = productId);
    try {
      final success = await GetIt.I<PaymentRepository>().purchaseListingFee();
      if (success) {
        if (mounted) {
          context.read<ProductBloc>().add(ActivateProductEvent(productId));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment successful! Activating...'), backgroundColor: Colors.green),
          );
        }
      } else {
        setState(() => _processingProductId = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment failed or was cancelled.')),
          );
        }
      }
    } catch (e) {
      setState(() => _processingProductId = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _editPrice(String productId, double currentPrice) {
    final controller = TextEditingController(text: currentPrice.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Edit Price',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current price: R ${currentPrice.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'New Price',
                labelStyle: TextStyle(color: Colors.grey[600]),
                prefixText: 'R ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(80, 40),
            ),
            onPressed: () {
              final newPrice = double.tryParse(controller.text.replaceAll(',', '.'));
              if (newPrice != null && newPrice > 0) {
                context.read<ProductBloc>().add(UpdateProductPrice(productId, newPrice));
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid price'),
                    backgroundColor: Colors.black,
                  ),
                );
              }
            },
            child: const Text(
              'SAVE',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _confirmDelete(String productId, String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Product',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "$productName"?',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(80, 40),
            ),
            onPressed: () {
              context.read<ProductBloc>().add(DeleteProduct(productId));
              Navigator.pop(context);
            },
            child: const Text(
              'DELETE',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Listings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadProducts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocListener<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductAddedSuccess && _processingProductId != null) {
            setState(() => _processingProductId = null);
            _loadProducts(); // Refresh list to show active status
          }
        },
        child: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is ProductLoading && _processingProductId == null) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              );
            }
            // ... rest of the builder

          if (state is UserProductsLoaded) {
            if (state.products.isEmpty) {
              return _EmptyState(
                onRefresh: _loadProducts,
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _loadProducts();
              },
              color: Colors.black,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.products.length,
                itemBuilder: (context, index) {
                  final product = state.products[index];
                  final isProcessingThis = _processingProductId == product.id;

                  return Stack(
                    children: [
                      _ProductCard(
                        product: product,
                        onEdit: () => _editPrice(product.id, product.price),
                        onDelete: () => _confirmDelete(product.id, product.name),
                        onPay: () => _handleRetryPayment(product.id),
                      ),
                      if (isProcessingThis)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(child: CircularProgressIndicator(color: Colors.black)),
                          ),
                        ),
                    ],
                  );
                },
              ),
            );
          }

          if (state is ProductError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load listings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(200, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _loadProducts,
                      child: const Text(
                        'RETRY',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    ));
  }
}

// Empty state widget
class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'No Active Listings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t listed any products yet.\nCreate your first listing today!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onRefresh,
              child: const Text(
                'REFRESH',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Product card widget
class _ProductCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPay;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = product.status == 'active';
    final isPending = product.status == 'pending_payment';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrls.isNotEmpty
                    ? Image.network(
                  product.imageUrls.first,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[400],
                      size: 30,
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.black,
                          ),
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                )
                    : Icon(Icons.image, color: Colors.grey[400], size: 30),
              ),
            ),
            title: Text(
              product.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'R ${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.grey[200] : (isPending ? Colors.amber[100] : Colors.grey[300]),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.status.toUpperCase(),
                    style: TextStyle(
                      color: isActive ? Colors.black : (isPending ? Colors.amber[900] : Colors.grey[700]),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPending)
                  IconButton(
                    icon: Icon(Icons.payment_rounded, color: Colors.amber[900]),
                    onPressed: onPay,
                    tooltip: 'Pay to activate',
                  ),
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: Colors.grey[700]),
                  onPressed: onEdit,
                  tooltip: 'Edit price',
                  splashRadius: 20,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.grey[700]),
                  onPressed: onDelete,
                  tooltip: 'Delete listing',
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          if (product.status != 'active')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isPending ? Colors.amber[50] : Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isPending ? Icons.warning_amber_rounded : Icons.info_outline,
                    size: 16,
                    color: isPending ? Colors.amber[900] : Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isPending
                        ? 'Listing is hidden. Pay R20 to activate.'
                        : 'This listing is ${product.status} and not visible to buyers',
                      style: TextStyle(
                        fontSize: 12,
                        color: isPending ? Colors.amber[900] : Colors.grey[600],
                        fontWeight: isPending ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isPending)
                    TextButton(
                      onPressed: onPay,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.amber[900],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('ACTIVATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}