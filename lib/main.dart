import 'package:flutter/material.dart';
import 'data/catalogue_repository.dart';
import 'models/catalogue.dart';
import 'l10n/app_strings.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'category_screen.dart';
import 'package:flutter/foundation.dart';
import 'staff/staff_portal_screen.dart';

void main() => runApp(const OutreachApp());

class OutreachApp extends StatefulWidget {
  final Locale initialLocale;
  const OutreachApp({super.key, this.initialLocale = const Locale('si')});
  @override
  State<OutreachApp> createState() => _OutreachAppState();
}

class _OutreachAppState extends State<OutreachApp> {
  late Locale _locale = widget.initialLocale;
  @override
  Widget build(BuildContext context) => LanguageScope(
      locale: _locale,
      change: (locale) => setState(() {
            _locale = locale;
          }),
      child: MaterialApp(
          title: 'Hetarata',
          locale: _locale,
          supportedLocales: const [Locale('si'), Locale('en'), Locale('ta')],
          localizationsDelegates: const [
            AppStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate
          ],
          theme: ThemeData(
              fontFamily: _locale.languageCode == 'ta'
                  ? 'NotoSansTamil'
                  : _locale.languageCode == 'en'
                      ? 'Roboto'
                      : 'NotoSansSinhala',
              fontFamilyFallback: const [
                'NotoSansSinhala',
                'NotoSansTamil',
                'Roboto'
              ],
              colorSchemeSeed: Colors.cyan,
              useMaterial3: true),
          home: const WelcomeScreen()));
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late Future<Catalogue> _catalogue = loadCatalogue();
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(AppStrings.of(context).t('title')), actions: [
        const LanguagePicker(),
        if (kIsWeb)
          IconButton(
              tooltip: 'Officer inbox',
              icon: const Icon(Icons.work_outline),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => const StaffPortalScreen()))),
      ]),
      body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/fscreen.jpg'), fit: BoxFit.cover)),
          child: Center(
              child: FutureBuilder<Catalogue>(
                  future: _catalogue,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return ElevatedButton(
                          onPressed: () => setState(() {
                                _catalogue = loadCatalogue();
                              }),
                          child: Text(AppStrings.of(context).t('retry')));
                    }
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    return ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(AppStrings.of(context).t('start')),
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) => CategoryScreen(
                                    catalogue: snapshot.data!))));
                  }))));
}
