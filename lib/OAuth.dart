import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OAuthScreen extends StatefulWidget {
  const OAuthScreen({super.key});

  @override
  State<OAuthScreen> createState() => _OAuthScreenState();
}

class _OAuthScreenState extends State<OAuthScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  // Text controllers
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController birthController = TextEditingController();
  TextEditingController genderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadSavedData(); // Load saved image & text when screen opens
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    birthController.dispose();
    genderController.dispose();
    super.dispose();
  }

  // Load saved data (image + text)
  Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load image
    String? imagePath = prefs.getString("profileImage");
    if (imagePath != null) {
      setState(() {
        _image = File(imagePath);
      });
    }

    // Load text fields
    setState(() {
      firstNameController.text = prefs.getString("firstName") ?? "";
      lastNameController.text = prefs.getString("lastName") ?? "";
      usernameController.text = prefs.getString("username") ?? "";
      emailController.text = prefs.getString("email") ?? "";
      phoneController.text = prefs.getString("phone") ?? "";
      birthController.text = prefs.getString("birth") ?? "";
      genderController.text = prefs.getString("gender") ?? "";
    });
  }

  // Pick image from camera or gallery
  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("profileImage", pickedFile.path);

      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }
  Future<void> removeImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("profileImage");

    setState(() {
      _image = null;
    });
  }

  // Show bottom sheet for camera/gallery
  void showImageSource() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera"),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Remove Photo"),
                onTap: () {
                  Navigator.pop(context);
                  removeImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Save text fields
  Future<void> saveProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("firstName", firstNameController.text);
    await prefs.setString("lastName", lastNameController.text);
    await prefs.setString("username", usernameController.text);
    await prefs.setString("email", emailController.text);
    await prefs.setString("phone", phoneController.text);
    await prefs.setString("birth", birthController.text);
    await prefs.setString("gender", genderController.text);
  }

  // Reusable TextField widget
  Widget buildTextField(String label, String hint,
      {TextEditingController? controller, bool isDropdown = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: isDropdown ? const Icon(Icons.arrow_drop_down) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF667eea),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Profile Image
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: showImageSource,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _image != null ? FileImage(_image!) : null,
                        child: _image == null
                            ? const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey,
                        )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 20),

                /// Title
                const Text(
                  "Edit Profile",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                /// Fields
                buildTextField("First Name", "",
                    controller: firstNameController),
                buildTextField("Last Name", "", controller: lastNameController),
                buildTextField("Username", "", controller: usernameController),
                buildTextField("Email", "", controller: emailController),

                /// Phone Row
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      prefixText: "+92  ",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                buildTextField("Birth", "",
                    controller: birthController, isDropdown: true),
                buildTextField("Gender", "",
                    controller: genderController, isDropdown: true),

                const SizedBox(height: 20),

                /// Save Button
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text("Confirm Save"),
                        content: const Text("Are you sure you want to save changes?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(dialogContext); // Close dialog
                              await saveProfileData(); // Save text fields
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Profile saved successfully!"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            },
                            child: const Text("OK"),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Save Changes"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
