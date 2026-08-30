import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../../images/bloc/images_bloc.dart';
import '../../images/bloc/images_event.dart';
import '../../images/bloc/images_state.dart';
import '../../user/user_bloc.dart';
import '../../user/user_state.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/repositories/payment_repository.dart';
import 'package:get_it/get_it.dart';


class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = 'Electronics';
  final List<String> _categories = ['Electronics', 'Books', 'Kitchen', 'Sports', 'Room', 'Other'];
  final List<File> _images = [];
  final List<String> _uploadedUrls = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_images.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 2 images allowed'),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one image'),
            backgroundColor: Colors.black,
          ),
        );
        return;
      }

      final userState = context.read<UserBloc>().state;
      if (userState is UserLoaded) {
        setState(() => _isSubmitting = true);
        _uploadedUrls.clear();
        _uploadNextImage(userState.user.id, 0);
      }
    }
  }

  void _uploadNextImage(String userId, int index) {
    if (index < _images.length) {
      context.read<ImagesBloc>().add(
        UploadProductImage(
          userId: userId,
          image: _images[index],
        ),
      );
    } else {
      _createProduct();
    }
  }

  void _createProduct() {
    final userState = context.read<UserBloc>().state;
    if (userState is UserLoaded) {
      context.read<ProductBloc>().add(
        AddProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          category: _selectedCategory,
          university: userState.user.university,
          imageUrls: _uploadedUrls,
          sellerId: userState.user.id,
        ),
      );
    }
  }

  Future<void> _handlePayment(String productId) async {
    setState(() => _isSubmitting = true);
    try {
      final success = await GetIt.I<PaymentRepository>().purchaseListingFee();
      if (success) {
        if (mounted) {
          context.read<ProductBloc>().add(ActivateProductEvent(productId));
        }
      } else {
        setState(() => _isSubmitting = false);
        if (mounted) {
          // Changed to show more detail for debugging on the phone
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment failed. Check your dashboard configuration or Entitlement ID.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ImagesBloc, ImagesState>(
          listener: (context, state) {
            if (state is ImageOperationSuccess && state.image != null) {
              debugPrint('AddProductScreen: Image uploaded. URL: ${state.image!.url}');
              _uploadedUrls.add(state.image!.url);
              final userState = context.read<UserBloc>().state;
              if (userState is UserLoaded) {
                _uploadNextImage(userState.user.id, _uploadedUrls.length);
              }
            } else if (state is ImagesError) {
              setState(() => _isSubmitting = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Image upload failed: ${state.message}'),
                  backgroundColor: Colors.black,
                ),
              );
            }
          },
        ),
        BlocListener<ProductBloc, ProductState>(
          listener: (context, state) {
            if (state is ProductAddedSuccess) {
              setState(() => _isSubmitting = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product listed successfully!'),
                  backgroundColor: Colors.black,
                ),
              );
              Navigator.pop(context);
            } else if (state is PaymentRequired) {
              setState(() => _isSubmitting = false);
              _showPaymentDialog(state.productId);
            } else if (state is ProductError) {
              setState(() => _isSubmitting = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.black,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'List a Product',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, productState) {
            return BlocBuilder<ImagesBloc, ImagesState>(
              builder: (context, imageState) {
                final isLoading = _isSubmitting ||
                    productState is ProductLoading ||
                    imageState is ImagesLoading;

                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        // Image Picker Section
                        _buildImageSection(isLoading),
                        const SizedBox(height: 24),

                        // Product Name
                        _buildTextField(
                          controller: _nameController,
                          label: 'Product Name',
                          hint: 'Enter product name',
                          enabled: !isLoading,
                          validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter a product name' : null,
                        ),
                        const SizedBox(height: 16),

                        // Description
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          hint: 'Describe your product',
                          enabled: !isLoading,
                          maxLines: 4,
                          validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter a description' : null,
                        ),
                        const SizedBox(height: 16),

                        // Price
                        _buildTextField(
                          controller: _priceController,
                          label: 'Price',
                          hint: '0.00',
                          enabled: !isLoading,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          prefixText: 'R ',
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please enter a price';
                            }
                            if (double.tryParse(value!) == null) {
                              return 'Please enter a valid price';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Category Dropdown
                        _buildCategoryDropdown(isLoading),
                        const SizedBox(height: 32),

                        // Submit Button
                        _buildSubmitButton(isLoading),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageSection(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Product Photos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Max 2',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length + (_images.length < 2 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _images.length) {
                return _buildAddImageButton(isLoading);
              }
              return _buildImageCard(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _pickImage,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: Colors.grey[500],
            ),
            const SizedBox(height: 4),
            Text(
              'Add Photo',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(int index) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _images[index],
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool enabled,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
        ),
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey[400]!,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.black,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.black,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.black,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildCategoryDropdown(bool isLoading) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      items: _categories.map((c) {
        return DropdownMenuItem(
          value: c,
          child: Text(
            c,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
            ),
          ),
        );
      }).toList(),
      onChanged: isLoading ? null : (val) => setState(() => _selectedCategory = val!),
      decoration: InputDecoration(
        labelText: 'Category',
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey[400]!,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.black,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: isLoading ? Colors.grey[50] : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      dropdownColor: Colors.white,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 15,
      ),
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: Colors.grey[600],
      ),
      isExpanded: true,
    );
  }

  Widget _buildSubmitButton(bool isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : _onSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        disabledBackgroundColor: Colors.grey[300],
      ),
      child: isLoading
          ? const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : const Text(
        'LIST PRODUCT',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  void _showPaymentDialog(String productId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            const Icon(Icons.stars_rounded, size: 64, color: Colors.amber),
            const SizedBox(height: 24),
            const Text(
              'Activate Your Listing',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Unlock your second listing for just R20 and start reaching buyers at your university today.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
            const Spacer(),
            // Paywall Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Standard Listing',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'One-time fee',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'R20',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handlePayment(productId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'PAY NOW',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(
                'MAYBE LATER',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}