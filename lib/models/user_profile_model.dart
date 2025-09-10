// lib/models/user_profile_model.dart

import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String photoURL;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoURL,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Người dùng mới',
      email: map['email'] as String? ?? '',
      photoURL: map['photoURL'] as String? ?? '',
    );
  }
}