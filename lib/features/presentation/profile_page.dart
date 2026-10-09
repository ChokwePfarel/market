import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:market/core/utils/snackbar.dart';
import 'package:market/features/presentation/settings_page.dart';
import '../auth/auth_bloc.dart';
import '../auth/auth_state.dart';
import '../user/user_bloc.dart';
import '../user/user_event.dart';
import '../user/user_state.dart';
import 'full_image_page.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _universityController;
  String? _localImagePath;

  @override
  void initState() {
    super.initState();

    final userBloc = context.read<UserBloc>();
    final userState = userBloc.state;

    if (userState is UserLoaded) {
      _nameController = TextEditingController(text: userState.user.name);
      _universityController = TextEditingController(
        text: userState.user.university,
      );
    } else {
      _nameController = TextEditingController();
      _universityController = TextEditingController();

      // Auto-trigger load if state is initial
      final authState = context
          .read<AuthBloc>()
          .state;
      if (authState is Authenticated) {
        userBloc.add(LoadUserProfile(authState.user.id));
        userBloc.add(const WatchCurrentUser());
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
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
  }

  Future<CroppedFile?> _cropImage(String path) async {
    return await ImageCropper().cropImage(
      sourcePath: path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), //Square for avatar
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Profile Picture',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          activeControlsWidgetColor: Colors.black,
        ),
        IOSUiSettings(
          title: 'Crop Profile Picture',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
  }

  void _saveProfile() {
    context.read<UserBloc>().add(
      UpdateUserProfile(
        name: _nameController.text.trim(),

        university: _universityController.text.trim(),
        localImagePath: _localImagePath,
      ),
    );
    setState(() {
      _isEditing = false;
    });
  }

  Widget _buildProfileAvatar(String? profileUrl, String? localPath) {
    if (localPath != null) {
      return CircleAvatar(
        radius: 64,
        backgroundColor: Colors.grey.shade300,
        backgroundImage: FileImage(File(localPath.replaceFirst('file://', ''))),
      );
    }

    if (profileUrl == null || profileUrl.isEmpty || profileUrl.contains('com.example.market')) {
      return CircleAvatar(
        radius: 64,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, size: 64, color: Colors.grey[600]),
      );
    }

    return CachedNetworkImage(
      imageUrl: profileUrl,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: 64,
        backgroundColor: Colors.grey[300],
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: 64,
        backgroundColor: Colors.grey[200],
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: 64,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, size: 64, color: Colors.grey[600]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios),
          color: Colors.black,
        ),
        actions: [
          IconButton(onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          }, icon: Icon(Icons.settings,color: Colors.black,
          size: 30,)),

        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
         // debugPrint('ProfilePage: UserBloc state changed to $state');
          if (state is UserError) {

            AppSnackBar.error(context, 'No Network Connection');

          } else if (state is UserLoaded && !_isEditing) {
           /* debugPrint(
              'ProfilePage: Updating controllers with ${state.user.name}',
            );*/
            _nameController.text = state.user.name;
            _universityController.text = state.user.university;
          }
        },
        builder: (context, state) {
          //debugPrint('ProfilePage: Building with state $state');
          if (state is UserLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            );
          }

          if (state is UserLoaded) {
            final user = state.user;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isEditing ? _pickImage : null,
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            final imageToShow = _localImagePath ?? user.profileImageUrl;
                            if (imageToShow.isEmpty) return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullImagePage(
                                  imageUrl: imageToShow,
                                ),
                              ),
                            );
                          },
                          child: _buildProfileAvatar(user.profileImageUrl, _localImagePath),
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Editable name field
                  _buildEditableField('Full Name', _nameController, _isEditing),
                  const SizedBox(height: 16),

                  // Read  only university field and sex
                  _buildReadOnlyField('University', user.university),
                  const SizedBox(height: 16),


                  _buildReadOnlyField('Gender', user.sex),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (_isEditing) {
                        _saveProfile();
                      } else {
                        setState(() {
                          _isEditing = true;
                        });
                      }
                    },
                    child: Text(
                      _isEditing ? 'SAVE CHANGES' : 'EDIT PROFILE',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Profile details not available.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final authState = context.read<AuthBloc>().state;
                    if (authState is Authenticated) {
                      context.read<UserBloc>().add(
                        LoadUserProfile(authState.user.id),
                      );
                      context.read<UserBloc>().add(const WatchCurrentUser());
                    }
                  },
                  child: const Text(
                    'RELOAD PROFILE',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: Text(
                    'Go to Login',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

// Editable text field (for name only)..
  Widget _buildEditableField(
      String label,
      TextEditingController controller,
      bool isEditing,
      ) {
    return TextFormField(
      controller: controller,
      enabled: isEditing,
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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Colors.grey[400]!,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Colors.black,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: isEditing ? Colors.white : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

// Read Only field (for university and sex)
  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isNotEmpty ? value : 'Not specified',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }}

