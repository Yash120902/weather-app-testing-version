import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:weather_app/secret.dart';

class WeatherService {
  Future<Map<String, dynamic>?> getCurrentWeather(
      double lat, double lon) async {
    try {
      final url = Uri.parse(
        'http://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&APPID=$openWeatherAPIKey',
      );
      final res = await http.get(url);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        print(data);
        return data;
      } else {
        print('Failed to fetch data');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error Code: $e');
      print(('Stack Trace: $stackTrace'));
      return null;
    }
  }
}
