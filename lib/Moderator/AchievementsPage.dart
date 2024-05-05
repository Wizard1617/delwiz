import 'package:delwiz/Api/ApiRequest.dart';
import 'package:delwiz/Moderator/AchievementDetailPage.dart';
import 'package:delwiz/Moderator/AddAchievementPage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({Key? key}) : super(key: key);

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  late Future<List<Map<String, dynamic>>> _achievementsFuture;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _achievementsFuture = _fetchAchievements();
  }

  Future<List<Map<String, dynamic>>> _fetchAchievements() async {
    final response = await http.get(Uri.parse('$api/Progresses'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => json as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load achievements');
    }
  }

  List<Map<String, dynamic>> _filterAchievements(List<Map<String, dynamic>> achievements, String query) {
    return achievements.where((achievement) {
      final name = achievement['nameProgress'] as String;
      return name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  Future<void> _deleteAchievement(int idProgress) async {
    try {
      Response response = await dio.delete('$api/Progresses/$idProgress');
      if (response.statusCode == 204) {
        // Показать сообщение об успешном удалении
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Достижение удалено')),
        );
        // Обновить страницу
        setState(() {
          // Выполните необходимые действия для обновления списка достижений
          // Например, перезагрузка данных
          _achievementsFuture = _fetchAchievements();
        });
      } else {
        // Показать сообщение об ошибке
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при удалении достижения')),
        );
      }
    } catch (e) {
      // Показать сообщение об ошибке
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении достижения: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Достижения', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepOrangeAccent,
        actions: [
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  child: ListTile(
                    leading: Icon(Icons.add, color: Colors.deepOrangeAccent),
                    title: Text('Добавить достижение'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddAchievementPage(),
                        ),
                      ).then((value) {
                        if (value == true) {
                          // Если значение true, значит загрузка фото была успешной
                          _refreshAchievements(); // Обновление данных на странице AchievementsPage
                        }
                      });

                    },
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  // Обновляем список достижений при изменении текста поиска
                });
              },
              decoration: InputDecoration(
                labelText: 'Поиск по названию',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepOrangeAccent),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepOrangeAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepOrangeAccent),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _achievementsFuture,
              builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  final List<Map<String, dynamic>> filteredAchievements =
                  _filterAchievements(snapshot.data!, _searchController.text);
                  return RefreshIndicator(
                    onRefresh: _refreshAchievements,
                    child: ListView.builder(
                      itemCount: filteredAchievements.length,
                      itemBuilder: (BuildContext context, int index) {
                        final achievement = filteredAchievements[index];
                        return
                          GestureDetector(
                            onLongPress: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text("Удалить выбранное достижение?"),
                                    actions: <Widget>[
                                      TextButton(
                                        child: Text("Нет"),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: Text("Да"),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          _deleteAchievement(achievement['idProgress']);
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AchievementDetailPage(
                                    name: achievement['nameProgress'],
                                    description: achievement['descriptionProgress'],
                                    idProgress: achievement['idProgress'],
                                    photo: FutureBuilder<Widget>(
                                      future: _fetchAchievementPhoto(achievement['idProgress']),
                                      builder: (BuildContext context, AsyncSnapshot<Widget> photoSnapshot) {
                                        if (photoSnapshot.connectionState == ConnectionState.waiting) {
                                          return CircularProgressIndicator();
                                        } else if (photoSnapshot.hasError) {
                                          return Icon(Icons.error);
                                        } else {
                                          return photoSnapshot.data ?? Icon(Icons.photo);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              );

                            },
                            child: ListTile(
                              title: Text(achievement['nameProgress']),
                              subtitle: Text(achievement['descriptionProgress']),
                              leading: FutureBuilder<Widget>(
                                future: _fetchAchievementPhoto(achievement['idProgress']),
                                builder: (BuildContext context, AsyncSnapshot<Widget> photoSnapshot) {
                                  if (photoSnapshot.connectionState == ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  } else if (photoSnapshot.hasError) {
                                    return Icon(Icons.error);
                                  } else {
                                    return photoSnapshot.data ?? Icon(Icons.photo);
                                  }
                                },
                              ),
                            ),
                          );
                      },
                    )
                  );

                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshAchievements() async {
    setState(() {
      _achievementsFuture = _fetchAchievements();
    });
  }

  Future<Widget> _fetchAchievementPhoto(int idProgress) async {
    final response = await http.get(Uri.parse('$api/Progresses/progres-photos/$idProgress'));
    if (response.statusCode == 200) {
      return Image.memory(response.bodyBytes);
    } else {
      return Future.error('Failed to load photo');
    }
  }
}
