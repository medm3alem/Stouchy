import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

final profilePhotoProvider = StateNotifierProvider<ProfilePhotoNotifier, String?>((ref) {
  return ProfilePhotoNotifier();
});

class ProfilePhotoNotifier extends StateNotifier<String?> {
  ProfilePhotoNotifier() : super(null) {
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('local_profile_image');
  }

  Future<void> updatePhoto(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_profile_image', path);
    state = path;
  }

  Future<void> clearPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('local_profile_image');
    state = null;
  }
}
