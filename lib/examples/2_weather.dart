import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum City {
  stockholm,
  paris,
  tokyo,
}

typedef WeatherEmoji = String;

Future<WeatherEmoji> getWeather(City city) {
  switch (city) {
    case City.stockholm:
      return Future.delayed(Duration(seconds: 1), () => "☀️");
    case City.paris:
      return Future.delayed(Duration(seconds: 2), () => "☁️");
    case City.tokyo:
      return Future.delayed(Duration(seconds: 3), () => "☔️");
  }
}

// UI writes to this to change the city.
final currentCityProvider = StateProvider<City?>((ref) => null);

// UI reads this to display the weather.
final weatherProvider = FutureProvider<WeatherEmoji>((ref) {
  final city = ref.watch(currentCityProvider);
  if (city != null) {
    return getWeather(city);
  } else {
    return "🤷‍♂️";
  }
});

class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentWeather = ref.watch(weatherProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Weather"),
      ),
      body: Column(
        children: [
          currentWeather.when(
            data: (data) {
              return Text(
                data,
                style: Theme.of(context).textTheme.displayLarge,
              );
            },
            error: (error, stackTrace) => Text(
              "Error: $error",
              style: Theme.of(context).textTheme.displayLarge,
            ),
            loading: () => Padding(
              padding: const EdgeInsets.all(40.0),
              child: const CircularProgressIndicator(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: City.values.length,
              itemBuilder: (context, index) {
                final city = City.values[index];
                final isSelected = city == ref.watch(currentCityProvider);

                return ListTile(
                  title: Text(city.toString()),
                  trailing: isSelected ? Icon(Icons.check) : null,
                  onTap: () =>
                      ref.read(currentCityProvider.notifier).state = city,
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
