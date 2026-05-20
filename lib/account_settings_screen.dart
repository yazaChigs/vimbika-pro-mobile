import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'model/user.dart';
import 'app_constants/app_constants.dart'; // Import AppConstants

class AccountSettingsScreen extends StatefulWidget {
  @override
  _AccountSettingsScreenState createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  User? _currentUser;
  bool _isLoading = true;
  bool _isOnline = false; // Added for offline/online mode

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  String? _base64Image;

  @override
  void initState() {
    _loadUserData();
    super.initState();
  }

  Future<void> _loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _isOnline = !(prefs.getBool(AppConstants.keyIsOfflineMode) ?? false); // Determine mode
    print('_isOnline: $_isOnline');

    final String userKey = _isOnline ? AppConstants.keyOnlineUserData : AppConstants.keyOfflineUserData;
    final String? userData = prefs.getString(userKey);

    if (userData != null) {
      setState(() {
        _currentUser = User.fromJson(jsonDecode(userData));
        _firstNameController.text = _currentUser?.firstName ?? '';
        _lastNameController.text = _currentUser?.lastName ?? '';
        _phoneController.text = _currentUser?.phoneNumber ?? '';
        _base64Image = _currentUser?.profilePicture;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // Compress the image to save storage space
        maxWidth: 500,
        maxHeight: 500,
      );
      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();
        setState(() {
          _base64Image = base64Encode(imageBytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _updateUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedUser = User(
        id: _currentUser?.id,
        userName: _currentUser?.userName ?? '',
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phoneNumber: _phoneController.text,
        role: _currentUser?.role,
        branch: _currentUser?.branch,
        isActive: _currentUser?.isActive ?? true,
        pin: _currentUser?.pin,
        dateCreated: _currentUser?.dateCreated,
        userRoles: _currentUser?.userRoles,
        profilePicture: _base64Image,
      );

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String userKey = _isOnline ? AppConstants.keyOnlineUserData : AppConstants.keyOfflineUserData;
      await prefs.setString(userKey, jsonEncode(updatedUser.toJson()));
      
      // Update the all_users list as well, using the correct key for all users
      final String allUsersKey = _isOnline ? AppConstants.keyAllUsers : AppConstants.keyAllUsers; // Assuming same key for all users regardless of mode, or adjust if needed
      List<String> allUsers = prefs.getStringList(allUsersKey) ?? [];
      int index = allUsers.indexWhere((u) => User.fromJson(jsonDecode(u)).userName == updatedUser.userName);
      if (index != -1) {
        allUsers[index] = jsonEncode(updatedUser.toJson());
        await prefs.setStringList(allUsersKey, allUsers);
      }

      setState(() {
        _currentUser = updatedUser;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );
        // Return to the previous screen (SettingsScreen)
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: Text('Account Settings', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        iconTheme: IconThemeData(color: AppTheme.nearlyBlack),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.vimbikaBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildProfileHeader(),
                  const SizedBox(height: 32),
                  _buildTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.vimbikaBlue,
                      foregroundColor: AppTheme.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _updateUserData,
                    child: Text('Save Changes', style: AppTheme.title.copyWith(color: AppTheme.white)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.grey.withAlpha(25),
                  backgroundImage: _base64Image != null ? MemoryImage(base64Decode(_base64Image!)) : null,
                  child: _base64Image == null ? Icon(Icons.person, size: 50, color: AppTheme.grey) : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.vimbikaBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentUser?.userName ?? '',
            style: AppTheme.headline,
          ),
          Text(
            _currentUser?.role ?? 'User',
            style: AppTheme.subtitle.copyWith(color: AppTheme.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.subtitle.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(25),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }
}
