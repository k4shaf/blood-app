import 'package:app/core/enums/app_routes.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/core/theme/app_decorations.dart';
import 'package:app/pages/testing_profile.dart';
import 'package:app/services/auth_services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Sign up",
          style: TextStyle(color: Color(0xFF757575)),
        ),
      ),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    "Complete Profile",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Complete your details so we can ensure\n a secure community for DonorX",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF757575)),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  const SignUpForm(),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  _SignUpFormState createState() {
    return _SignUpFormState();
  }
}

class _SignUpFormState extends State<SignUpForm> {
  final DioClient _dioClient = GetIt.instance.get<DioClient>();
  final formKey = GlobalKey<FormState>();
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool isLocationLoading = false;
  String locationError = '';
  int _currentStep = 0;

  final fullNameController = TextEditingController();
  final phoneNoController = TextEditingController();
  final emailController = TextEditingController();
  final cnicController = TextEditingController();
  final cityController = TextEditingController();
  final coordinatesController = TextEditingController();
  final dateOfBirthController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        locationError =
            'Location services are disabled. Please enable the services';
      });
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          locationError = 'Location permissions are denied';
        });
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationError =
            'Location permissions are permanently denied, we cannot request permissions.';
      });
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLocationLoading = true;
      locationError = '';
    });

    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) {
      setState(() {
        isLocationLoading = false;
      });
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final coordinates = "${position.latitude},${position.longitude}";
      coordinatesController.text = coordinates;

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final city = place.locality ?? place.subAdministrativeArea ?? '';
        setState(() {
          cityController.text = city;
          isLocationLoading = false;
        });
      } else {
        setState(() {
          locationError = 'Could not determine your city';
          isLocationLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        locationError = 'Error getting location: $e';
        isLocationLoading = false;
      });
    }
  }

  Future<void> submitSignUp() async {
    if (!(_step3FormKey.currentState?.validate() ?? false)) {
      return;
    }

    final username = fullNameController.text;
    final phone = phoneNoController.text;
    final email = emailController.text;
    final cnic = cnicController.text;
    final city = cityController.text;
    final coordinates = coordinatesController.text;
    final dateOfBirth = dateOfBirthController.text;
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    setState(() {
      isLoading = true;
    });
    try {
      final response = await _dioClient.dio.post("/auth/register", data: {
        "username": username,
        "phone": phone,
        "email": email,
        "cnic": cnic,
        "city": city,
        "coordinates": coordinates,
        "dob": dateOfBirth,
        "password": password,
        "confirmPassword": confirmPassword,
      });
      print(response);
      if (response.statusCode == 201 && response.data["status"] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Account created successfully! Redirecting To Sign In!"),
            duration: Duration(seconds: 2),
          ),
        );
        if (mounted) {
          context.replace(AppRoutes.login.path);
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error: $e");
      }

      if (e is DioException) {
        print(e.response);
        if (e.response?.statusCode == 400) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.response?.data['message']),
              duration: const Duration(seconds: 10),
            ),
          );
        } else if (e.response?.statusCode == 500) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Server Error! Please try again later."),
              duration: Duration(seconds: 10),
            ),
          );
        }
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  void _nextStep() {
    bool isValid = false;

    switch (_currentStep) {
      case 0:
        isValid = _step1FormKey.currentState?.validate() ?? false;
        break;
      case 1:
        isValid = _step2FormKey.currentState?.validate() ?? false;
        break;
      default:
        isValid = true;
        break;
    }

    if (isValid && _currentStep < 2) {
      setState(() {
        _currentStep += 1;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepDot(0),
          _buildStepLine(0),
          _buildStepDot(1),
          _buildStepLine(1),
          _buildStepDot(2),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step) {
    bool isActive = _currentStep == step;
    bool isCompleted = _currentStep > step;

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isActive || isCompleted
            ? const Color(0xFFE0313B)
            : Colors.grey.shade300,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? const Color(0xFFE0313B) : Colors.transparent,
          width: 2,
        ),
      ),
      child: isCompleted
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : Center(
              child: Text(
                '${step + 1}',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
    );
  }

  Widget _buildStepLine(int step) {
    bool isCompleted = _currentStep > step;

    return Container(
      width: 50,
      height: 2,
      color: isCompleted ? const Color(0xFFE0313B) : Colors.grey.shade300,
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildPersonalDetailsStep();
      case 2:
        return _buildSecurityStep();
      default:
        return _buildBasicInfoStep();
    }
  }

  Widget _buildBasicInfoStep() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0, left: 8.0),
            child: Text(
              "Basic Information",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF303030),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextFormField(
              controller: fullNameController,
              onSaved: (username) {},
              onChanged: (username) {},
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                if (value.trim().length < 3) {
                  return 'Name must be at least 3 characters';
                }
                return null;
              },
              decoration: AppDecorations.textFieldDecoration(
                  hintText: "Enter your full name",
                  labelText: "Full Name",
                  icon: userIcon),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 12.0, bottom: 16.0),
            child: Text(
              "Make sure to enter name as on your CNIC",
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF757575),
              ),
            ),
          ),
          TextFormField(
            controller: phoneNoController,
            onSaved: (number) {},
            onChanged: (number) {},
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              if (!RegExp(r'^\d{10,12}$').hasMatch(value.trim())) {
                return 'Enter a valid phone number (10-12 digits)';
              }
              return null;
            },
            decoration: AppDecorations.textFieldDecoration(
                hintText: "Enter a phone number",
                labelText: "Phone Number",
                icon: phoneIcon),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 12.0, top: 8.0, bottom: 16.0),
            child: Text(
              "Enter a valid phone number to receive SMS notifications",
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF757575),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextFormField(
              controller: emailController,
              onSaved: (email) {},
              onChanged: (email) {},
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value.trim())) {
                  return 'Please enter a valid email';
                }
                return null;
              },
              decoration: AppDecorations.textFieldDecoration(
                  hintText: "Enter an email",
                  labelText: "Email",
                  icon: emailIcon),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 12.0, bottom: 16.0),
            child: Text(
              "We'll use this email for account verification",
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF757575),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsStep() {
    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0, left: 8.0),
            child: Text(
              "Personal Details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF303030),
              ),
            ),
          ),
          TextFormField(
            controller: cnicController,
            onSaved: (cnic) {},
            onChanged: (cnic) {},
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your CNIC number';
              }
              if (!RegExp(r'^\d{5}-\d{7}-\d{1}$').hasMatch(value.trim()) &&
                  !RegExp(r'^\d{13}$').hasMatch(value.trim())) {
                return 'Enter valid CNIC (13 digits or format: #####-#######-#)';
              }
              return null;
            },
            decoration: AppDecorations.textFieldDecoration(
                hintText: "Enter a valid CNIC",
                labelText: "CNIC number",
                icon: cardIcon),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 12.0, top: 8.0, bottom: 16.0),
            child: Text(
              "Format: 12345-1234567-1 or 1234512345671",
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF757575),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: cityController,
                  enabled: false,
                  readOnly: true,
                  onSaved: (city) {},
                  onChanged: (city) {},
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please use "Use Current Location" to set your city';
                    }
                    return null;
                  },
                  decoration: AppDecorations.textFieldDecoration(
                    hintText: "Use Current Location to set city",
                    labelText: "City",
                    icon: locationPointIcon,
                    suffixIcon: isLocationLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(
                            icon: const Icon(Icons.my_location,
                                color: Color(0xFFE0313B)),
                            onPressed: _getCurrentLocation,
                          ),
                  ),
                ),
                Visibility(
                  visible: false,
                  child: TextFormField(
                    controller: coordinatesController,
                  ),
                ),
                if (locationError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                    child: Text(
                      locationError,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                if (coordinatesController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                    child: Text(
                      "Location saved: ${coordinatesController.text}",
                      style: const TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.my_location, size: 18),
                    label: Text(
                      cityController.text.isEmpty
                          ? "Use Current Location"
                          : "Update Location",
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFFE0313B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextFormField(
            controller: dateOfBirthController,
            readOnly: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select your date of birth';
              }
              return null;
            },
            onTap: () async {
              // Calculate date 18 years ago from today
              final DateTime eighteenYearsAgo =
                  DateTime.now().subtract(const Duration(days: 365 * 18));

              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: eighteenYearsAgo,
                firstDate: DateTime(1900),
                lastDate: eighteenYearsAgo, // Set maximum date to 18 years ago
                selectableDayPredicate: (DateTime date) {
                  // Only allow dates on or before 18 years ago
                  return date.compareTo(eighteenYearsAgo) <= 0;
                },
              );
              if (pickedDate != null) {
                setState(() {
                  dateOfBirthController.text =
                      "${pickedDate.toLocal()}".split(' ')[0];
                });
              }
            },
            decoration: AppDecorations.textFieldDecoration(
              hintText: "Select your date of birth",
              labelText: "Date of Birth",
              icon: locationPointIcon,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 12.0, top: 8.0),
            child: Text(
              "You must be at least 18 years old to register as a donor",
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF757575),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityStep() {
    bool termsAccepted = false;

    return Form(
      key: _step3FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0, left: 8.0),
            child: Text(
              "Security",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF303030),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextFormField(
              controller: passwordController,
              obscureText: true,
              onSaved: (password) {},
              onChanged: (password) {},
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
              decoration: AppDecorations.textFieldDecoration(
                  hintText: "Create a password",
                  labelText: "Password",
                  icon: passwordIcon),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 12.0, bottom: 16.0),
            child: Text(
              "Use a strong password with letters, numbers and symbols",
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF757575),
              ),
            ),
          ),
          TextFormField(
            controller: confirmPasswordController,
            obscureText: true,
            onSaved: (confirmPassword) {},
            onChanged: (confirmPassword) {},
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            decoration: AppDecorations.textFieldDecoration(
                hintText: "Re-enter your password",
                labelText: "Confirm Password",
                icon: passwordIcon),
          ),

          const SizedBox(height: 32),

          // Terms and Conditions Checkbox
          FormField<bool>(
            initialValue: false,
            validator: (value) {
              if (value != true) {
                return 'You must accept the terms to continue';
              }
              return null;
            },
            builder: (FormFieldState<bool> field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: field.value,
                        activeColor: const Color(0xFFE0313B),
                        onChanged: (value) {
                          field.didChange(value);
                        },
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                color: Color(0xFF303030),
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: 'I agree to the ',
                                ),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: Color(0xFFE0313B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: ' and ',
                                ),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: Color(0xFFE0313B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 8.0),
                      child: Text(
                        field.errorText!,
                        style: const TextStyle(
                          color: Color(0xFFE0313B),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const Padding(
                    padding: EdgeInsets.only(left: 12.0, top: 8.0, right: 12.0),
                    child: Text(
                      "By accepting, you allow us to access your location to find nearby donors and donation requests. Your information will only be shared with verified users.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _currentStep > 0
              ? ElevatedButton(
                  onPressed: _previousStep,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFE0313B),
                    side: const BorderSide(color: Color(0xFFE0313B)),
                    minimumSize: const Size(120, 48),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  child: const Text("Previous"),
                )
              : const SizedBox(width: 120),
          ElevatedButton(
            onPressed: _currentStep < 2 ? _nextStep : submitSignUp,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFFE0313B),
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 48),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            child: isLoading && _currentStep == 2
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(_currentStep < 2 ? "Next" : "Submit"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          _buildStepIndicator(),
          _buildStepContent(),
          _buildNavigationButtons(),
        ],
      ),
    );
  }
}

