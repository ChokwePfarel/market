import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product_entity.dart';
import '../otheruser/otheruser_bloc.dart';
import '../otheruser/otheruser_event.dart';
import '../otheruser/otheruser_state.dart';
import '../product/bloc/other_user_products_bloc.dart';
import 'detailed_product_page.dart';

class OtherUserProducts extends StatefulWidget {
  final String otherUserId;

  const OtherUserProducts({super.key, required this.otherUserId});

  @override
  State<OtherUserProducts> createState() => _OtherUserProductsState();
}

class _OtherUserProductsState extends State<OtherUserProducts> {
  @override
  void initState() {
    super.initState();
    // Fetch user details and their products
    context.read<OtherUserBloc>().add(FetchOtherUserRequested(widget.otherUserId));
    context.read<OtherUserProductsBloc>().add(FetchOtherUserProducts(widget.otherUserId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: BlocBuilder<OtherUserBloc, OtherUserState>(
          builder: (context, state) {
            if (state is OtherUserLoaded) {
              return Text(
                "${state.user.name}'s Listings",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              );
            }
            return const Text(
              "User Listings",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            );
          },
        ),
      ),
      body: BlocBuilder<OtherUserProductsBloc, OtherUserProductsState>(
        builder: (context, state) {
          if (state is OtherUserProductsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          if (state is OtherUserProductsLoaded) {
            if (state.products.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.products.length,
              itemBuilder: (context, index) {
                final product = state.products[index];
                return _ProductListItem(product: product);
              },
            );
          }

          if (state is OtherUserProductsError) {
            return Center(child: Text(state.message));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No active listings found.",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final ProductEntity product;

  const _ProductListItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 64,
            height: 64,
            color: Colors.grey[50],
            child: product.imageUrls.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: product.imageUrls.first,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.image),
                  )
                : const Icon(Icons.image),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            "R ${product.price.toStringAsFixed(2)}",
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(product: product),
            ),
          );
        },
      ),
    );
  }
}
