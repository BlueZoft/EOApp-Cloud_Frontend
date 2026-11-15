import 'package:flutter/material.dart';

class AppPage extends StatelessWidget {
  final String title;
  final Widget child;
  const AppPage({super.key, required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(title), actions: [
        IconButton(
            tooltip: 'මුල් පිටුව',
            icon: const Icon(Icons.home),
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst))
      ]),
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: child))));
}

class DetailCard extends StatelessWidget {
  final String label, value;
  const DetailCard({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(value)
          ])));
}
