import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/snackbar.dart';
import '../user/user_bloc.dart';
import '../user/user_event.dart';
import '../user/user_state.dart';
import 'home_screen.dart';
import 'signup_page.dart'; // To reuse CustomDropdown if available or universities list

class CreateAccountProfilePage extends StatefulWidget {
  const CreateAccountProfilePage({super.key});

  @override
  State<CreateAccountProfilePage> createState() => _CreateAccountProfilePageState();
}

class _CreateAccountProfilePageState extends State<CreateAccountProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedSex = 'Male';
  final List<String> sexes = ['Male', 'Female'];
  String? _localImagePath;
  
  final List<String> universities = [
    "University of Cape Town",
    "Stellenbosch University",
    "University of Pretoria",
    "University of the Witwatersrand",
    "University of KwaZulu-Natal",
    "University of the Western Cape",
    "Rhodes University",
    "University of South Africa",
    "Nelson Mandela University",
    "North-West University",
    "Sefako Makgatho Health Sciences University",
    "Sol Plaatje University",
    "University of Fort Hare",
    "University of Johannesburg",
    "University of Limpopo",
    "University of Mpumalanga",
    "University of the Free State",
    "University of Venda",
    "Tshwane University of Technology",
    "Durban University of Technology",
    "Central University of Technology",
    "Cape Peninsula University of Technology",
    "Mangosuthu University of Technology",
    "Walter Sisulu University",
  ];
  late String _selectedUniversity = universities.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Take a Photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        final croppedFile = await _cropImage(pickedFile.path);
        if (croppedFile != null) {
          setState(() {
            _localImagePath = croppedFile.path;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        AppSnackBar.error(context, 'Failed to pick image');
      }
    }
  }

  Future<CroppedFile?> _cropImage(String path) async {
    return await ImageCropper().cropImage(
      sourcePath: path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Profile Picture',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Profile Picture',
          aspectRatioLockEnabled: true,
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<UserBloc>().add(
        CreateUser(
          name: _nameController.text.trim(),
          sex: _selectedSex,
          userType: 'Student',
          university: _selectedUniversity,
          isVerified: false,
          profileImageUrl: _localImagePath ?? '', 
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Setup Your Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: BlocListener<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserLoaded) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          } else if (state is UserError) {
            AppSnackBar.error(context, state.message);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _localImagePath != null
                              ? FileImage(File(_localImagePath!))
                              : null,
                          child: _localImagePath == null
                              ? const Icon(Icons.person, size: 60, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.black, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.black, width: 2),
                    ),

                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: _selectedSex,
                  decoration: InputDecoration(labelText: 'Gender',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.black, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  items: sexes
                      .map((sex) => DropdownMenuItem(
                    value: sex,
                    child: Text(sex),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSex = value!;
                    });
                  },
                ),

                const SizedBox(height: 10),

                CustomDropdown<String>(
                  labelText: 'University',
                  items: universities,
                  value: _selectedUniversity,
                  onChanged: (value) {
                    setState(() {
                      _selectedUniversity = value!;
                    });
                  },
                ),


                const SizedBox(height: 40),
                
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Start Shopping',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
