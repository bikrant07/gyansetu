class WeatherData {
  final double temperature;
  final double humidity;
  final double rainfall;
  final String description;
  final String icon;
  final String cityName;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.description,
    required this.icon,
    required this.cityName,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['main']['temp'] as num).toDouble(),
      humidity: (json['main']['humidity'] as num).toDouble(),
      rainfall: json['rain']?['1h']?.toDouble() ?? 0.0,
      description: json['weather'][0]['description'] as String,
      icon: json['weather'][0]['icon'] as String,
      cityName: json['name'] as String? ?? 'Unknown Location',
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/w/$icon.png';
}