import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;

  final Map<String, dynamic> placeholderData = {
    'demo-user-1': {
      'uid': 'demo-user-1',
      'email': 'alice@example.com',
      'displayName': 'Alice Smith',
      'photoURL': 'https://i.pravatar.cc/150?img=1',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    },
    'demo-user-2': {
      'uid': 'demo-user-2',
      'email': 'bob@example.com',
      'displayName': 'Bob Jones',
      'photoURL': 'https://i.pravatar.cc/150?img=2',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    },
  };

  print('Populating Firestore...');

  for (final entry in placeholderData.entries) {
    try {
      await firestore.collection('users').doc(entry.key).set(entry.value);
      print('Added user: ${entry.key}');
    } catch (e) {
      print('Failed to add ${entry.key}: $e');
    }
  }

  print('Data population complete!');
  // Exit cleanly
  // ignore: avoid_print
}
