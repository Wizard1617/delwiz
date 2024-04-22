import 'package:delwiz/Pages/News/NewsCard.dart';
import 'package:flutter/material.dart';
import '../../Models/NewsDto.dart';
import '../../Models/NewsService.dart';
import '../News/EditNews.dart'; // Убедитесь, что у вас есть эта страница для редактирования новостей

class NewsListScreen extends StatefulWidget {
  final List<NewsDto> newsList;

  const NewsListScreen({Key? key, required this.newsList}) : super(key: key);

  @override
  _NewsListScreenState createState() => _NewsListScreenState();
}


class _NewsListScreenState extends State<NewsListScreen> with AutomaticKeepAliveClientMixin {

  bool isLoading = true;
  @override
  bool get wantKeepAlive => true;

  final NewsService _newsService = NewsService();



  void _editNews(BuildContext context, NewsDto newsItem) async {
    final updatedDescription = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNews(
          newsId: newsItem.newsId,
          initialDescription: newsItem.description,
        ),
      ),
    );

    // Проверяем, вернулось ли обновленное описание
    if (updatedDescription != null && updatedDescription is String) {
      setState(() {
        // Обновляем описание новости в списке
        newsItem.description = updatedDescription;
      });
    }
  }


  void _deleteNews(BuildContext context, NewsDto newsItem) async {
    try {
      await NewsService().deleteNews(newsItem.newsId);
      setState(() {
        widget.newsList.removeWhere((news) => news.newsId == newsItem.newsId);
      });
    } catch (e) {
      print('Error deleting news: $e');
    }
  }
  final PageStorageKey _key = PageStorageKey('news-list');

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          key: _key, // Уникальный ключ для сохранения состояния прокрутки
          slivers: <Widget>[
            SliverAppBar(
              title: Text('Новости'),
              backgroundColor: Colors.deepOrangeAccent,
              floating: true,
              automaticallyImplyLeading: true,
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  if (index >= widget.newsList.length) {
                    return isLoading ? Center(child: CircularProgressIndicator()) : null;
                  }
                  return NewsCard(news: widget.newsList[index]);
                },
                childCount: widget.newsList.length + (isLoading ? 1 : 0),  // Добавляем индикатор загрузки в конец списка, если данные загружаются
              ),
            ),

          ],
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    // Ваш код для обновления списка новостей
  }
}
