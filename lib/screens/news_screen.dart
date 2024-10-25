import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ogp_data_extract/ogp_data_extract.dart';
import 'package:webfeed_plus/domain/rss_feed.dart';
import 'package:webfeed_plus/domain/rss_item.dart';
import 'webview_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<RssItem> _newsItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoading = true;
    });

    // 岐阜新聞のRSSフィードに変更
    const rssUrl =
        'https://api.allorigins.win/get?url=https://news.yahoo.co.jp/rss/media/gifuweb/all.xml';

    try {
      final response = await http.get(Uri.parse(rssUrl));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final content = json['contents'] as String;

        final decodedContent =
            content.replaceAll(r'\n', '\n').replaceAll(r'\"', '"');
        final feed = RssFeed.parse(decodedContent);

        setState(() {
          _newsItems = feed.items ?? [];
        });
      } else {
        throw Exception('Failed to load RSS feed');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _newsItems.length,
              itemBuilder: (context, index) {
                final item = _newsItems[index];
                return FutureBuilder<OgpData?>(
                  future: _fetchOgpData(item.link),
                  builder: (context, snapshot) {
                    final ogpData = snapshot.data;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 5.0),
                      child: InkWell(
                        onTap: () => _openArticle(item.link),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10.0),
                                topRight: Radius.circular(10.0),
                              ),
                              child: ogpData?.image != null
                                  ? Image.network(
                                      ogpData!.image!,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 200,
                                      width: double.infinity,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.article,
                                        size: 50,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 8.0),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ogpData?.title ?? item.title ?? 'No title',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    ogpData?.description ??
                                        item.pubDate?.toLocal().toString() ??
                                        '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<OgpData?> _fetchOgpData(String? url) async {
    if (url == null) return null;
    try {
      return await OgpDataExtract.execute(url);
    } catch (e) {
      print('Failed to fetch OGP data: $e');
      return null;
    }
  }

  void _openArticle(String? url) {
    if (url != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewScreen(url: url),
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------------------


// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:ogp_data_extract/ogp_data_extract.dart';
// import 'package:webfeed_plus/domain/rss_feed.dart';
// import 'package:webfeed_plus/domain/rss_item.dart';
// import 'webview_screen.dart';

// class NewsScreen extends StatefulWidget {
//   const NewsScreen({super.key});

//   @override
//   State<NewsScreen> createState() => _NewsScreenState();
// }

// class _NewsScreenState extends State<NewsScreen> {
//   List<RssItem> _newsItems = [];
//   List<RssItem> _filteredItems = []; // フィルタリングされたニュースを保持
//   bool _isLoading = true;
//   String _currentCity = '岐阜'; // 初期は「岐阜」のニュースを表示

//   @override
//   void initState() {
//     super.initState();
//     _fetchNews();
//   }

//   // RSSフィードを取得する関数
//   Future<void> _fetchNews() async {
//     setState(() {
//       _isLoading = true;
//     });

//     const rssUrl = 'https://api.allorigins.win/get?url=https://news.yahoo.co.jp/rss/media/gifuweb/all.xml';

//     try {
//       final response = await http.get(Uri.parse(rssUrl));
//       if (response.statusCode == 200) {
//         final json = jsonDecode(response.body);
//         final content = json['contents'] as String;
//         final decodedContent = content.replaceAll(r'\n', '\n').replaceAll(r'\"', '"');
//         final feed = RssFeed.parse(decodedContent);

//         setState(() {
//           _newsItems = feed.items ?? [];
//           _filterNews(); // ニュースをフィルタリング
//         });
//       } else {
//         throw Exception('Failed to load RSS feed');
//       }
//     } catch (e) {
//       print('Error: $e');
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   // ニュースをフィルタリングする関数
//   void _filterNews() {
//     setState(() {
//       _filteredItems = _newsItems.where((item) {
//         final content = (item.title ?? '') + (item.description ?? '') + (item.link ?? '');
//         if (_currentCity == '岐阜') {
//           return content.contains('岐阜');
//         } else if (_currentCity == '大垣') {
//           return content.contains('大垣');
//         }
//         return false;
//       }).toList();
//     });
//   }

//   // 都市を変更する関数
//   void _changeCity(String city) {
//     setState(() {
//       _currentCity = city;
//       _filterNews(); // 都市を変更するたびにフィルタリングを再実行
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('$_currentCityのニュース'),
//       ),
//       body: Column(
//         children: [
//           // 都市切り替えボタン
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 ElevatedButton(
//                   onPressed: () => _changeCity('岐阜'),
//                   child: const Text('岐阜のニュース'),
//                 ),
//                 const SizedBox(width: 10),
//                 ElevatedButton(
//                   onPressed: () => _changeCity('大垣'),
//                   child: const Text('大垣のニュース'),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : _filteredItems.isEmpty
//                     ? const Center(child: Text('該当するニュースが見つかりませんでした。'))
//                     : ListView.builder(
//                         itemCount: _filteredItems.length,
//                         itemBuilder: (context, index) {
//                           final item = _filteredItems[index];
//                           return FutureBuilder<OgpData?>(
//                             future: _fetchOgpData(item.link),
//                             builder: (context, snapshot) {
//                               final ogpData = snapshot.data;
//                               return Card(
//                                 margin: const EdgeInsets.symmetric(
//                                     horizontal: 10.0, vertical: 5.0),
//                                 child: InkWell(
//                                   onTap: () => _openArticle(item.link),
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       ClipRRect(
//                                         borderRadius: const BorderRadius.only(
//                                           topLeft: Radius.circular(10.0),
//                                           topRight: Radius.circular(10.0),
//                                         ),
//                                         child: ogpData?.image != null
//                                             ? Image.network(
//                                                 ogpData!.image!,
//                                                 width: double.infinity,
//                                                 height: 200,
//                                                 fit: BoxFit.cover,
//                                               )
//                                             : Container(
//                                                 height: 200,
//                                                 width: double.infinity,
//                                                 color: Colors.grey[300],
//                                                 child: const Icon(
//                                                   Icons.article,
//                                                   size: 50,
//                                                   color: Colors.white,
//                                                 ),
//                                               ),
//                                       ),
//                                       const SizedBox(height: 8.0),
//                                       Padding(
//                                         padding: const EdgeInsets.symmetric(
//                                             horizontal: 20.0, vertical: 10.0),
//                                         child: Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             Text(
//                                               ogpData?.title ??
//                                                   item.title ?? 'No title',
//                                               style: const TextStyle(
//                                                 fontWeight: FontWeight.bold,
//                                                 fontSize: 18,
//                                                 color: Colors.black,
//                                               ),
//                                             ),
//                                             const SizedBox(height: 4.0),
//                                             Text(
//                                               ogpData?.description ??
//                                                   item.pubDate
//                                                       ?.toLocal()
//                                                       .toString() ??
//                                                   '',
//                                               style: const TextStyle(
//                                                 fontSize: 14,
//                                                 color: Colors.grey,
//                                               ),
//                                               maxLines: 3,
//                                               overflow: TextOverflow.ellipsis,
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           );
//                         },
//                       ),
//           ),
//         ],
//       ),
//     );
//   }

//   // OGPデータを取得する関数
//   Future<OgpData?> _fetchOgpData(String? url) async {
//     if (url == null) return null;
//     try {
//       return await OgpDataExtract.execute(url);
//     } catch (e) {
//       print('Failed to fetch OGP data: $e');
//       return null;
//     }
//   }

//   // WebViewで記事を開く関数
//   void _openArticle(String? url) {
//     if (url != null) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => WebViewScreen(url: url),
//         ),
//       );
//     }
//   }
// }
