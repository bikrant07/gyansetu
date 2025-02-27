import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:filesize/filesize.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/transfer_history.dart';

enum SupportedFileType { image, video, audio, document, pdf, archive, other }

class NearbyShareScreen extends StatefulWidget {
  const NearbyShareScreen({super.key});

  @override
  State<NearbyShareScreen> createState() => _NearbyShareScreenState();
}

class _NearbyShareScreenState extends State<NearbyShareScreen> {
  final String userName = Random().nextInt(10000).toString();
  final Strategy strategy = Strategy.P2P_STAR;
  Map<String, ConnectionInfo> endpointMap = {};
  String? tempFileUri;
  Map<int, String> map = {};
  bool isAdvertising = false;
  bool isDiscovering = false;
  Map<int, int> transferProgress = {};
  Map<int, int> transferSpeeds = {};
  Map<int, String> fileNames = {};
  Timer? _speedUpdateTimer;
  Map<int, int> _lastBytesTransferred = {};
  List<PlatformFile>? _pendingFiles;
  bool _isConnecting = false;
  Map<int, int> _totalBytes = {};
  static const String _permissionsGrantedKey = 'nearby_permissions_granted';
  List<TransferHistory> _transferHistory = [];
  static const String _transferHistoryKey = 'transfer_history';

  @override
  void initState() {
    super.initState();
    _checkInitialPermissions();
    _loadTransferHistory();
  }

