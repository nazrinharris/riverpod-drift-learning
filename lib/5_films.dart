import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

@immutable
class Film {
  final String id;
  final String title;
  final String desc;
  final bool isFavorite;

  const Film({
    required this.id,
    required this.title,
    required this.desc,
    required this.isFavorite,
  });

  Film copyWith({
    String? id,
    String? title,
    String? desc,
    bool? isFavorite,
  }) {
    return Film(
      id: id ?? this.id,
      title: title ?? this.title,
      desc: desc ?? this.desc,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  String toString() {
    return 'Film(id: $id, '
        'title: $title, '
        'desc: $desc, '
        'isFavorite: $isFavorite)';
  }

  @override
  bool operator ==(covariant Film other) =>
      id == other.id && isFavorite == other.isFavorite;

  @override
  int get hashCode => Object.hashAll([id, isFavorite]);
}

const allFilms = [
  Film(
    id: '1',
    title: 'The Shawshank Redemption',
    desc: 'Description for the shawshank redepmton',
    isFavorite: false,
  ),
  Film(
    id: '2',
    title: 'The Godfather',
    desc: 'Description for the godfather',
    isFavorite: false,
  ),
  Film(
    id: '3',
    title: 'The Dark Knight',
    desc: 'Description for the dark knight',
    isFavorite: false,
  ),
  Film(
    id: '4',
    title: 'The Godfather: Part II',
    desc: 'Description for the godfather part 2',
    isFavorite: false,
  ),
];

class FilmsNotifier extends StateNotifier<List<Film>> {
  FilmsNotifier() : super(allFilms);

  void updateFavorite(Film film, bool isFavorite) {
    state = state
        .map((thisFilm) => thisFilm.id == film.id
            ? thisFilm.copyWith(isFavorite: isFavorite)
            : thisFilm)
        .toList();
  }
}

enum FavoriteStatus { all, favorite, notFavorite }

final favoriteStatusProvider =
    StateProvider<FavoriteStatus>((ref) => FavoriteStatus.all);

final allFilmsProvider = StateNotifierProvider<FilmsNotifier, List<Film>>(
  (ref) => FilmsNotifier(),
);

final favoriteFilmsProvider = Provider<Iterable<Film>>(
  (ref) => ref.watch(allFilmsProvider).where((film) => film.isFavorite),
);

final notFavoriteFilmsProvider = Provider<Iterable<Film>>(
  (ref) => ref.watch(allFilmsProvider).where((film) => !film.isFavorite),
);

class FilmsScreen extends ConsumerWidget {
  const FilmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Films"),
      ),
      body: Column(
        children: [
          FilterWidget(),
          Consumer(builder: (context, ref, child) {
            final filter = ref.watch(favoriteStatusProvider);

            switch (filter) {
              case FavoriteStatus.all:
                return FilmsWidget(provider: allFilmsProvider);
              case FavoriteStatus.favorite:
                return FilmsWidget(provider: favoriteFilmsProvider);
              case FavoriteStatus.notFavorite:
                return FilmsWidget(provider: notFavoriteFilmsProvider);
            }
          })
        ],
      ),
    );
  }
}

class FilmsWidget extends ConsumerWidget {
  final AlwaysAliveProviderBase<Iterable<Film>> provider;

  const FilmsWidget({super.key, required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final films = ref.watch(provider);

    return Expanded(
      child: ListView.builder(
        itemCount: films.length,
        itemBuilder: (context, index) {
          final film = films.elementAt(index);
          final favoriteIcon = film.isFavorite
              ? Icon(Icons.favorite)
              : Icon(Icons.favorite_border);

          return ListTile(
            title: Text(film.title),
            subtitle: Text(film.desc),
            trailing: IconButton(
              icon: favoriteIcon,
              onPressed: () {
                final isFavorite = !film.isFavorite;
                ref
                    .read(allFilmsProvider.notifier)
                    .updateFavorite(film, isFavorite);
              },
            ),
          );
        },
      ),
    );
  }
}

class FilterWidget extends StatelessWidget {
  const FilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      return DropdownButton(
        value: ref.watch(favoriteStatusProvider),
        items: FavoriteStatus.values
            .map(
              (status) => DropdownMenuItem(
                value: status,
                child: Text(status.toString().split('.').last),
              ),
            )
            .toList(),
        onChanged: (value) {
          ref.read(favoriteStatusProvider.notifier).state =
              value as FavoriteStatus;
        },
      );
    });
  }
}
