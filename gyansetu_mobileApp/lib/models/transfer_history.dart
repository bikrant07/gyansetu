import 'dart:convert';

class TransferHistory {
  final String fileName;
  final int totalBytes;
  final DateTime timestamp;
  final bool isSuccess;
  final bool isSender;

  TransferHistory({
    required this.fileName,
    required this.totalBytes,
    required this.timestamp,
    required this.isSuccess,
    required this.isSender,
  });

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'totalBytes': totalBytes,
        'timestamp': timestamp.toIso8601String(),
        'isSuccess': isSuccess,
        'isSender': isSender,
      };

  factory TransferHistory.fromJson(Map<String, dynamic> json) => TransferHistory(
        fileName: json['fileName'],
        totalBytes: json['totalBytes'],
        timestamp: DateTime.parse(json['timestamp']),
        isSuccess: json['isSuccess'],
        isSender: json['isSender'],
      );
} 