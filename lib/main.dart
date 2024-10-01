import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Browser',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: BrowserScreen(),
    );
  }
}

class BrowserScreen extends StatefulWidget {
  @override
  _BrowserScreenState createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  List<TabData> tabs = [];
  int activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _addNewTab();
  }

  WebViewController _createWebViewController(String url) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) async {
            final title = await tabs[activeTabIndex].controller.getTitle();
            if (title != null) {
              _updateTabTitle(activeTabIndex, title);
            } else {
              _updateTabTitle(activeTabIndex, url);
            }
          },
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  void _addNewTab() {
    setState(() {
      tabs.add(TabData(
        title: 'New Tab',
        url: 'https://www.duckduckgo.com',
        controller: _createWebViewController('https://www.duckduckgo.com'),
      ));
      activeTabIndex = tabs.length - 1;
    });
  }

  void _closeTab(int index) {
    if (tabs.length > 1) {
      setState(() {
        tabs.removeAt(index);
        if (activeTabIndex >= tabs.length) {
          activeTabIndex = tabs.length - 1;
        }
      });
    }
  }

  void _switchTab(int index) {
    setState(() {
      activeTabIndex = index;
    });
  }

  void _updateTabTitle(int index, String newTitle) {
    setState(() {
      tabs[index].title = newTitle;
    });
  }

 void _showTabOverview() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Open Tabs',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    controller: controller,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: tabs.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          _switchTab(index);
                          Navigator.pop(context);
                        },
                        child: Card(
                          margin: EdgeInsets.all(8),
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(tabs[index].url),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              Text(tabs[index].title),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.close),
                                    onPressed: () {
                                      _closeTab(index);
                                      if (tabs.isEmpty) Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tabs[activeTabIndex].title),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addNewTab,
          ),
          IconButton(
            icon: Icon(Icons.tab),
            onPressed: _showTabOverview,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: WebViewWidget(
              controller: tabs[activeTabIndex].controller,
            ),
          ),
          NavigationControls(controller: tabs[activeTabIndex].controller),
        ],
      ),
    );
  }
}

class TabData {
  String title;
  String url;
  WebViewController controller;

  TabData({required this.title, required this.url, required this.controller});
}

class NavigationControls extends StatelessWidget {
  final WebViewController controller;

  NavigationControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            if (await controller.canGoBack()) {
              await controller.goBack();
            }
          },
        ),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: () async {
            if (await controller.canGoForward()) {
              await controller.goForward();
            }
          },
        ),
      ],
    );
  }
}