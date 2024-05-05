
import 'package:delwiz/Api/ApiRequest.dart';

class User {
  final int id;
  final String firstName;
  final String lastName;
  final String loginUser;
  final String? nameRole; // Добавляем поле для роли пользователя.

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.loginUser,
     this.nameRole, // Обновляем конструктор.
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['idUser'] ?? IDUser,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      loginUser: json['loginUser'] ?? '',
      nameRole: json['nameRole'] ?? '', // Получаем роль из поля 'nameRole'.
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idUser': id,
      'firstName': firstName,
      'lastName': lastName,
      'loginUser': loginUser,
      'nameRole': nameRole, // Включаем роль в сериализацию.
    };
  }
}