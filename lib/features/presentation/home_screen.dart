import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../conversation/conversation_bloc.dart';
import '../conversation/conversation_event.dart';
import '../conversation/conversation_state.dart';
import '../product/bloc/product_bloc.dart';
import '../product/bloc/product_event.dart';
import '../product/bloc/product_state.dart';
import '../product/presentation/add_product_screen.dart';
import '../product/presentation/my_products_page.dart';
import '../search/presentation/search_page.dart';
import '../user/user_event.dart';
import 'detailed_product_page.dart';
import 'inbox_page.dart';
import 'profile_page.dart';
import '../user/user_bloc.dart';
import '../user/user_state.dart';
import '../network/bloc/network_bloc.dart';
import '../network/bloc/network_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  String _selectedCategory = 'Electronics';
  final List<String> _categories = [
    'Electronics',
    'Books',
    'Kitchen',
    'Sports',
    'Room',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Trigger initial fetch if user is already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userState = context.read<UserBloc>().state;
      if (userState is UserLoaded) {
        context.read<ProductBloc>().add(
          FetchProducts(
            university: userState.user.university,
            category: _selectedCategory,
            isRefresh: true,
          ),
        );
        context.read<ConversationsBloc>().add(
          LoadConversations(userState.user.id),
        );

        debugPrint('HomeScreen: User loaded, starting initial fetch');
        debugPrint('User Id: ${userState.user.id}');
      } else {
        // Not loaded yet — BlocListener will handle it when UserLoaded arrives
        // but make sure the subscription is running
        context.read<UserBloc>().add(const WatchCurrentUser());
        debugPrint('HomeScreen: User not loaded yet');
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      final userState = context.read<UserBloc>().state;
      if (userState is UserLoaded) {
        context.read<ProductBloc>().add(
          FetchProducts(
            university: userState.user.university,
            category: _selectedCategory,
          ),
        );
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    final userState = context.read<UserBloc>().state;
    if (userState is UserLoaded) {
      context.read<ProductBloc>().add(
        FetchProducts(
          university: userState.user.university,
          category: _selectedCategory,
          isRefresh: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
        },
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Offline indicator - existing functionality preserved
            BlocBuilder<NetworkBloc, NetworkState>(
              builder: (context, state) {
                if (!state.isConnected) {
                  return Container(
                    width: double.infinity,
                    color: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: const Text(
                      'Offline Mode — Showing Cached Data',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),

            Expanded(
              child: BlocListener<UserBloc, UserState>(
                listener: (context, state) {
                  if (state is UserLoaded) {
                    context.read<ProductBloc>().add(
                      FetchProducts(
                        university: state.user.university,
                        category: _selectedCategory,
                        isRefresh: true,
                      ),
                    );
                  }
                },

                child: RefreshIndicator(
                  onRefresh: () async {
                    final userState = context.read<UserBloc>().state;
                    if (userState is UserLoaded) {
                      context.read<ProductBloc>().add(
                        FetchProducts(
                          university: userState.user.university,
                          category: _selectedCategory,
                          isRefresh: true,
                        ),
                      );
                    }
                  },
                  child: ListView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      // ------------------------------------------------
                      // STATIC HEADER / SEARCH / CATEGORIES
                      // ------------------------------------------------
                      _buildHeader(context),
                      const SizedBox(height: 24),
                      _buildSearchBar(context),
                      const SizedBox(height: 24),
                      _buildCategoryTabs(),
                      const SizedBox(height: 28),

                      Text(
                        _selectedCategory,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ------------------------------------------------
                      // DYNAMIC PRODUCT SECTION
                      // ------------------------------------------------
                      BlocBuilder<ProductBloc, ProductState>(
                        builder: (context, state) {
                          if (state is ProductInitial ||
                              (state is ProductLoading && state is! ProductLoaded)) {
                            return _buildShimmerGrid();
                          }

                          if (state is ProductError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 40),
                                child: Text('Error: ${state.message}'),
                              ),
                            );
                          }

                          if (state is ProductLoaded) {
                            if (state.products.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 40),
                                  child: Text(
                                    'No products found for your university.',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              );
                            }

                            return Column(
                              children: [
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: state.products.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 16,
                                        childAspectRatio: 0.68,
                                      ),
                                  itemBuilder: (context, index) {
                                    final product = state.products[index];
                                    return _buildProductCard(context, product);
                                  },
                                ),

                                if (!state.hasReachedMax)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                              ],
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(18),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Profile
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          },
          child: BlocBuilder<UserBloc, UserState>(
            builder: (context, state) {
              String? profileUrl;
              if (state is UserLoaded) {
                profileUrl = state.user.profileImageUrl;
              }

              final bool hasImage = profileUrl != null && profileUrl.isNotEmpty;
              ImageProvider? imageProvider;
              
              if (hasImage) {
                if (profileUrl!.startsWith('http')) {
                  imageProvider = NetworkImage(profileUrl);
                } else {
                  imageProvider = FileImage(File(profileUrl.replaceFirst('file://', '')));
                }
              }

              return CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFFF0E8F7),
                backgroundImage: imageProvider,
                child: !hasImage
                    ? const Icon(Icons.person, color: Colors.black87, size: 25)
                    : null,
              );
            },
          ),
        ),

        const Spacer(),

        // Notification
        BlocBuilder<ConversationsBloc, ConversationsState>(
          builder: (context, state) {
            int unreadCount = 0;

            if (state is ConversationsLoaded) {
              unreadCount = state.unreadCount;
            }

            return IconButton(
              onPressed: () {
                final userState = context.read<UserBloc>().state;

                if (userState is UserLoaded) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          InboxPage(currentUserId: userState.user.id),
                    ),
                  );
                }
              },
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF9F9F9),
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
              ),
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text(unreadCount.toString()),
                child: const Icon(
                  CupertinoIcons.bell, // outlined bell
                  size: 25,
                  color: Colors.black87,
                ),
              ),
            );
          },
        ),

        const SizedBox(width: 6),

        // Cart
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyProductsPage() ),
            );
          },
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF9F9F9),
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(12),
          ),
          icon: const Icon(
            CupertinoIcons.bag_fill,
            size: 25,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchPage()),
        );
      },
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFEDEDED)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: const [
            Icon(Icons.search, size: 25, color: Colors.grey),
            SizedBox(width: 12),
            Text(
              'Search...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () => _onCategorySelected(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, dynamic product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEAEAEA)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 7,
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF4F4F4),
                child: product.imageUrls.isNotEmpty
                    ? Image.network(
                        product.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),

            // Product information
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      'R ${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