  @override
  void dispose() {
    _clearAllTransfers();
    _stopAllEndpoints();
    _speedUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final permissionsGranted = prefs.getBool(_permissionsGrantedKey) ?? false;

    if (!permissionsGranted) {
      await _checkAndRequestPermissions();
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    if (await _arePermissionsGranted()) {
      return;
    }

    if (!mounted) return;

    // Get the Android version check result before showing dialog
    final isAndroid13Plus = await _isAndroid13OrHigher();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: Text(
          isAndroid13Plus
              ? 'GyanSetu needs access to photos, videos, and location to enable file sharing. '
                  'Please grant the required permissions in the next screens.'
              : 'GyanSetu needs access to storage and location to enable file sharing. '
                  'Please grant the required permissions in the next screens.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestPermissions();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<bool> _arePermissionsGranted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final permissionsGranted = prefs.getBool(_permissionsGrantedKey) ?? false;

      if (permissionsGranted) return true;

      if (await _isAndroid13OrHigher()) {
        final permissions = await Future.wait([
          Permission.photos.status,
          Permission.videos.status,
          Permission.audio.status,
          Permission.location.status,
          if (await _isAndroid12OrHigher()) ...[
            Permission.bluetoothScan.status,
            Permission.bluetoothConnect.status,
            Permission.bluetoothAdvertise.status,
            Permission.nearbyWifiDevices.status,
          ],
        ]);

        final allGranted = !permissions.any((status) =>
            status.isDenied ||
            status.isPermanentlyDenied ||
            status.isRestricted);

        if (allGranted) {
          await prefs.setBool(_permissionsGrantedKey, true);
        }

        return allGranted;
      } else {
        final permissions = await Future.wait([
          Permission.storage.status,
          Permission.location.status,
          if (await _isAndroid12OrHigher()) ...[
            Permission.bluetoothScan.status,
            Permission.bluetoothConnect.status,
            Permission.bluetoothAdvertise.status,
            Permission.nearbyWifiDevices.status,
          ],
        ]);

        final allGranted = !permissions.any((status) =>
            status.isDenied ||
            status.isPermanentlyDenied ||
            status.isRestricted);

        if (allGranted) {
          await prefs.setBool(_permissionsGrantedKey, true);
        }

        return allGranted;
      }
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return false;
    }
  }

  Future<bool> _isAndroid12OrHigher() async {
    if (Theme.of(context).platform != TargetPlatform.android) return false;
    return await Permission.bluetoothScan.status != PermissionStatus.restricted;
  }

  Future<bool> _isAndroid13OrHigher() async {
    if (Theme.of(context).platform != TargetPlatform.android) return false;
    return await Permission.photos.status != PermissionStatus.restricted;
  }

  Future<void> _requestPermissions() async {
    try {
      // Create lists to store permissions that need to be requested
      List<Permission> permissionsToRequest = [];

      if (await _isAndroid13OrHigher()) {
        // Check each permission individually for Android 13+
        if (await Permission.photos.status.isDenied) {
          permissionsToRequest.add(Permission.photos);
        }
        if (await Permission.videos.status.isDenied) {
          permissionsToRequest.add(Permission.videos);
        }
        if (await Permission.audio.status.isDenied) {
          permissionsToRequest.add(Permission.audio);
        }
        if (await Permission.location.status.isDenied) {
          permissionsToRequest.add(Permission.location);
        }
      } else {
        // Check storage permission for older Android versions
        if (await Permission.storage.status.isDenied) {
          permissionsToRequest.add(Permission.storage);
        }
        if (await Permission.location.status.isDenied) {
          permissionsToRequest.add(Permission.location);
        }
      }

      // Check Bluetooth permissions for Android 12+
      if (await _isAndroid12OrHigher()) {
        if (await Permission.bluetoothScan.status.isDenied) {
          permissionsToRequest.add(Permission.bluetoothScan);
        }
        if (await Permission.bluetoothConnect.status.isDenied) {
          permissionsToRequest.add(Permission.bluetoothConnect);
        }
        if (await Permission.bluetoothAdvertise.status.isDenied) {
          permissionsToRequest.add(Permission.bluetoothAdvertise);
        }
        if (await Permission.nearbyWifiDevices.status.isDenied) {
          permissionsToRequest.add(Permission.nearbyWifiDevices);
        }
      }

      // Only request permissions that are not already granted
      if (permissionsToRequest.isNotEmpty) {
        await Future.forEach(permissionsToRequest,
            (Permission permission) async {
          await permission.request();
          // Add a small delay between requests to prevent conflicts
          await Future.delayed(const Duration(milliseconds: 100));
        });
      }

      // Check if any permission is permanently denied
      final permanentlyDenied = await _checkPermanentlyDeniedPermissions();
      if (permanentlyDenied.isNotEmpty && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissions Required'),
            content: Text(
              'The following permissions are permanently denied: '
              '${permanentlyDenied.join(", ")}. '
              'Please enable them in Settings to use file sharing.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showSnackbar('Error requesting permissions: $e');
    }
  }

  Future<List<String>> _checkPermanentlyDeniedPermissions() async {
    List<String> permanentlyDenied = [];

    if (await _isAndroid13OrHigher()) {
      if (await Permission.photos.isPermanentlyDenied) {
        permanentlyDenied.add('Photos');
      }
      if (await Permission.videos.isPermanentlyDenied) {
        permanentlyDenied.add('Videos');
      }
      if (await Permission.audio.isPermanentlyDenied) {
        permanentlyDenied.add('Audio');
      }
    } else {
      if (await Permission.storage.isPermanentlyDenied) {
        permanentlyDenied.add('Storage');
      }
    }

    if (await Permission.location.isPermanentlyDenied) {
      permanentlyDenied.add('Location');
    }

    if (await _isAndroid12OrHigher()) {
      if (await Permission.bluetoothScan.isPermanentlyDenied) {
        permanentlyDenied.add('Bluetooth Scan');
      }
      if (await Permission.bluetoothConnect.isPermanentlyDenied) {
        permanentlyDenied.add('Bluetooth Connect');
      }
      if (await Permission.bluetoothAdvertise.isPermanentlyDenied) {
        permanentlyDenied.add('Bluetooth Advertise');
      }
      if (await Permission.nearbyWifiDevices.isPermanentlyDenied) {
        permanentlyDenied.add('Nearby Devices');
      }
    }

    return permanentlyDenied;
  }

  // Update the _checkPermissions method to use the new permission handling
  Future<bool> _checkPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final permissionsGranted = prefs.getBool(_permissionsGrantedKey) ?? false;

    if (permissionsGranted) return true;

    if (await _arePermissionsGranted()) {
      return true;
    }

    await _checkAndRequestPermissions();
    return await _arePermissionsGranted();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: WillPopScope(
        onWillPop: () async {
          _clearAllTransfers();
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Gyan Share'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Share'),
                Tab(text: 'History'),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
            ),
          ),
          body: TabBarView(
            children: [
              // First tab - existing sharing interface
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          Colors.white,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: _buildOptions(),
                        ),
                        if (isAdvertising || isDiscovering)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: SizedBox(
                              height: 130,
                              child: _buildStatusCard(),
                            ),
                          ),
                        if (transferProgress.isNotEmpty)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: _buildTransfersList(),
                            ),
                          ),
                        // Add empty space at bottom if no transfers
                        if (transferProgress.isEmpty)
                          const Expanded(child: SizedBox()),
                      ],
                    ),
                  ),
                  if (_isConnecting)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'Connecting...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              // Second tab - transfer history
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildTransferHistory(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildOptionCard(
          icon: Icons.upload_file,
          title: 'Share',
          onTap: _startSharing,
          isActive: isAdvertising,
        ),
        _buildOptionCard(
          icon: Icons.download,
          title: 'Receive',
          onTap: _startReceiving,
          isActive: isDiscovering,
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isActive
                      ? [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.8),
                        ]
                      : [
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                        ],
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isActive
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isAdvertising ? Icons.share : Icons.search,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isAdvertising
                              ? 'Sharing Active'
                              : 'Discovering Devices',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Connected devices: ${endpointMap.length}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Center(
                    child: SizedBox(
                      height: 32,
                      child: ElevatedButton.icon(
                        onPressed: _stopAllEndpoints,
                        icon: const Icon(Icons.stop, size: 16),
                        label: const Text(
                          'Stop',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (endpointMap.isNotEmpty) ...[
              const Divider(height: 16),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 70),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connected Devices:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...endpointMap.entries.map((entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.devices, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      entry.value.endpointName,
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransfersList() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'File Transfers',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: transferProgress.length,
              itemBuilder: (context, index) {
                final payloadId = transferProgress.keys.elementAt(index);
                final bytesTransferred = transferProgress[payloadId] ?? 0;
                final speed = transferSpeeds[payloadId] ?? 0;
                final fileName = fileNames[payloadId] ?? 'Unknown file';

                return _buildTransferListItem(
                    payloadId, bytesTransferred, speed, fileName);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferListItem(
    int payloadId,
    int bytesTransferred,
    int speed,
    String fileName,
  ) {
    final totalBytes = _totalBytes[payloadId] ?? 1;
    final progress = bytesTransferred / totalBytes;
    final progressPercent = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularPercentIndicator(
              radius: 18.0,
              lineWidth: 3.0,
              percent: progressPercent,
              center: Text(
                '${(progressPercent * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 10),
              ),
              progressColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            _getFileTypeIcon(_getFileType(fileName)),
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${filesize(bytesTransferred)} / ${filesize(totalBytes)} • ${filesize(speed)}/s',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Update the speed monitoring method
  void _startSpeedMonitoring() {
    _speedUpdateTimer?.cancel();
    _speedUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (transferProgress.isEmpty) {
        timer.cancel();
        return;
      }

      setState(() {
        for (var entry in _lastBytesTransferred.entries) {
          final currentBytes = transferProgress[entry.key] ?? 0;
          final lastBytes = entry.value;
          // Calculate speed in bytes per second
          transferSpeeds[entry.key] = (currentBytes - lastBytes);
          _lastBytesTransferred[entry.key] = currentBytes;
        }
      });
    });
  }

  // Update payload handling method
  void _onPayloadTransferUpdate(
      String endid, PayloadTransferUpdate update) async {
    if (!mounted) return;

    debugPrint(
        "Transfer update - ID: ${update.id}, Bytes: ${update.bytesTransferred}/${update.totalBytes}, Status: ${update.status}");

    setState(() {
      final bytesTransferred = update.bytesTransferred.toInt();
      transferProgress[update.id] = bytesTransferred;
      _totalBytes[update.id] = update.totalBytes.toInt();

      if (!_lastBytesTransferred.containsKey(update.id)) {
        _lastBytesTransferred[update.id] = 0;
        _startSpeedMonitoring();
      }

      // Handle different payload statuses
      switch (update.status) {
        case PayloadStatus.SUCCESS:
          debugPrint("Transfer successful for ID: ${update.id}");
          if (map.containsKey(update.id)) {
            String fileName = map[update.id]!;
            debugPrint("Found filename for successful transfer: $fileName");
            if (tempFileUri != null) {
              _moveFile(tempFileUri!, fileName);
            }
            _addToTransferHistory(
              fileName: fileName,
              totalBytes: update.totalBytes.toInt(),
              isSuccess: true,
              isSender: isAdvertising,
            );
            _removeTransfer(update.id);
          }
          break;

        case PayloadStatus.FAILURE:
          debugPrint("Transfer failed for ID: ${update.id}");
          _showSnackbar(
              "Failed to transfer: ${fileNames[update.id] ?? 'Unknown file'}");
          _removeTransfer(update.id);
          break;

        case PayloadStatus.CANCELED:
          debugPrint("Transfer canceled for ID: ${update.id}");
          _showSnackbar(
              "Transfer canceled: ${fileNames[update.id] ?? 'Unknown file'}");
          _removeTransfer(update.id);
          break;

        case PayloadStatus.IN_PROGRESS:
          // Continue tracking progress
          break;

        case PayloadStatus.NONE:
          // Initial state, no action needed
          break;
      }
    });
  }

  // Add this helper method to remove a transfer
  void _removeTransfer(int payloadId) {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          transferProgress.remove(payloadId);
          transferSpeeds.remove(payloadId);
          _lastBytesTransferred.remove(payloadId);
          fileNames.remove(payloadId);
          map.remove(payloadId);
          _totalBytes.remove(payloadId);

          // If no more transfers, reset states
          if (transferProgress.isEmpty) {
            isAdvertising = false;
            isDiscovering = false;
            _isConnecting = false;
          }
        });
      }
    });
  }

  // Update file sending method
  Future<void> _startSharing() async {
    if (!await _checkPermissions()) {
      _showSnackbar('Required permissions not granted');
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          // Images
          'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp',
          // Videos
          'mp4', 'mkv', 'avi', 'mov', '3gp', 'webm',
          // Audio
          'mp3', 'wav', 'aac', 'm4a', 'ogg',
          // Documents
          'doc', 'docx', 'txt', 'rtf', 'xlsx', 'xls', 'ppt', 'pptx',
          // PDF
          'pdf',
          // Archives
          'zip', 'rar', '7z', 'tar', 'gz'
        ],
      );

      if (result == null) return;

      // If already connected to devices, send files directly
      if (endpointMap.isNotEmpty) {
        for (var endpoint in endpointMap.entries) {
          await _sendPendingFilesToEndpoint(endpoint.key, result.files);
        }
        return;
      }

      // Otherwise, start advertising and store files
      setState(() {
        _pendingFiles = result.files;
        _isConnecting = true;
      });

      // Stop any existing advertising
      await Nearby().stopAdvertising();

      bool advertisingStarted = await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: _onConnectionInit,
        onConnectionResult: (id, status) {
          debugPrint("Connection result: $status for id: $id");
          if (status == Status.CONNECTED) {
            _sendPendingFilesToEndpoint(id, _pendingFiles!);
          } else {
            _showSnackbar("Connection failed: $status");
            setState(() => _isConnecting = false);
          }
        },
        onDisconnected: (id) {
          setState(() {
            endpointMap.remove(id);
            _isConnecting = false;
          });
          _showSnackbar("Disconnected: ${endpointMap[id]?.endpointName}");
        },
      ).catchError((e) {
        _showSnackbar("Error starting advertising: $e");
        setState(() => _isConnecting = false);
        return false;
      });

      if (advertisingStarted) {
        setState(() => isAdvertising = true);
        _showSnackbar("Waiting for receiver to connect...");
      } else {
        setState(() {
          _pendingFiles = null;
          _isConnecting = false;
        });
      }
    } catch (e) {
      setState(() {
        _pendingFiles = null;
        _isConnecting = false;
      });
      _showSnackbar("Error: $e");
    }
  }

  Future<void> _sendPendingFilesToEndpoint(
      String endpointId, List<PlatformFile> files) async {
    try {
      setState(() {
        _isConnecting = false; // Hide connecting dialog
        isAdvertising = true; // Show status card
      });

      for (var file in files) {
        if (file.path == null) continue;

        debugPrint("Sending file: ${file.name}");
        int payloadId = await Nearby().sendFilePayload(
          endpointId,
          file.path!,
        );

        setState(() {
          fileNames[payloadId] = file.name;
          transferProgress[payloadId] = 0;
          transferSpeeds[payloadId] = 0;
          _lastBytesTransferred[payloadId] = 0;
          map[payloadId] = file.name;
        });

        _startSpeedMonitoring();

        await Nearby().sendBytesPayload(
          endpointId,
          Uint8List.fromList(
            "$payloadId:${file.name}".codeUnits,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        isAdvertising = false;
      });
      _showSnackbar("Error sending files: $e");
    }
  }

  Future<void> _startReceiving() async {
    if (!await _checkPermissions()) {
      _showSnackbar('Required permissions not granted');
      return;
    }

    // Stop any existing advertising or discovery
    await _stopAllEndpoints();

    try {
      bool discoveryStarted = await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          _showConnectionRequest(id, name);
        },
        onEndpointLost: (id) {
          _showSnackbar("Lost endpoint: ${endpointMap[id]?.endpointName}");
        },
      ).catchError((e) {
        _showSnackbar("Error starting discovery: $e");
        return false;
      });

      if (discoveryStarted) {
        setState(() => isDiscovering = true);
        _showSnackbar("Discovery started");
      }
    } catch (e) {
      _showSnackbar("Error: $e");
    }
  }

  Future<void> _stopAllEndpoints() async {
    try {
      await Nearby().stopAllEndpoints();
      await Nearby().stopAdvertising();
      await Nearby().stopDiscovery();

      _clearAllTransfers();

      // Reset permissions if there was an error
      if (!await _arePermissionsGranted()) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_permissionsGrantedKey, false);
      }
    } catch (e) {
      _showSnackbar("Error stopping endpoints: $e");
    }
  }

  void _onConnectionInit(String id, ConnectionInfo info) {
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Connection Request",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text("From: ${info.endpointName}"),
              Text("Authentication Token: ${info.authenticationToken}"),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _rejectConnection(id);
                    },
                    child: const Text("Reject"),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _acceptConnection(id, info);
                    },
                    child: const Text("Accept"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _acceptConnection(String id, ConnectionInfo info) async {
    try {
      setState(() => endpointMap[id] = info);

      await Nearby().acceptConnection(
        id,
        onPayLoadRecieved: _onPayloadReceived,
        onPayloadTransferUpdate: _onPayloadTransferUpdate,
      );

      _showSnackbar("Connected to ${info.endpointName}");
    } catch (e) {
      _showSnackbar("Error accepting connection: $e");
    }
  }

  Future<void> _rejectConnection(String id) async {
    try {
      await Nearby().rejectConnection(id);
    } catch (e) {
      _showSnackbar("Error rejecting connection: $e");
    }
  }

  void _onPayloadReceived(String endid, Payload payload) async {
    try {
      if (payload.type == PayloadType.BYTES) {
        String str = String.fromCharCodes(payload.bytes!);
        debugPrint("Received bytes payload: $str");
        if (str.contains(':')) {
          int payloadId = int.parse(str.split(':')[0]);
          String fileName = str.split(':')[1];
          setState(() {
            map[payloadId] = fileName;
            fileNames[payloadId] = fileName;
            isDiscovering = true; // Show status card for receiver
          });
          debugPrint("Stored filename for payloadId $payloadId: $fileName");
        }
      } else if (payload.type == PayloadType.FILE) {
        debugPrint("Received file payload with uri: ${payload.uri}");
        tempFileUri = payload.uri;
      }
    } catch (e) {
      debugPrint("Error in _onPayloadReceived: $e");
    }
  }

  Future<bool> _moveFile(String uri, String fileName) async {
    try {
      // Get the Downloads directory path
      final directory = await _getDownloadsDirectory();
      if (directory == null) {
        _showSnackbar("Could not access Downloads directory");
        return false;
      }

      // Create a GyanSetu folder in Downloads
      final gyansetuDir = Directory('${directory.path}/GyanSetu');
      if (!await gyansetuDir.exists()) {
        await gyansetuDir.create(recursive: true);
      }

      final success = await Nearby().copyFileAndDeleteOriginal(
        uri,
        '${gyansetuDir.path}/$fileName',
      );

      if (success) {
        _showSnackbar(
          "File saved in Downloads/GyanSetu folder: $fileName",
        );
      } else {
        _showSnackbar("Error saving file");
      }
      return success;
    } catch (e) {
      _showSnackbar("Error moving file: $e");
      return false;
    }
  }

  Future<Directory?> _getDownloadsDirectory() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      return Directory('/storage/emulated/0/Download');
    }
    return await getExternalStorageDirectory();
  }

  void _showSnackbar(dynamic message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.toString())),
    );
  }

  void _showConnectionRequest(String id, String name) {
    // Don't show request if already connected to this device
    if (endpointMap.values.any((info) => info.endpointName == name)) {
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Device Found",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text("Name: $name"),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _requestConnection(id);
                    },
                    child: const Text("Connect"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _requestConnection(String id) async {
    try {
      await Nearby().requestConnection(
        userName,
        id,
        onConnectionInitiated: _onConnectionInit,
        onConnectionResult: (id, status) => _showSnackbar(status),
        onDisconnected: (id) {
          setState(() => endpointMap.remove(id));
          _showSnackbar("Disconnected from: ${endpointMap[id]?.endpointName}");
        },
      );
    } catch (e) {
      _showSnackbar("Error requesting connection: $e");
    }
  }

  SupportedFileType _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      // Images
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
        return SupportedFileType.image;

      // Videos
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'mov':
      case '3gp':
      case 'webm':
        return SupportedFileType.video;

      // Audio
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'm4a':
      case 'ogg':
        return SupportedFileType.audio;

      // Documents
      case 'doc':
      case 'docx':
      case 'txt':
      case 'rtf':
      case 'xlsx':
      case 'xls':
      case 'ppt':
      case 'pptx':
        return SupportedFileType.document;

      // PDF
      case 'pdf':
        return SupportedFileType.pdf;

      // Archives
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return SupportedFileType.archive;

      default:
        return SupportedFileType.other;
    }
  }

  IconData _getFileTypeIcon(SupportedFileType type) {
    switch (type) {
      case SupportedFileType.image:
        return Icons.image;
      case SupportedFileType.video:
        return Icons.video_file;
      case SupportedFileType.audio:
        return Icons.audio_file;
      case SupportedFileType.document:
        return Icons.description;
      case SupportedFileType.pdf:
        return Icons.picture_as_pdf;
      case SupportedFileType.archive:
        return Icons.folder_zip;
      case SupportedFileType.other:
        return Icons.insert_drive_file;
    }
  }

  // Add this new method to clear transfer history
  void _clearAllTransfers() {
    setState(() {
      transferProgress.clear();
      transferSpeeds.clear();
      _lastBytesTransferred.clear();
      fileNames.clear();
      map.clear();
      _totalBytes.clear();
      _pendingFiles = null;
      _isConnecting = false;
      isAdvertising = false;
      isDiscovering = false;
    });
  }

  // Add this method to load transfer history
  Future<void> _loadTransferHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_transferHistoryKey) ?? [];
    setState(() {
      _transferHistory = historyJson
          .map((item) => TransferHistory.fromJson(json.decode(item)))
          .toList();
    });
  }

  // Add this method to save transfer history
  Future<void> _saveTransferHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _transferHistory
        .map((item) => json.encode(item.toJson()))
        .toList();
    await prefs.setStringList(_transferHistoryKey, historyJson);
  }

  // Add this method to add a transfer to history
  void _addToTransferHistory({
    required String fileName,
    required int totalBytes,
    required bool isSuccess,
    required bool isSender,
  }) {
    setState(() {
      _transferHistory.insert(
        0,
        TransferHistory(
          fileName: fileName,
          totalBytes: totalBytes,
          timestamp: DateTime.now(),
          isSuccess: isSuccess,
          isSender: isSender,
        ),
      );
    });
    _saveTransferHistory();
  }

  // Add this method to remove a transfer from history
  void _removeFromHistory(int index) {
    setState(() {
      _transferHistory.removeAt(index);
    });
    _saveTransferHistory();
  }

  // Add this method to build the transfer history section
  Widget _buildTransferHistory() {
    if (_transferHistory.isEmpty) {
      return const Center(
        child: Text('No transfer history'),
      );
    }

    return ListView.builder(
      itemCount: _transferHistory.length,
      itemBuilder: (context, index) {
        final history = _transferHistory[index];
        return ListTile(
          leading: Icon(
            _getFileTypeIcon(_getFileType(history.fileName)),
            color: history.isSuccess ? Colors.green : Colors.red,
          ),
          title: Text(
            history.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${history.isSuccess ? 'Completed' : 'Failed'} • ${filesize(history.totalBytes)}\n'
            '${_formatTimestamp(history.timestamp)}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                history.isSender ? Icons.upload : Icons.download,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _removeFromHistory(index),
                color: Colors.grey,
              ),
            ],
          ),
        );
      },
    );
  }

  // Add this helper method to format timestamps
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
