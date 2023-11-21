import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../page_welcome.dart';
import '../styles.dart';
import 'field_list.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Home extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DIRECTION-cassava',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        AppLocalizations.delegate, // Add this line
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en', ''), // English, no country code
        Locale('th', ''), // Thai, no country code
        Locale('vi', ''), // Viet, no country code
      ],
      theme: ThemeData(
        primarySwatch: Styles.themeColor,
      ),
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
              flexibleSpace: new Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TabBar(
                      tabs: [
                        Tab(icon: Icon(Icons.home)),
                        Tab(icon: Icon(Icons.agriculture)),
                      ],
                    ),
                  ])),
          body: TabBarView(
            children: [
              MyHomePage(title: ""),
              FieldList(),
            ],
          ),
        ),
      ),
    );
  }

}