// Icons
const userIcon =
    '''<svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M14.8331 14.6608C14.6271 14.9179 14.3055 15.0713 13.9729 15.0713H2.02715C1.69446 15.0713 1.37287 14.9179 1.16692 14.6608C0.972859 14.4191 0.906322 14.1271 0.978404 13.8382C1.77605 10.6749 4.66327 8.46512 8.0004 8.46512C11.3367 8.46512 14.2239 10.6749 15.0216 13.8382C15.0937 14.1271 15.0271 14.4191 14.8331 14.6608ZM4.62208 4.23295C4.62208 2.41197 6.13737 0.929467 8.0004 0.929467C9.86263 0.929467 11.3779 2.41197 11.3779 4.23295C11.3779 6.0547 9.86263 7.53565 8.0004 7.53565C6.13737 7.53565 4.62208 6.0547 4.62208 4.23295ZM15.9444 13.6159C15.2283 10.7748 13.0231 8.61461 10.2571 7.84315C11.4983 7.09803 12.3284 5.75882 12.3284 4.23295C12.3284 1.89921 10.387 0 8.0004 0C5.613 0 3.67155 1.89921 3.67155 4.23295C3.67155 5.75882 4.50168 7.09803 5.7429 7.84315C2.97688 8.61461 0.771665 10.7748 0.0556038 13.6159C-0.0861827 14.179 0.0460985 14.7692 0.419179 15.2332C0.808894 15.7212 1.39584 16 2.02715 16H13.9729C14.6042 16 15.1911 15.7212 15.5808 15.2332C15.9539 14.7692 16.0862 14.179 15.9444 13.6159Z" fill="#626262"/>
</svg>
''';

