import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FireStoreProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<bool> createRecord(
    bool authRequired,
    BuildContext context, {
    required String collectionName,
    required String docID,
    required Map<String, dynamic> data,
    required String successMessage,
    required String failMessage,
  }) async {
    if (currentUser == null && authRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Need to Log in to perform this action"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return false;
    }

    await _firestore
        .collection(collectionName)
        .doc(docID)
        .set(data)
        .then(
          (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(successMessage),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
            return true;
          },
          onError: (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("$failMessage: $e"),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );

            return false;
          },
        );

    return false;
  }

  Future<List<T>> getRecords<T>(
    BuildContext context,
    T Function(Map<String, dynamic> data) fromMap, {
    required String collectionName,
    required String failMessage,
  }) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(collectionName)
        .get()
        .then(
          (_) {},
          onError: (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("$failMessage: $e"),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
            return false;
          },
        );

    return snapshot.docs.map((doc) => fromMap(doc.data())).toList();
  }

  Future<bool> updateRecord(
    bool authRequired,
    BuildContext context, {
    required String collectionName,
    required String docID,
    required Map<String, dynamic> data,
    required String successMessage,
    required String failMessage,
  }) async {
    if (currentUser == null && authRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Need to Log in to perform this action"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return false;
    }

    await _firestore
        .collection(collectionName)
        .doc(docID)
        .update(data)
        .then(
          (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(successMessage),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
            return true;
          },
          onError: (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("$failMessage: $e"),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
            return false;
          },
        );

    return false;
  }
}
