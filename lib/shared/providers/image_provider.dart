import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerProvider {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<File?> pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1080,
    );

    return pickedFile != null ? File(pickedFile.path) : null;
  }

  Future<String?> uploadImage(File imageFile, {String? folder}) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      debugPrint('Upload blocked: No authenticated user.');
      return null;
    }

    try {
      final String fileName =
          '${folder ?? 'images'}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final Reference storageRef = _storage.ref().child(fileName);

      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('Firebase upload error: ${e.message}');
      return null;
    }
  }

  Future<void> saveImageUrl(String url, String userId) async {
    await _firestore.collection('user_images').add({
      'url': url,
      'userId': userId,
      'uploadedAt': FieldValue.serverTimestamp(),
    });
  }
}