const phoneIcon =
    '''<svg width="11" height="18" viewBox="0 0 11 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M6.33333 15.0893C6.33333 15.5588 5.96 15.9384 5.5 15.9384C5.04 15.9384 4.66667 15.5588 4.66667 15.0893C4.66667 14.6197 5.04 14.2402 5.5 14.2402C5.96 14.2402 6.33333 14.6197 6.33333 15.0893ZM6.83333 2.63135C6.83333 2.91325 6.61 3.14081 6.33333 3.14081H4.66667C4.39 3.14081 4.16667 2.91325 4.16667 2.63135C4.16667 2.34945 4.39 2.12274 4.66667 2.12274H6.33333C6.61 2.12274 6.83333 2.34945 6.83333 2.63135ZM10 15.7923C10 16.4479 9.47667 16.9819 8.83333 16.9819H2.16667C1.52333 16.9819 1 16.4479 1 15.7923V2.2068C1 1.55215 1.52333 1.01807 2.16667 1.01807H8.83333C9.47667 1.01807 10 1.55215 10 2.2068V15.7923ZM8.83333 0H2.16667C0.971667 0 0 0.990047 0 2.2068V15.7923C0 17.01 0.971667 18 2.16667 18H8.83333C10.0283 18 11 17.01 11 15.7923V2.2068C11 0.990047 10.0283 0 8.83333 0Z" fill="#626262"/>
</svg>''';

