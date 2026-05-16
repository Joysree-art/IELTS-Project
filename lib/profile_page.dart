import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  String? avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        _showMessage("User not logged in");
        setState(() => isLoading = false);
        return;
      }

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        await supabase.from('profiles').insert({
          'id': user.id,
          'email': user.email,
          'full_name': user.userMetadata?['full_name'] ?? '',
          'phone': user.userMetadata?['phone'] ?? '',
          'avatar_url': null,
        });

        nameController.text = user.userMetadata?['full_name'] ?? '';
        phoneController.text = user.userMetadata?['phone'] ?? '';
        emailController.text = user.email ?? '';
        avatarUrl = null;
      } else {
        nameController.text =
            data['full_name'] ?? user.userMetadata?['full_name'] ?? '';
        phoneController.text =
            data['phone'] ?? user.userMetadata?['phone'] ?? '';
        emailController.text = data['email'] ?? user.email ?? '';
        avatarUrl = data['avatar_url'];
      }
    } catch (e) {
      _showMessage("Profile load failed: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> _saveProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => isSaving = true);

    try {
      await supabase.from('profiles').upsert({
        'id': user.id,
        'full_name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'avatar_url': avatarUrl,
      });

      _showMessage("Profile updated successfully");
    } catch (e) {
      _showMessage("Update failed: $e");
    }

    setState(() => isSaving = false);
  }

  Future<void> _pickAndUploadImage() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (image == null) return;

      final fileExt = image.path.split('.').last;
      final filePath = '${user.id}/profile.$fileExt';

      if (kIsWeb) {
        final Uint8List bytes = await image.readAsBytes();

        await supabase.storage.from('profile-pictures').uploadBinary(
              filePath,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );
      } else {
        final file = File(image.path);

        await supabase.storage.from('profile-pictures').upload(
              filePath,
              file,
              fileOptions: const FileOptions(upsert: true),
            );
      }

      final publicUrl =
          supabase.storage.from('profile-pictures').getPublicUrl(filePath);

      setState(() {
        avatarUrl = publicUrl;
      });

      await _saveProfile();
      _showMessage("Profile picture updated");
    } catch (e) {
      _showMessage("Image upload failed: $e");
    }
  }

  Future<void> _deleteProfilePicture() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('profiles').update({
        'avatar_url': null,
      }).eq('id', user.id);

      setState(() {
        avatarUrl = null;
      });

      _showMessage("Profile picture deleted");
    } catch (e) {
      _showMessage("Delete failed: $e");
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();

    if (!mounted) return;

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _inputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF111827),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF6B7280)),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFFE60046),
            size: 20,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFFCCD8), width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8FA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE60046)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Center(
                child: Container(
                  width: screenWidth > 700 ? 430 : screenWidth * 0.55,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE60046),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE60046)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE60046).withOpacity(0.22),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8FA),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFFFCCD8)),
                        ),
                        child: const Text(
                          "Keep your IELTSync profile updated to track your IELTS practice progress, saved scores, and personal learning history accurately.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFB42350),
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 58,
                            backgroundColor: Colors.white,
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl!)
                                : null,
                            child: avatarUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 65,
                                    color: Color(0xFFE60046),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: InkWell(
                              onTap: _pickAndUploadImage,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE60046),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 120,
                            child: TextButton.icon(
                              onPressed: _pickAndUploadImage,
                              icon: const Icon(
                                Icons.upload,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "Update",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 22,
                            color: Colors.white54,
                          ),
                          SizedBox(
                            width: 110,
                            child: TextButton.icon(
                              onPressed: avatarUrl == null
                                  ? null
                                  : _deleteProfilePicture,
                              icon: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: avatarUrl == null
                                    ? Colors.white54
                                    : Colors.white,
                              ),
                              label: Text(
                                "Delete",
                                style: TextStyle(
                                  color: avatarUrl == null
                                      ? Colors.white54
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      _inputField(
                        label: "Full Name",
                        icon: Icons.person_outline,
                        controller: nameController,
                      ),

                      _inputField(
                        label: "Email",
                        icon: Icons.email_outlined,
                        controller: emailController,
                        readOnly: true,
                      ),

                      _inputField(
                        label: "Phone",
                        icon: Icons.phone_outlined,
                        controller: phoneController,
                      ),

                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: isSaving ? null : _saveProfile,
                          icon: const Icon(
                            Icons.save_outlined,
                            color: Color(0xFFE60046),
                            size: 20,
                          ),
                          label: isSaving
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFE60046),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Save Profile",
                                  style: TextStyle(
                                    color: Color(0xFFE60046),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFE60046),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(
                            Icons.logout,
                            size: 20,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Logout",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white,
                              width: 1.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
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