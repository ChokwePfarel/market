import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/custom/Header.dart';
import '../../core/custom/product_card.dart';
import '../conversation/conversation_bloc.dart';
import '../conversation/conversation_event.dart';
import '../conversation/conversation_state.dart';
import '../product/bloc/product_bloc.dart';
import '../product/bloc/product_event.dart';
import '../product/bloc/product_state.dart';
import 'add_product_screen.dart';
import 'my_products_page.dart';
import 'search_page.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  String _selectedCategory = 'Electronics'; //Default

  final List<String> _categories = [
    'Electronics',
    'Books',
    'Kitchen',
    'Sports',
    'Room',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Trigger initial fetch only if data isnt already loaded.
    //...
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productBloc = context.read<ProductBloc>();
      final userState = context.read<UserBloc>().state;

      if (userState is UserLoaded) {
        if (productBloc.state is ProductInitial) {
          productBloc.add(
            FetchProducts(
              university: userState.user.university,
              category: _selectedCategory,
              isRefresh: true,
            ),
          );
        } else {}
        context.read<ConversationsBloc>().add(
          LoadConversations(userState.user.id),
        );
      } else {
        context.read<UserBloc>().add(const WatchCurrentUser());
      }
    });
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
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          ).then((_) {
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
          });
        },
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      'Offline',
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
                listenWhen: (previous, current) {
                  // Only re-fetch if university has changed or if we just logged in
                  if (previous is! UserLoaded && current is UserLoaded)
                    return true;
                  if (previous is UserLoaded && current is UserLoaded) {
                    return previous.user.university != current.user.university;
                  }
                  return false;
                },
                listener: (context, state) {
                  if (state is UserLoaded) {
                    debugPrint(
                      'HomeScreen: User loaded/updated. Syncing data...',
                    );

                    // 1. Fetch products
                    context.read<ProductBloc>().add(
                      FetchProducts(
                        university: state.user.university,
                        category: _selectedCategory,
                        isRefresh: true,
                      ),
                    );

                    // 2. Start persistent notification listener
                    context.read<ConversationsBloc>().add(
                      LoadConversations(state.user.id),
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
                      Header(),
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

                      BlocBuilder<ProductBloc, ProductState>(
                        builder: (context, state) {
                          if (state is ProductInitial ||
                              (state is ProductLoading &&
                                  state is! ProductLoaded)) {
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
                                    return ProductCard(product: product);
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

                          return _buildShimmerGrid();
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white),
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
