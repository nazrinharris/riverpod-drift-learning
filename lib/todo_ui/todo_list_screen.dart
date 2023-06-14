import 'package:drift/drift.dart' as d;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_learning/todo_ui/todo_list_provider.dart';
import 'package:drift_db_viewer/drift_db_viewer.dart';

import '../data/drift_db.dart';
import '../data/provider/drift_db_provider.dart';

class TodoListScreen extends ConsumerWidget {
  const TodoListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Todo List"),
          actions: [
            CompletedOnlySwitch(),
          ],
        ),
        body: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => DriftDbViewer(ref.watch(riverDriftDatabaseProvider))));
              },
              child: Text("Inspect DB"),
            ),
            Expanded(
              child: TaskList(),
            ),
            NewTaskInput(),
          ],
        ));
  }
}

class TaskList extends ConsumerWidget {
  const TaskList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(watchAllTasksProvider);

    return stream.when(
      data: (list) {
        final casted = list as List<Task>;

        return ListView.builder(
          itemCount: casted.length,
          itemBuilder: (context, index) {
            final task = casted[index];

            return ListTile(
              title: Text(task.name),
              subtitle: Text(task.dueDate?.toString() ?? "No due date"),
              trailing: Checkbox(
                value: task.completed,
                onChanged: (value) {
                  ref.read(tasksDaoProvider).updateTask(task.copyWith(completed: value));
                },
              ),
            );
          },
        );
      },
      error: (e, __) {
        return Text(e.toString());
      },
      loading: () => Align(
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class NewTaskInput extends ConsumerStatefulWidget {
  const NewTaskInput({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NewTaskInputState();
}

class _NewTaskInputState extends ConsumerState<NewTaskInput> {
  DateTime? newTaskDate;
  Tag? selectedTag;
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          _buildTextField(),
          _buildTagSelector(context),
          _buildDateButton(),
        ],
      ),
    );
  }

  Widget _buildTextField() {
    return Expanded(
      flex: 1,
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: "What do you need to do?"),
        onSubmitted: (value) {
          ref.read(tasksDaoProvider).insertTask(TasksCompanion(
                name: d.Value(value),
                dueDate: d.Value(newTaskDate),
              ));
          controller.clear();
          newTaskDate = null;
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }

  StreamBuilder<List<Tag>> _buildTagSelector(BuildContext context) {
    return StreamBuilder<List<Tag>>(
      stream: ref.read(tagsDaoProvider).watchTags(),
      builder: (context, snapshot) {
        final tags = snapshot.data ?? [];

        DropdownMenuItem<Tag> dropdownFromTag(Tag tag) {
          return DropdownMenuItem(
            value: tag,
            child: Row(
              children: <Widget>[
                Text(tag.name),
                SizedBox(width: 5),
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(tag.color),
                  ),
                ),
              ],
            ),
          );
        }

        final dropdownMenuItems = tags.map((tag) => dropdownFromTag(tag)).toList()
          // Add a "no tag" item as the first element of the list
          ..insert(
            0,
            DropdownMenuItem(
              value: null,
              child: Text('No Tag'),
            ),
          );

        return Expanded(
          child: DropdownButton(
            onChanged: (Tag? tag) {
              setState(() {
                selectedTag = tag;
              });
            },
            isExpanded: true,
            value: selectedTag,
            items: dropdownMenuItems,
          ),
        );
      },
    );
  }

  Widget _buildDateButton() {
    return IconButton(
      icon: const Icon(Icons.calendar_today),
      onPressed: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2010),
          lastDate: DateTime(2100),
        );

        if (selectedDate == null) return;

        setState(() {
          newTaskDate = selectedDate;
        });
      },
    );
  }
}

class CompletedOnlySwitch extends ConsumerWidget {
  const CompletedOnlySwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.check),
          CupertinoSwitch(
            value: ref.watch(showIsCompletedProvider),
            onChanged: (_) {
              ref.read(showIsCompletedProvider.notifier).toggle();
            },
          ),
        ],
      ),
    );
  }
}

class NewTagInput extends ConsumerStatefulWidget {
  const NewTagInput({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NewTagInputState();
}

class _NewTagInputState extends ConsumerState<NewTagInput> {
  static const Color DEFAULT_COLOR = Colors.red;

  Color pickedTagColor = DEFAULT_COLOR;
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          _buildTextField(context),
          _buildColorPickerButton(context),
        ],
      ),
    );
  }

  Flexible _buildTextField(BuildContext context) {
    return Flexible(
      flex: 1,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(hintText: 'Tag Name'),
        onSubmitted: (inputName) {
          final dao = ref.read(tagsDaoProvider);
          final tag = TagsCompanion(
            name: d.Value(inputName),
            color: d.Value(pickedTagColor.value),
          );
          dao.insertTag(tag);
          resetValuesAfterSubmit();
        },
      ),
    );
  }

  Widget _buildColorPickerButton(BuildContext context) {
    return Flexible(
      flex: 1,
      child: GestureDetector(
        child: Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: pickedTagColor,
          ),
        ),
        onTap: () {
          _showColorPickerDialog(context);
        },
      ),
    );
  }

  Future _showColorPickerDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: MaterialColorPicker(
            allowShades: false,
            selectedColor: DEFAULT_COLOR,
            onMainColorChange: (colorSwatch) {
              setState(() {
                pickedTagColor = colorSwatch![500]!;
              });
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

  void resetValuesAfterSubmit() {
    setState(() {
      pickedTagColor = DEFAULT_COLOR;
      controller.clear();
    });
  }
}
