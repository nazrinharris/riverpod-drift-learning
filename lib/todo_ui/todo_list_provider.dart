import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/drift_db.dart';
import '../data/provider/drift_db_provider.dart';

part 'todo_list_provider.g.dart';

@riverpod
class ShowIsCompleted extends _$ShowIsCompleted {
  @override
  bool build() {
    return false;
  }

  void toggle() {
    state = !state;
    debugPrint('Toggled to: $state');
  }
}

@riverpod
Stream<List<Task>> watchCompletedTasks(WatchCompletedTasksRef ref) {
  return ref.watch(tasksDaoProvider).completedTasksGenerate().watch();
}

@riverpod
Stream<List<TaskWithTag>> watchAllTasks(WatchAllTasksRef ref) {
  return ref.watch(tasksDaoProvider).watchAllTasks();
}

// @riverpod
// class WatchChosenTasks extends _$WatchChosenTasks {
//   @override
//   Stream<List<Task>> build() {
//     final showIsCompleted = ref.watch(showIsCompletedProvider);

//     return showIsCompleted
//         ? ref.watch(tasksDaoProvider).watchCompletedTasks()
//         : ref.watch(tasksDaoProvider).watchAllTasks();
//   }
// }
