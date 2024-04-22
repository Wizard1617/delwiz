import 'package:delwiz/Models/MediaFileDto.dart';
import 'package:flutter/cupertino.dart';

class NewsDto {
  final int newsId;
  late final String description;
  final int pictureId;
  int likes;
  int dislikes;
  final DateTime sendingTime;
  final int idUser;
  bool likedByCurrentUser; // Поле для отслеживания текущего состояния лайка
  bool dislikedByCurrentUser; // Поле для отслеживания текущего состояния дизлайка
  ValueNotifier<int> likesNotifier;
  ValueNotifier<int> dislikesNotifier;
  final List<MediaFileDto> mediaFiles;


  NewsDto({
    required this.newsId,
    required this.description,
    required this.pictureId,
    required this.likes,
    required this.dislikes,
    required this.sendingTime,
    required this.idUser,
    required this.mediaFiles,

    this.likedByCurrentUser = false, // По умолчанию лайк не стоит
    this.dislikedByCurrentUser = false, // По умолчанию дизлайк не стоит
  }): likesNotifier = ValueNotifier<int>(likes),
        dislikesNotifier = ValueNotifier<int>(dislikes);

  factory NewsDto.fromJson(Map<String, dynamic> json) {
    var mediaList = (json['mediaFiles'] as List).map((i) => MediaFileDto.fromJson(i)).toList();

    return NewsDto(
      newsId: json['newsId'] as int? ?? 0, // Используйте значение по умолчанию, если null
      description: json['description_News'] as String? ?? '',
      pictureId: json['pictureId'] as int? ?? 0, // Используйте значение по умолчанию, если null
      likes: json['likes'] as int? ?? 0,
      dislikes: json['disLike'] as int? ?? 0,
      sendingTime: DateTime.parse(json['sendingTime'] as String),
      idUser: json['idUser'] as int? ?? 0, // Используйте значение по умолчанию, если null
      likedByCurrentUser: json['likedByCurrentUser'] as bool? ?? false,
      dislikedByCurrentUser: json['dislikedByCurrentUser'] as bool? ?? false,
      mediaFiles: mediaList,

    );
  }
// В классе NewsDto
  Map<String, dynamic> toJson() {
    return {
      'newsId': newsId,
      'description': description,
      'pictureId': pictureId,
      'likes': likes,
      'dislikes': dislikes,
      'sendingTime': sendingTime.toIso8601String(),
      'idUser': idUser,
      'likedByCurrentUser': likedByCurrentUser,
      'dislikedByCurrentUser': dislikedByCurrentUser,
      'mediaFiles': mediaFiles.map((e) => e.toJson()).toList(),
    };
  }

}
