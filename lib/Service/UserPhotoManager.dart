import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';

import '../Api/ApiRequest.dart';

class UserPhotoManager {
  static final UserPhotoManager _singleton = UserPhotoManager._internal();
  Map<int, ImageProvider> _cache = {};

  factory UserPhotoManager() {
    return _singleton;
  }

  UserPhotoManager._internal();

  Future<ImageProvider> getUserPhoto(int userId) async {
    if (!_cache.containsKey(userId)) {
      try {
        final Dio _dio = Dio();
        _dio.options.responseType = ResponseType.bytes;
        var response = await _dio.get('$api/Users/user-photos/$userId');
        if (response.statusCode == 200) {
          _cache[userId] = MemoryImage(Uint8List.fromList(response.data));
        } else {
          _cache[userId] = AssetImage('assets/default_avatar.jpg');
        }
      } catch (e) {
        print('Failed to load user photo: $e');
        _cache[userId] = AssetImage('assets/default_avatar.jpg');
      }
    }
    return _cache[userId]!;
  }
}
