// ignore_for_file: prefer_const_constructors, unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import 'examples/5_films.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await supa.Supabase.initialize(
    url: "https://sloyzbyrkoimithtvueg.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNsb3l6Ynlya29pbWl0aHR2dWVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODAxOTgzMzMsImV4cCI6MTk5NTc3NDMzM30.kjHjKLZTd9YfvpQbVLZJvTNF-54tlAZG9MRiFuUv4wk",
  );

  runApp(
    ProviderScope(
      child: RiverApp(),
    ),
  );
}

class RiverApp extends StatelessWidget {
  const RiverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      title: "Riverpod Learning",
      home: FilmsScreen(),
    );
  }
}
