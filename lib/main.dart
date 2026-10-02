import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await ServiceLocator.instance.initialize(
    firestore: FirebaseFirestore.instance,
  );

  runApp(const QswApp());

  unawaited(_syncPendingOperations());
}

Future<void> _syncPendingOperations() async {
  try {
    await ServiceLocator.instance.syncEngine.syncPendingOperations();
  } catch (_) {
    // Startup sync must not prevent the application from running.
  }
}
