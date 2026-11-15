import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/catalogue.dart';

Future<Catalogue> loadCatalogue() async => Catalogue.fromJson(
    jsonDecode(await rootBundle.loadString('assets/catalogue.json'))
        as Map<String, dynamic>);
