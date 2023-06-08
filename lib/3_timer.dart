import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const names = [
  'Alice',
  'Bob',
  'Charlie',
  'Dave',
  'Eve',
  'Frank',
  'Grace',
  'Heidi',
  'Ivan',
  'Judy',
  'Kincaid',
  'Larry',
  'Mallory',
];

final tickerProvider = StreamProvider(
  (ref) => Stream.periodic(
    const Duration(seconds: 1),
    (i) => i + 1,
  ),
);

final namesProvider = StreamProvider((ref) {
  return ref
      .watch(tickerProvider.stream)
      .map((event) => names.getRange(0, event));
});

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final names = ref.watch(namesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Timer"),
      ),
      body: names.when(
        data: (data) {
          return ListView(
            children: data.map((e) => Text(e)).toList(),
          );
        },
        error: (error, stackTrace) => Text(
          "Error: $error",
          style: Theme.of(context).textTheme.headline2,
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
