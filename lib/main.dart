import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:photalchemy/app/app.dart';
import 'package:photalchemy/app/app_controller.dart';
import 'package:photalchemy/core/storage/cloud_firestore_gateway.dart';
import 'package:photalchemy/features/auth/data/firebase_auth_repository.dart';
import 'package:photalchemy/features/auth/domain/profile_repository.dart';
import 'package:photalchemy/features/cards/data/firestore_card_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppController? controller;
  try {
    await Firebase.initializeApp();
    final authRepository = FirebaseAuthRepository();
    final firestoreGateway = CloudFirestoreGateway();
    controller = AppController(
      authRepository: authRepository,
      cardRepository: FirestoreCardRepository(
        gateway: firestoreGateway,
        authenticatedUidProvider: () => authRepository.currentUser?.id,
      ),
      profileRepository: FirestoreProfileRepository(
        gateway: firestoreGateway,
        authenticatedUidProvider: () => authRepository.currentUser?.id,
      ),
    );
  } catch (_) {
    // When running without platform google-services.json (e.g., unit/CI runs),
    // AppController defaults to deterministic rule-enforced in-memory storage.
    controller = null;
  }

  runApp(PhotalchemyApp(controller: controller));
}
