import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ArticlesScreen extends StatelessWidget {
  ArticlesScreen({Key? key}) : super(key: key);

  final List<Map<String, String>> articles = [
    {
      'title': 'Budgeting 101: How to Create a Budget',
      'url': 'https://www.nerdwallet.com/article/finance/how-to-budget',
    },
    {
      'title': '50/30/20 Budget Rule: How to Use It',
      'url': 'https://www.investopedia.com/ask/answers/022916/what-502030-budget-rule.asp',
    },
    {
      'title': 'How to Save Money: 17 Proven Ways',
      'url': 'https://www.ramseysolutions.com/saving/how-to-save-money',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Suggested Articles')),
      body: ListView.builder(
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          return ListTile(
            title: Text(article['title']!),
            onTap: () async {
              final url = Uri.parse(article['url']!);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
          );
        },
      ),
    );
  }
}

