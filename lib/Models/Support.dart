import 'MessageUser.dart';

class Support {
  final int idSupports;
  final int messageId;
  final int userId;
  final int specialistId;
  MessageUser? lastMessage; // Add this property

  Support({
    required this.idSupports,
    required this.messageId,
    required this.userId,
    required this.specialistId,
    this.lastMessage, // Initialize it with null
  });

  /* factory Correspondence.fromJson(Map<String, dynamic> json) {
    return Correspondence(
      idCorrespondence: json['idCorrespondence'],
      messageId: json['messageId'],
      userId: json['userId'],
      senderId: json['senderId'],
    );
  }*/

  Map<String, dynamic> toJson() {
    return {
      'idSupports': idSupports,
      'messageId': messageId,
      'userId': userId,
      'specialistId': specialistId,
      // Include lastMessage details if it's not null
      'lastMessage': lastMessage?.toJson(),
    };
  }

  factory Support.fromJson(Map<String, dynamic> json) {
    // Your existing fromJson constructor
    // Modify it to handle lastMessage
    return Support(
      idSupports: json['idSupports'],
      messageId: json['messageId'],
      userId: json['userId'],
      specialistId: json['specialistId'],
      lastMessage: json['lastMessage'] != null ? MessageUser.fromJson(json['lastMessage']) : null,
    );
  }
}
