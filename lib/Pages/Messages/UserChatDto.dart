class UserChatDto {
  final int correspondenceId;
  final int userId;
  final int senderId;
  final String userName;
  final String lastMessage;
  final List<int>? userPhoto;

  UserChatDto({
    required this.correspondenceId,
    required this.userId,
    required this.senderId,
    required this.userName,
    required this.lastMessage,
    this.userPhoto,
  });

  factory UserChatDto.fromJson(Map<String, dynamic> json) {
    return UserChatDto(
      correspondenceId: json['correspondenceId'],
      userId: json['userId'],
      senderId: json['senderId'],
      userName: json['userName'],
      lastMessage: json['lastMessage'],
      userPhoto: json['userPhoto'] != null ? List<int>.from(json['userPhoto']) : null,
    );
  }
}
