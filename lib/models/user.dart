import 'package:flutter/foundation.dart';

/// User Model
class User {
  final String id;
  final String name;

  /// Unique learner code (login identifier when email is not used).
  final String? code;
  final String email;
  final String phone;
  final String? categoryId;
  final String? categoryName;
  final String? subcategoryId;
  final String? subcategoryName;
  final String? avatar;
  final String? avatarThumbnail;
  final String role;
  final bool isVerified;
  final String createdAt;
  final String? studentType; // "online" or "offline"

  User({
    required this.id,
    required this.name,
    this.code,
    required this.email,
    required this.phone,
    this.categoryId,
    this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
    this.avatar,
    this.avatarThumbnail,
    required this.role,
    required this.isVerified,
    required this.createdAt,
    this.studentType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print('👤 Parsing User from JSON...');
      print('  json keys: ${json.keys.toList()}');
      print('  id: ${json['id']}');
      print('  email: ${json['email']}');
      print('  name: ${json['name']}');
      print('  status: ${json['status']}');
    }

    return User(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['nameAr'] as String? ?? '',
      code: json['code'] as String? ?? json['student_code'] as String?,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      categoryId: json['category_id'] as String? ??
          (json['category'] is Map<String, dynamic>
              ? (json['category'] as Map<String, dynamic>)['id'] as String?
              : null),
      categoryName: json['category_name'] as String? ??
          (json['category'] is Map<String, dynamic>
              ? (json['category'] as Map<String, dynamic>)['name'] as String?
              : null),
      subcategoryId: json['subcategory_id'] as String? ??
          (json['subcategory'] is Map<String, dynamic>
              ? (json['subcategory'] as Map<String, dynamic>)['id'] as String?
              : null),
      subcategoryName: json['subcategory_name'] as String? ??
          (json['subcategory'] is Map<String, dynamic>
              ? (json['subcategory'] as Map<String, dynamic>)['name'] as String?
              : null),
      avatar: json['avatar'] as String?,
      avatarThumbnail: json['avatar_thumbnail'] as String?,
      role: json['role'] as String? ?? 'student',
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
      studentType:
          json['studentType'] as String? ?? json['student_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (code != null) 'code': code,
      'email': email,
      'phone': phone,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryName != null) 'category_name': categoryName,
      if (subcategoryId != null) 'subcategory_id': subcategoryId,
      if (subcategoryName != null) 'subcategory_name': subcategoryName,
      'avatar': avatar,
      'avatar_thumbnail': avatarThumbnail,
      'role': role,
      'is_verified': isVerified,
      'created_at': createdAt,
      'studentType': studentType,
    };
  }
}
