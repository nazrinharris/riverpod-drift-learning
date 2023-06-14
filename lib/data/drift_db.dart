import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'drift_db.g.dart';

// You can set custom data object name, if not it defaults to Task. (I think it just removes the 's')
// @DataClassName("TaskObject")
class Tasks extends Table {
  // autoIncrement automatically sets this to be the primary key
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  /// This is a foreign key, it references the id column in the Tags table. So, whenever
  /// we try to add a tag to a task, it will check to make sure that the tag exists in the
  /// Tags table. If it doesn't, it will throw an error.
  ///
  /// The nullable() means that we can have a task without a tag. And so, in the customConstraint,
  /// we would need to add the NULL keyword.
  TextColumn get tagName => text().nullable().customConstraint('NULL REFERENCES tags(name)')();

  // We can set a composite primary key like this, not really sure how it works or
  // technically what it does.
  // @override
  // Set<Column> get primaryKey => {id, name};
}

class TaskWithTag {
  final Task task;
  final Tag tag;

  TaskWithTag({required this.task, required this.tag});
}

class Tags extends Table {
  // When you apply autoIncrement to a column, it automatically sets it to be the primary key.
  // IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 20)();
  IntColumn get color => integer()();

  // In this instance, I want to make the [name] to be the primary key.
  @override
  Set<Column> get primaryKey => {name};
}

@DriftDatabase(tables: [Tasks, Tags], daos: [TasksDao, TagsDao])
class RiverDriftDatabase extends _$RiverDriftDatabase {
  RiverDriftDatabase() : super(_openConnection());

  /// Each time a table is changed or updated, bump this number. 1 is when there were
  /// only the Tasks table.
  // @override
  // int get schemaVersion => 1;

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(tasks, tasks.tagName);
            await migrator.createTable(tasks);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'drift_db.sqlite'));
    return NativeDatabase.createBackgroundConnection(file, logStatements: true);
  });
}

@DriftAccessor(tables: [
  Tasks,
  Tags,
], queries: {
  'completedTasksGenerate': 'SELECT * FROM tasks WHERE completed = 1 ORDER BY due_date DESC, name;'
})
class TasksDao extends DatabaseAccessor<RiverDriftDatabase> with _$TasksDaoMixin {
  TasksDao(RiverDriftDatabase db) : super(db);

  Future<List<Task>> getAllTasks() => select(tasks).get();

  Stream<List<TaskWithTag>> watchAllTasks() {
    return (select(tasks)
          ..orderBy(
            [
              (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.desc),
              (t) => OrderingTerm(expression: t.name),
            ],
          ))
        .join([
          leftOuterJoin(tags, tags.name.equalsExp(tasks.tagName)),
        ])
        .watch()
        .map(
          (rows) => rows.map((row) {
            return TaskWithTag(task: row.readTable(tasks), tag: row.readTable(tags));
          }).toList(),
        );
  }

  Stream<List<Task>> watchCompletedTasks() {
    return (select(tasks)
          ..orderBy([
            (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.name),
          ])
          ..where((t) => t.completed.equals(true)))
        .watch();
  }

  Stream<List<Task>> watchCompletedTasksCustom() {
    return customSelect(
      'SELECT * FROM tasks WHERE completed = 1 ORDER BY due_date DESC, name;',
      readsFrom: {tasks},
    ).watch().map((rows) => rows
        .map((row) => Task(
              id: row.read<int>('id'),
              name: row.read<String>('name'),
              completed: row.read<bool>('completed'),
            ))
        .toList());
  }

  // The int returned is the id of the task that was inserted, but only if it has the auto-increment column.
  Future<int> insertTask(TasksCompanion task) => into(tasks).insert(task);
  Future updateTask(Task task) => update(tasks).replace(task);
  Future deleteTask(Task task) => delete(tasks).delete(task);
}

@DriftAccessor(tables: [Tags])
class TagsDao extends DatabaseAccessor<RiverDriftDatabase> with _$TagsDaoMixin {
  TagsDao(RiverDriftDatabase db) : super(db);

  Stream<List<Tag>> watchTags() => select(tags).watch();
  Future insertTag(TagsCompanion tag) => into(tags).insert(tag);
}
