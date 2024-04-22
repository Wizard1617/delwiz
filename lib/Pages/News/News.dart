import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../Api/ApiRequest.dart';
import '../../Models/NewsDto.dart';
import '../../Models/NewsService.dart';
import 'NewsCard.dart';

class NewsScreen extends StatefulWidget {

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  final NewsService _newsService = NewsService();
  late List<Map<String, dynamic>> pictData = [];

  final Map<String, Image> _imageCache = {};
  final Map<int, List<int>> _userPhotoCache = {};


  final ScrollController _scrollController = ScrollController();
  List<NewsDto> newsData = [];
  int currentPage = 1;
  bool isLoading = false;
  bool isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    // Вызываем _fetchNewsData() только если данные еще не загружены
    if (!isDataLoaded) {
      _fetchNewsData();
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Вызываем _fetchNewsData() только если данные еще не загружены
    if (!isDataLoaded) {
      _fetchNewsData();
    }
  }


  Future<void> _fetchNewsData() async {
    if (isLoading) return; // Если уже идет загрузка, выходим
    isLoading = true;

    try {
      List<NewsDto> newNews = await _newsService.getNews(pageNumber: currentPage, pageSize: 10);
      if (newNews.isEmpty) {
        isLoading = false; // Если новых данных нет, сбрасываем флаг загрузки
        return;
      }

      setState(() {
        newsData.addAll(newNews);
        currentPage++; // Увеличиваем номер страницы только если были получены данные
        isDataLoaded = true; // Устанавливаем флаг загруженности данных
      });
    } catch (error) {
      print('Error fetching news data: $error');
    } finally {
      isLoading = false; // Гарантируем сброс флага загрузки
    }
  }


  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _fetchNewsData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Не забудьте освободить контроллер
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      key: globalScaffoldKey,

      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: <Widget>[
            SliverAppBar(
              title: Text('Новости', style: TextStyle(color: Colors.white),),
              backgroundColor: Colors.deepOrangeAccent,
              floating: true,
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  if (index >= newsData.length) {
                    return isLoading ? Center(child: CircularProgressIndicator()) : null;
                  }
                  return NewsCard(
                    news: newsData[index],
                  );
                },
                childCount: newsData.length + (isLoading ? 1 : 0),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.only(bottom: 80), // Дополнительный отступ внизу списка
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    setState(() {
      currentPage = 1; // Сброс текущей страницы
      newsData.clear(); // Очистка существующих данных
      isLoading = false; // Сброс флага загрузки
    });
    await _fetchNewsData(); // Перезагрузка данных
  }
}
