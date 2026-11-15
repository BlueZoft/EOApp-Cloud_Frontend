import 'package:flutter/material.dart';
import 'data/catalogue_repository.dart';
import 'models/catalogue.dart';
import 'l10n/si.dart';
import 'category_screen.dart';

void main() => runApp(const OutreachApp());

class OutreachApp extends StatelessWidget {
  const OutreachApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Hetarata',
      theme: ThemeData(
          fontFamily: 'NotoSansSinhala',
          colorSchemeSeed: Colors.cyan,
          useMaterial3: true),
      home: const WelcomeScreen());
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
      appBar: AppBar(title: const Text(Si.title)),
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
                          child: const Text('නැවත උත්සාහ කරන්න'));
                    }
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    return ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('ආරම්භ කරන්න'),
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) => CategoryScreen(
                                    catalogue: snapshot.data!))));
                  }))));
}
