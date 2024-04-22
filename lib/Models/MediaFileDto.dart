class MediaFileDto {
  final int pictureId;
  final String url;
  final String type; // 'video' или 'image'

  MediaFileDto({
    required this.pictureId,
    required this.url,
    required this.type,
  });

  factory MediaFileDto.fromJson(Map<String, dynamic> json) {
    return MediaFileDto(
      pictureId: json['pictureId'],
      url: json['url'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pictureId': pictureId,
      'url': url,
      'type': type,
    };
  }
}
