import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gyansetu_client/models/weather_data.dart';
import 'package:gyansetu_client/widgets/weather_widget.dart';
import 'package:gyansetu_client/screens/agriculture_page.dart';
import 'package:gyansetu_client/screens/fish_farming_page.dart';
import 'package:gyansetu_client/screens/poultry_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KrishiPage extends StatefulWidget {
  const KrishiPage({Key? key}) : super(key: key);

  @override
  _KrishiPageState createState() => _KrishiPageState();
}

class _KrishiPageState extends State<KrishiPage> {
  WeatherData? _weatherData;
  bool _isLoading = true;
  String _errorMessage = '';
  final String _openWeatherApiKey = '479df8e329f14dcdc0c751885f9015c0';
  
  // Add these constants
  static const String _weatherCacheKey = 'weather_data';
  static const String _weatherTimestampKey = 'weather_timestamp';
  static const Duration _cacheExpiration = Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_weatherCacheKey);
      final cachedTimestamp = prefs.getInt(_weatherTimestampKey);

      if (cachedData != null && cachedTimestamp != null) {
        final timestamp = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
        final now = DateTime.now();
        final difference = now.difference(timestamp);

        if (difference < _cacheExpiration) {
          // Use cached data if it's not expired
          setState(() {
            _weatherData = WeatherData.fromJson(json.decode(cachedData));
            _isLoading = false;
            _errorMessage = '';
          });
          return;
        }
      }

      // If no cached data or cache expired, fetch new data
      await _initializeLocation();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading weather data: ${e.toString()}';
      });
    }
  }

  Future<void> _cacheWeatherData(Map<String, dynamic> weatherJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_weatherCacheKey, json.encode(weatherJson));
      await prefs.setInt(_weatherTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching weather data: ${e.toString()}');
    }
  }

  Future<void> _fetchWeatherData(double lat, double lon) async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_openWeatherApiKey&units=metric'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Cache the response data
        await _cacheWeatherData(data);
        
        setState(() {
          _weatherData = WeatherData.fromJson(data);
          _isLoading = false;
          _errorMessage = '';
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to fetch weather data: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching weather data: ${e.toString()}';
      });
    }
  }

  // Update the refresh method to clear cache
  Future<void> _refreshWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clear cached data
      await prefs.remove(_weatherCacheKey);
      await prefs.remove(_weatherTimestampKey);
      
      // Fetch new data
      await _initializeLocation();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error refreshing weather data: ${e.toString()}';
      });
    }
  }

  Future<void> _initializeLocation() async {
    try {
      final location = Location();
      bool serviceEnabled;
      PermissionStatus permissionGranted;

      // Check if location services are enabled
      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Location services are disabled';
          });
          return;
        }
      }

      // Check location permissions
      permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Location permission denied';
          });
          return;
        }
      }

      // Get location and fetch weather data
      final locationData = await location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        await _fetchWeatherData(locationData.latitude!, locationData.longitude!);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to get location';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.krishiTitle ?? 'Krishi'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshWeatherData,  // Updated to use new refresh method
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weather Widget
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else if (_weatherData != null)
                WeatherWidget(weatherData: _weatherData!),

              // Main Categories
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildCategoryCard(
                      context,
                      'agriculture',
                      AppLocalizations.of(context)?.agriculture ?? 'Agriculture',
                      Icons.eco,
                      Colors.green,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AgriculturePage(),
                        ),
                      ),
                    ),
                    _buildCategoryCard(
                      context,
                      'fishFarming',
                      AppLocalizations.of(context)?.fishFarming ?? 'Fish Farming',
                      Icons.water,
                      Colors.blue,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FishFarmingPage(),
                        ),
                      ),
                    ),
                    _buildCategoryCard(
                      context,
                      'poultryFarming',
                      AppLocalizations.of(context)?.poultryFarming ?? 'Poultry Farming',
                      Icons.pets,
                      Colors.orange,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PoultryPage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String key,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.7),
                color.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