const locationPointIcon =
    '''<svg width="15" height="18" viewBox="0 0 15 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M7.5 9.3384C6.38263 9.3384 5.47303 8.42383 5.47303 7.30037C5.47303 6.17691 6.38263 5.26235 7.5 5.26235C8.61737 5.26235 9.52697 6.17691 9.52697 7.30037C9.52697 8.42383 8.61737 9.3384 7.5 9.3384ZM7.5 4.24334C5.82437 4.24334 4.45955 5.61476 4.45955 7.30037C4.45955 8.98599 5.82437 10.3574 7.5 10.3574C9.17563 10.3574 10.5405 8.98599 10.5405 7.30037C10.5405 5.61476 9.17563 4.24334 7.5 4.24334ZM12.0894 12.1551L7.5 16.7695L2.9106 12.1551C0.380268 9.61098 0.380268 5.47125 2.9106 2.92711C4.17577 1.6542 5.83704 1.01816 7.5 1.01816C9.16212 1.01816 10.8242 1.65505 12.0894 2.92711C14.6197 5.47125 14.6197 9.61098 12.0894 12.1551ZM12.8064 2.20616C9.88 -0.735387 5.12 -0.735387 2.19356 2.20616C-0.731187 5.14771 -0.731187 9.93452 2.19356 12.8761L7.1419 17.8505C7.24072 17.9507 7.37078 18 7.5 18C7.62922 18 7.75928 17.9507 7.8581 17.8505L12.8064 12.8761C15.7312 9.93452 15.7312 5.14771 12.8064 2.20616Z" fill="#626262"/>
</svg>''';

const emailIcon =
    '''<svg width="10" height="14" viewBox="0 0 18 14" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M1.5 0H16.5C17.33 0 18 0.67 18 1.5V12.5C18 13.33 17.33 14 16.5 14H1.5C0.67 14 0 13.33 0 12.5V1.5C0 0.67 0.67 0 1.5 0ZM16.5 2L9 6.75L1.5 2V12.5H16.5V2ZM1.5 1.5L9 6L16.5 1.5H1.5Z" fill="#626262"/>
</svg>''';

const cardIcon =
    '''<svg width="10" height="14" viewBox="0 0 18 14" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M1.5 0H16.5C17.33 0 18 0.67 18 1.5V12.5C18 13.33 17.33 14 16.5 14H1.5C0.67 14 0 13.33 0 12.5V1.5C0 0.67 0.67 0 1.5 0ZM16.5 2H1.5V4H16.5V2ZM1.5 6V12.5H16.5V6H1.5ZM3 8H5.5V10H3V8ZM6.5 8H9V10H6.5V8Z" fill="#626262"/>
</svg>''';

const passwordIcon =
    '''<svg width="10" height="14" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M9 0C6.24 0 4 2.24 4 5V7H3C1.89 7 1 7.89 1 9V16C1 17.11 1.89 18 3 18H15C16.11 18 17 17.11 17 16V9C17 7.89 16.11 7 15 7H14V5C14 2.24 11.76 0 9 0ZM6 5C6 3.34 7.34 2 9 2C10.66 2 12 3.34 12 5V7H6V5ZM3 9H15V16H3V9ZM9 10C8.45 10 8 10.45 8 11V13C8 13.55 8.45 14 9 14C9.55 14 10 13.55 10 13V11C10 10.45 9.55 10 9 10Z" fill="#626262"/>
</svg>''';
