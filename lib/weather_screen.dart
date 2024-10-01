import 'dart:ui' show FontWeight, ImageFilter;

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/additional_info.dart';
import 'package:weather_app/hourly_forecast.dart';
import 'package:weather_app/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final weather = WeatherService();
  late Position currentPosition;
  Future<Map<String, dynamic>?>? currentWeather;
  bool _locationPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    _handleRefresh();
  }

// Function to handle permission checks and refresh weather data
  Future<void> _handleRefresh() async {
    // Check location permission status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // Request location permission
      permission = await Geolocator.requestPermission();

      // Handle permission denial again
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationPermissionDenied = true;
          Text('Location Permission Denied: $_locationPermissionDenied');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission is required to fetch weather data, please change the permissions manually🙇‍♂️.',
            ),
          ),
        );
        return;
      }
    }

    // If permission is granted, reset the permission denied flag and fetch the weather
    setState(() {
      _locationPermissionDenied = false;
    });

    await _determinePosition();
  }

  Future<void> _determinePosition() async {
    LocationPermission permission;
    permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // Handle denied permission scenario
      print('Location permissions are denied');
      return;
    }

    // Get the current position
    currentPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    List<Placemark> placemarks = await placemarkFromCoordinates(
      currentPosition.latitude,
      currentPosition.longitude,
    );
    String locationName = placemarks.isNotEmpty
        ? '${placemarks[0].locality}, ${placemarks[0].administrativeArea}, ${placemarks[0].country}'
        : 'Unknown Location';

    // Fetch the weather for the current location
    setState(() {
      currentWeather = weather.getCurrentWeather(
        currentPosition.latitude,
        currentPosition.longitude,
      );
      _locationName = locationName;
    });
  }

  String _locationName = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Weather App',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: _handleRefresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: currentWeather,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator.adaptive(),
                SizedBox(
                  height: 10.0,
                ),
                Text('No data available ATM, please wait or refresh.'),
              ],
            ));
          }
          // print('API Data: ${snapshot.data}');

          final data = snapshot.data!;

          if (data['list'] == null || data['list'].isEmpty) {
            return const Center(
              child: Text('Weather data is unavailable.'),
            );
          }

          final currentWeatherData = data['list'][0];

          final currentTemp = (currentWeatherData['main']['temp']);
          final currentTempInCel = currentTemp - 273.15;
          final currentSky = (currentWeatherData['weather'][0]['main']);
          final currentPressure = (currentWeatherData['main']['pressure']);
          final currentWindSpeed = (currentWeatherData['wind']['speed']);
          final currentHumidity = (currentWeatherData['main']['humidity']);

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaY: 10, sigmaX: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                '${currentTempInCel.toStringAsFixed(1)}°C',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              Icon(
                                currentSky == 'Clouds' || currentSky == 'Rain'
                                    ? Icons.cloud
                                    : Icons.sunny,
                                size: 60,
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                currentSky,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 28,
                ),
                const Text(
                  'Hourly Forecasting',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 8.0,
                ),
                SizedBox(
                  height: 105.0,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      final hourlyForecastItem = data['list'][index + 1];
                      final hourlySky =
                          data['list'][index + 1]['weather'][0]['main'];
                      final hourlyTemp = hourlyForecastItem['main']['temp'];
                      final hourlyTempInCel = hourlyTemp - 273.15;
                      final time = DateTime.parse(hourlyForecastItem['dt_txt']);
                      return HourlyForecast(
                          DateFormat.j().format(time),
                          hourlySky == 'Clouds' || hourlySky == 'Rain'
                              ? Icons.cloud
                              : Icons.sunny,
                          hourlyTempInCel.toStringAsFixed(1));
                    },
                  ),
                ),
                const SizedBox(
                  height: 20.0,
                ),
                const Text(
                  'Additional Info',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 16.0,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    AdditionalInfo(Icons.water_drop, 'Humidity',
                        currentHumidity.toString()),
                    AdditionalInfo(
                        Icons.air, 'Pressure', currentPressure.toString()),
                    AdditionalInfo(Icons.beach_access, 'Wind Speed',
                        currentWindSpeed.toString()),
                  ],
                ),
                const SizedBox(height: 40), // Space before location name
                Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      '($_locationName)',
                      textAlign: TextAlign.end,
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}
