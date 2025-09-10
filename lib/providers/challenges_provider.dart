// lib/providers/challenges_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/firebase_users_service.dart';
import 'auth_provider.dart';

// Lắng nghe các lời mời game đã nhận
final gameChallengesProvider = StreamProvider<List<DocumentSnapshot>>((ref) {
  ref.watch(authStateChangesProvider);
  return FirebaseUsersService.instance.getGameChallengesStream().map((s) => s.docs);
});

// Lắng nghe một lời mời cụ thể (cho phòng chờ)
final singleChallengeProvider = StreamProvider.family<DocumentSnapshot, String>((ref, challengeId) {
  return FirebaseUsersService.instance.getChallengeStream(challengeId);
});