import 'dart:convert' show json;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart'
    show Brightness, Locale, WidgetsFlutterBinding, runApp;
import 'package:flutter/services.dart'
    show SystemChrome, SystemUiOverlayStyle, rootBundle;

import 'package:nhie/env.dart';
import 'package:nhie/models/category.dart';
import 'package:nhie/models/statement.dart';
import 'package:nhie/screens/app.dart';
import 'package:nhie/theme/style.dart';

Future<void> main() async {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
    systemNavigationBarColor: appTheme().scaffoldBackgroundColor,
    statusBarColor: appTheme().scaffoldBackgroundColor,
    statusBarIconBrightness: Brightness.dark,
  ));
  WidgetsFlutterBinding.ensureInitialized();

  String raw = await rootBundle.loadString('lib/config.json');
  Map config = json.decode(raw);

  BuildEnvironment.init(
    flavor: BuildFlavor.production,
    baseUrl: config['prod']['baseUrl'] as String,
    defaultStatement: Statement.fromMap(config['defaultStatement']),
    errorStatement: Statement.fromMap(config['errorStatement']),
    categories: [
      Category.fromMap(config['categories']['harmless']),
      Category.fromMap(config['categories']['delicate']),
      Category.fromMap(config['categories']['offensive'])
    ],
    maxPrefetchCalls: config['maxPrefetchCalls'],
    prefetchWaitTime: config['prefetchWaitTime'],
    languageCodes: config['languageCodes'].cast<String>(),
    selectedLanguage: config['selectedLanguage'],
  );
  assert(env != null);

  runApp(EasyLocalization(
      supportedLocales: [
        Locale('en', ''),
        Locale('de', ''),
        Locale('es', '')
      ],
      path: 'assets/translations',
      fallbackLocale: Locale('en', ''),
      child: App()));
}
