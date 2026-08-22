import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/snackbar.dart';
import '../auth/auth_bloc.dart';
import '../auth/auth_event.dart';
import '../auth/auth_state.dart';

import '../user/user_bloc.dart';
import '../user/user_event.dart';
import '../user/user_state.dart';
import 'home_screen.dart';
import 'login_page.dart';
import 'verify_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final String _nameController = '';
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Mapping of universities to their expected email domains
  final Map<String, String> _universityDomains = {
    'University of the Western Cape (UWC)': '@myuwc.ac.za',
    'University of Cape Town (UCT)': '@myuct.ac.za',
    'Stellenbosch University': '@sun.ac.za',
    'University of the Witwatersrand': '@students.wits.ac.za',
    'University of Johannesburg': '@student.uj.ac.za',
    'University of Pretoria': '@tuks.co.za',
    'University of KwaZulu-Natal': '@stu.ukzn.ac.za',
    'Rhodes University': '@ruconnect.ru.ac.za',
  };


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignup() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        SignUpRequested(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            AppSnackBar.warning(context, 'If you are not redirected, try again later');
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            if (state is EmailVerificationRequired) {
              return const VerifyPage();
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [




                    TextFormField(
                      controller: _emailController,
                      decoration:  InputDecoration(
                        labelText: 'University Email',
                        hintText: 'student@university.ac.za',
                        prefixIcon: const Icon(Icons.mail),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.black, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || !val.contains('@')) {
                          return 'Invalid email';
                        }

                        final isValid = _universityDomains.values.any((domain) => val.endsWith(domain));
                        if (!isValid) {
                          return 'Please use your official student email';
                        }
                        return null; // valid
                      },
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(labelText: 'password',
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Colors.black, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Colors.black, width: 2),
                          ),),

                        validator: (value){
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          } else if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        }
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                        ),

                        onPressed: _onSignup,
                        child: const Text('Sign Up', style: TextStyle(fontSize: 18,
                        color: Colors.white,),
                      ),),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Text('Already have an account? ',
                            style: TextStyle(color: Colors.black)),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const LoginPage()),
                            );
                          },
                          child: const Text('Log In'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
class CustomDropdown<T> extends StatelessWidget {
  final String labelText;
  final List<T> items;
  final T value;
  final void Function(T?) onChanged;
  final String Function(T)? displayItem;
  final Color borderColor;

  const CustomDropdown({
    super.key,
    required this.labelText,
    required this.items,
    required this.value,
    required this.onChanged,
    this.displayItem,
    this.borderColor = const Color(0xFF000000), // blue900
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth),
          // 1. Wrap with a Theme to customize the dropdown menu's SHAPE
          child: Theme(
            data: Theme.of(context).copyWith(
              // Use DropdownMenuTheme to set the border radius via MenuStyle
              dropdownMenuTheme: DropdownMenuThemeData(
                menuStyle: MenuStyle(
                  // This applies the rounded corners to the floating menu box
                  shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            child: DropdownButtonFormField<T>(
              isExpanded: true,
              initialValue: value,
              // 2. Use dropdownColor to set the background color
              dropdownColor: Colors.white,
              // 3. Keep the elevation to make it look "floating"
              elevation: 8,
              decoration: InputDecoration(
                labelText: labelText,
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(20),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: borderColor, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: borderColor),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    displayItem != null ? displayItem!(item) : item.toString(),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }
}
