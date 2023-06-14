import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../drift_db.dart';

part 'drift_db_provider.g.dart';

@Riverpod(keepAlive: true)
RiverDriftDatabase riverDriftDatabase(RiverDriftDatabaseRef ref) => RiverDriftDatabase();

@Riverpod(keepAlive: true)
TasksDao tasksDao(TasksDaoRef ref) => ref.watch(riverDriftDatabaseProvider).tasksDao;

@Riverpod(keepAlive: true)
TagsDao tagsDao(TagsDaoRef ref) => ref.watch(riverDriftDatabaseProvider).tagsDao;
