import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

@immutable
class Person {
  final String name;
  final int age;
  final String id;

  Person({
    required this.name,
    required this.age,
    String? id,
  }) : id = id ?? const Uuid().v4();

  Person copyWith({
    String? name,
    int? age,
  }) {
    return Person(
      name: name ?? this.name,
      age: age ?? this.age,
      id: id,
    );
  }

  String get displayName => "$name ($age years old)";

  @override
  bool operator ==(covariant Person other) => id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => "Person(name: $name, age: $age, id: $id)";
}

class DataModel extends ChangeNotifier {
  final List<Person> _persons = [];

  int get count => _persons.length;

  List<Person> get persons => List.unmodifiable(_persons);

  void addPerson(Person person) {
    _persons.add(person);
    notifyListeners();
  }

  void removePerson(Person person) {
    _persons.remove(person);
    notifyListeners();
  }

  void updatePerson(Person updatedPerson) {
    final index = _persons.indexOf(updatedPerson);
    final oldPerson = _persons[index];

    if (oldPerson.name != updatedPerson.name ||
        oldPerson.age != updatedPerson.age) {
      _persons[index] = oldPerson.copyWith(
        name: updatedPerson.name,
        age: updatedPerson.age,
      );
      notifyListeners();
    }
  }
}

final dataModelProvider = ChangeNotifierProvider((_) => DataModel());

class PersonsScreen extends ConsumerWidget {
  const PersonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Persons"),
      ),
      body: Consumer(builder: (context, ref, child) {
        final dataModel = ref.watch(dataModelProvider);

        return ListView.builder(
          itemCount: dataModel.count,
          itemBuilder: (context, index) {
            final person = dataModel.persons[index];
            return ListTile(
              title: Text(person.displayName),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () =>
                    ref.read(dataModelProvider).removePerson(person),
              ),
              onTap: () async {
                final updatedPerson = await createOrUpdatePersonDialog(
                  context,
                  person,
                );
                if (updatedPerson != null) {
                  ref.read(dataModelProvider).updatePerson(updatedPerson);
                }
              },
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final newPerson = await createOrUpdatePersonDialog(context);
          if (newPerson != null) {
            ref.read(dataModelProvider).addPerson(newPerson);
          }
        },
      ),
    );
  }
}

final nameController = TextEditingController();
final ageController = TextEditingController();

Future<Person?> createOrUpdatePersonDialog(
  BuildContext context, [
  Person? existingPerson,
]) {
  String? name = existingPerson?.name;
  int? age = existingPerson?.age;

  nameController.text = name ?? "";
  ageController.text = age?.toString() ?? "";

  return showDialog<Person?>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Create or Update Person'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Enter name here...',
              ),
              onChanged: (value) => name = value,
            ),
            TextField(
              controller: ageController,
              decoration: const InputDecoration(
                labelText: 'Enter age here...',
              ),
              onChanged: (value) => age = int.tryParse(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (name != null && age != null) {
                if (existingPerson == null) {
                  final newPerson = Person(
                    name: name!,
                    age: age!,
                  );
                  Navigator.of(context).pop(newPerson);
                } else {
                  final updatedPerson = existingPerson.copyWith(
                    name: name!,
                    age: age!,
                  );
                  Navigator.of(context).pop(updatedPerson);
                }
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
