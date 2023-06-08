import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FooScreen extends ConsumerWidget {
  const FooScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(currentDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(date.toIso8601String()),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Consumer(builder: (context, ref, child) {
            final count = ref.watch(counterProvider);
            return Text(
              count?.toString() ?? "null",
              style: Theme.of(context).textTheme.headline4,
            );
          }),
          SizedBox(height: 20),
          TextButton(
            onPressed: ref.read(counterProvider.notifier).increment,
            child: Text("Increment"),
          ),
          SizedBox(height: 20),
          OutlinedButton(
            onPressed: () {},
            child: Text("To Weather"),
          )
        ],
      )),
    );
  }
}

final currentDate = Provider((ref) => DateTime.now());

extension OptionalInfixAddition<T extends num> on T? {
  T? operator +(T? other) {
    final shadow = this;
    if (shadow != null) {
      return shadow + (other ?? 0) as T;
    } else {
      return null;
    }
  }
}

final counterProvider = StateNotifierProvider<Counter, int?>((ref) {
  return Counter();
});

class Counter extends StateNotifier<int?> {
  Counter() : super(null);
  void increment() => state = state == null ? 1 : state + 1;
  int? get value => state;
}
