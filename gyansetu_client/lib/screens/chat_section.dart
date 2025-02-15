import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ChatSection extends StatefulWidget {
  const ChatSection({super.key});

  @override
  State<ChatSection> createState() => _ChatSectionState();
}

class _ChatSectionState extends State<ChatSection>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _currentUserProfileName = '';
  bool _isUserNameLoaded = false;
  bool _hasUnreadMessages = false;

  static const int _timeGapThreshold = 120000; // 2 minutes in milliseconds

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final _publicMessagesController = StreamController<DatabaseEvent>.broadcast();
  final _usersController = BehaviorSubject<List<QuerySnapshot>>();

  StreamSubscription? _publicMessagesSubscription;
  StreamSubscription? _usersSubscription;

  List<MapEntry<dynamic, dynamic>>? _cachedPublicMessages;
  bool _isPublicMessagesLoaded = false;

  Map<String, StreamSubscription?> _privateMessageSubscriptions = {};

  List<UserData> _cachedUsers = [];
  bool _isUsersLoaded = false;

  final FocusNode _searchFocusNode = FocusNode();

  List<UserData>? _sortedUsers;
  bool _isLoadingSortedUsers = false;

  final Map<String, List<MapEntry<dynamic, dynamic>>> _cachedPrivateMessages = {};

  late SharedPreferences _preferences;
  static const String _publicMessagesCacheKey = 'public_messages_cache';
  static const String _privateMessagesCacheKey = 'private_messages_cache';
  static const String _usersCacheKey = 'users_cache';

  bool _isOnline = true;
  final List<Map<String, dynamic>> _offlineMessageQueue = [];
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initializePreferences().then((_) {
      if (mounted) {
        setState(() {
          // Initialization complete
        });
      }
    });
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      _clearSearchFocus();
    });
    _fetchCurrentUserName();
    _initializeStreams();
    _initializeConnectivityListener();
    _checkUnreadMessages();
  }

  void _checkUnreadMessages() {
    // Listen for private messages
    _dbRef.child('messages/private').onValue.listen((event) {
      if (!mounted) return;
      
      if (event.snapshot.value != null) {
        final messages = event.snapshot.value as Map<dynamic, dynamic>;
        bool hasUnread = false;
        
        for (var chatRoom in messages.values) {
          if (chatRoom is Map) {
            for (var message in chatRoom.values) {
              if (message is Map &&
                  message['userId'] != _currentUserId &&
                  !(message['read'] ?? false)) {
                hasUnread = true;
                break;
              }
            }
          }
          if (hasUnread) break;
        }
        
        setState(() {
          _hasUnreadMessages = hasUnread;
        });
      }
    });

    // Listen for public messages
    _dbRef.child('messages/public')
        .orderByChild('timestamp')
        .limitToLast(1)
        .onValue
        .listen((event) {
      if (!mounted) return;
      
      if (event.snapshot.value != null) {
        final message = (event.snapshot.value as Map<dynamic, dynamic>)
            .values
            .first as Map<dynamic, dynamic>;
            
        if (message['userId'] != _currentUserId) {
          setState(() {
            _hasUnreadMessages = true;
          });
        }
      }
    });
  }

  Future<void> _initializePreferences() async {
    _preferences = await SharedPreferences.getInstance();
    await _loadCachedData();
  }

  Future<void> _loadCachedData() async {
    if (_preferences == null) return;

    // Load cached public messages
    final cachedPublicMessages =
        _preferences?.getString(_publicMessagesCacheKey);
    if (cachedPublicMessages != null) {
      try {
        final decodedMessages = json.decode(cachedPublicMessages);
        setState(() {
          _cachedPublicMessages = List<MapEntry<dynamic, dynamic>>.from(
            (decodedMessages as List).map((item) => MapEntry(
                  item['key'],
                  item['value'],
                )),
          );
          _isPublicMessagesLoaded = true;
        });
      } catch (e) {
        debugPrint('Error loading cached public messages: $e');
      }
    }

    // Load cached users
    final cachedUsers = _preferences?.getString(_usersCacheKey);
    if (cachedUsers != null) {
      try {
        final decodedUsers = json.decode(cachedUsers);
        setState(() {
          _cachedUsers = List<UserData>.from(
            (decodedUsers as List).map((item) => UserData(
                  id: item['id'],
                  name: item['name'],
                  profilePicture: item['profilePicture'],
                  email: item['email'],
                  lastMessage: item['lastMessage'],
                  lastMessageTimestamp: item['lastMessageTimestamp'],
                )),
          );
          _isUsersLoaded = true;
        });
      } catch (e) {
        debugPrint('Error loading cached users: $e');
      }
    }

    // Load cached private messages
    final cachedPrivateMessages =
        _preferences?.getString(_privateMessagesCacheKey);
    if (cachedPrivateMessages != null) {
      try {
        final decodedMessages = json.decode(cachedPrivateMessages);
        _cachedPrivateMessages.clear();
        (decodedMessages as Map<String, dynamic>).forEach((key, value) {
          _cachedPrivateMessages[key] = List<MapEntry<dynamic, dynamic>>.from(
            (value as List).map((item) => MapEntry(
                  item['key'],
                  item['value'],
                )),
          );
        });
      } catch (e) {
        debugPrint('Error loading cached private messages: $e');
      }
    }
  }

  void _clearSearchFocus() {
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  void _initializeStreams() {
    debugPrint('\nInitializing streams:');
    debugPrint('Current user ID: $_currentUserId');

    // Public messages stream
    _publicMessagesSubscription =
        _dbRef.child('messages/public').onValue.listen(
      (event) {
        debugPrint('Received public messages update');
        _publicMessagesController.add(event);

        // Cache public messages
        if (event.snapshot.value != null) {
          try {
            final messages = _processPublicMessages(event.snapshot.value);
            _preferences?.setString(
              _publicMessagesCacheKey,
              json.encode(messages
                  .map((entry) => {
                        'key': entry.key,
                        'value': entry.value,
                      })
                  .toList()),
            );
          } catch (e) {
            debugPrint('Error caching public messages: $e');
          }
        }
      },
      onError: (error) => debugPrint('Public messages error: $error'),
    );

    // Firestore users and admins stream
    try {
      debugPrint('Setting up Firestore streams...');

      _usersSubscription = CombineLatestStream.list<QuerySnapshot>([
        FirebaseFirestore.instance.collection('users').snapshots(),
        FirebaseFirestore.instance.collection('admins').snapshots(),
      ]).listen(
        (snapshots) {
          debugPrint('\nReceived Firestore snapshots:');
          debugPrint('Users count: ${snapshots[0].docs.length}');
          debugPrint('Admins count: ${snapshots[1].docs.length}');

          // Process users data
          List<UserData> allUsers = [];

          // Process users collection
          for (var doc in snapshots[0].docs) {
            if (doc.id != _currentUserId) {
              final data = doc.data() as Map<String, dynamic>;
              allUsers.add(UserData(
                id: doc.id,
                name: data['profileName'] ?? data['name'] ?? 'Unknown User',
                profilePicture: data['profileImageUrl'],
                email: data['email'],
              ));
            }
          }

          // Process admins collection
          for (var doc in snapshots[1].docs) {
            if (doc.id != _currentUserId) {
              final data = doc.data() as Map<String, dynamic>;
              allUsers.add(UserData(
                id: doc.id,
                name: data['profileName'] ?? data['name'] ?? 'Unknown Admin',
                profilePicture: data['profileImageUrl'],
                email: data['email'],
              ));
            }
          }

          if (mounted) {
            setState(() {
              _cachedUsers = allUsers;
              _isUsersLoaded = true;
            });
          }

          if (!_usersController.isClosed) {
            _usersController.add(snapshots);
          }

          // Cache users
          if (_cachedUsers.isNotEmpty) {
            try {
              _preferences?.setString(
                _usersCacheKey,
                json.encode(_cachedUsers
                    .map((user) => {
                          'id': user.id,
                          'name': user.name,
                          'profilePicture': user.profilePicture,
                          'email': user.email,
                          'lastMessage': user.lastMessage,
                          'lastMessageTimestamp': user.lastMessageTimestamp,
                        })
                    .toList()),
              );
            } catch (e) {
              debugPrint('Error caching users: $e');
            }
          }
        },
        onError: (error) {
          debugPrint('\nFirestore stream error: $error');
          if (!_usersController.isClosed) {
            _usersController.addError(error);
          }
        },
      );

      debugPrint('Streams setup completed');
    } catch (e) {
      debugPrint('\nError setting up streams: $e');
    }
  }

  void _initializeConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      final wasOnline = _isOnline;
      final isOnline = result != ConnectivityResult.none;
      
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }

      // If coming back online, process offline message queue
      if (!wasOnline && isOnline) {
        _processOfflineMessageQueue();
      }
    });

    // Check initial connectivity
    Connectivity().checkConnectivity().then((result) {
      if (mounted) {
        setState(() {
          _isOnline = result != ConnectivityResult.none;
        });
      }
    });
  }

  Future<void> _processOfflineMessageQueue() async {
    if (_offlineMessageQueue.isEmpty) return;

    for (final message in List.from(_offlineMessageQueue)) {
      try {
        if (message['type'] == 'public') {
          await _dbRef.child('messages/public').push().set(message['data']);
        } else if (message['type'] == 'private') {
          final chatRoomId = message['chatRoomId'];
          await _dbRef.child('messages/private/$chatRoomId').push().set(message['data']);
        }
        _offlineMessageQueue.remove(message);
      } catch (e) {
        debugPrint('Error processing offline message: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Chat'),
            if (!_isOnline)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[400],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Public Chat'),
            Tab(text: 'Private Chats'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPublicChat(),
          _buildPrivateChats(),
        ],
      ),
    );
  }

  Widget _buildPublicChat() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder(
            stream: _publicMessagesController.stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong'));
              }

              if (!snapshot.hasData) {
                if (_cachedPublicMessages != null) {
                  return _buildMessagesList(_cachedPublicMessages!);
                }
                return const Center(child: CircularProgressIndicator());
              }

              try {
                final dynamic snapshotValue = snapshot.data!.snapshot.value;
                if (snapshotValue == null) {
                  _cachedPublicMessages = [];
                  _isPublicMessagesLoaded = true;
                  return const Center(child: Text('No messages yet'));
                }

                List<MapEntry<dynamic, dynamic>> messages = [];

                if (snapshotValue is Map) {
                  final messagesMap = Map<dynamic, dynamic>.from(snapshotValue);
                  messages = messagesMap.entries.toList();
                } else if (snapshotValue is List) {
                  messages = snapshotValue
                      .asMap()
                      .entries
                      .where((entry) => entry.value != null)
                      .toList();
                }

                messages.sort((a, b) {
                  final aTimestamp = (a.value['timestamp'] ?? 0) as int;
                  final bTimestamp = (b.value['timestamp'] ?? 0) as int;
                  return bTimestamp.compareTo(aTimestamp);
                });

                _cachedPublicMessages = messages;
                _isPublicMessagesLoaded = true;

                return _buildMessagesList(messages);
              } catch (e) {
                debugPrint('Error processing messages: $e');
                return Center(child: Text('Error: ${e.toString()}'));
              }
            },
          ),
        ),
        _buildMessageInput(_sendPublicMessage),
      ],
    );
  }

  Future<void> _sendPublicMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    if (!_isUserNameLoaded) {
      await _fetchCurrentUserName();
    }

    final messageData = {
      'text': _messageController.text.trim(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'userId': _currentUserId,
      'userName': _currentUserProfileName,
    };

    if (!_isOnline) {
      _offlineMessageQueue.add({
        'type': 'public',
        'data': messageData,
      });
    } else {
      try {
        await _dbRef.child('messages/public').push().set(messageData);
      } catch (e) {
        debugPrint('Error sending message: $e');
      }
    }

    _messageController.clear();
  }

  Widget _buildMessageInput(VoidCallback onSend) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: onSend,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<MapEntry<dynamic, dynamic>> messages) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No messages yet\nStart a conversation!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        try {
          final message = messages[index].value;
          if (message == null) return const SizedBox.shrink();

          final isCurrentUser = message['userId'] == _currentUserId;
          final timestamp = message['timestamp'] as int?;

          Widget? dateHeader;
          if (timestamp != null) {
            if (index == messages.length - 1) {
              dateHeader = _buildDateHeader(timestamp);
            } else {
              final nextMessage = messages[index + 1].value;
              final nextTimestamp = nextMessage['timestamp'] as int?;
              if (nextTimestamp != null) {
                final currentDate =
                    DateTime.fromMillisecondsSinceEpoch(timestamp);
                final nextDate =
                    DateTime.fromMillisecondsSinceEpoch(nextTimestamp);
                if (currentDate.day != nextDate.day ||
                    currentDate.month != nextDate.month ||
                    currentDate.year != nextDate.year) {
                  dateHeader = _buildDateHeader(timestamp);
                }
              }
            }
          }

          return Column(
            children: [
              if (dateHeader != null) dateHeader,
              Align(
                alignment: isCurrentUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  margin: EdgeInsets.only(
                    left: isCurrentUser ? 50 : 0,
                    right: isCurrentUser ? 0 : 50,
                    bottom: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: isCurrentUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (timestamp != null &&
                          _shouldShowTimestamp(
                            currentTimestamp: timestamp,
                            previousMessage: index < messages.length - 1
                                ? messages[index + 1].value
                                : null,
                          ))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            _getMessageTime(timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(isCurrentUser ? 20 : 5),
                            topRight: Radius.circular(isCurrentUser ? 5 : 20),
                            bottomLeft: const Radius.circular(20),
                            bottomRight: const Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isCurrentUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (!isCurrentUser)
                              StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(message['userId']?.toString() ?? '')
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  String displayName =
                                      message['userName']?.toString() ??
                                          'Unknown';
                                  if (snapshot.hasData &&
                                      snapshot.data!.exists) {
                                    final userData = snapshot.data!.data()
                                        as Map<String, dynamic>;
                                    displayName = userData['profileName'] ??
                                        userData['name'] ??
                                        displayName;
                                  }
                                  return Text(
                                    displayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            if (!isCurrentUser) const SizedBox(height: 4),
                            Text(
                              message['text']?.toString() ?? '',
                              style: TextStyle(
                                color: isCurrentUser
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        } catch (e) {
          debugPrint('Error building message: $e');
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildPrivateChats() {
    // If we already have sorted users and aren't searching, use the cached list
    if (_sortedUsers != null && _searchQuery.isEmpty) {
      return Container(
        color: Colors.grey[50],
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _buildUsersList(_sortedUsers!),
            ),
          ],
        ),
      );
    }

    // If we have cached users but they're not sorted yet
    if (_cachedUsers.isNotEmpty && !_isLoadingSortedUsers) {
      _isLoadingSortedUsers = true;
      // Only sort if we don't have sorted users or if we're searching
      final usersToSort = _searchQuery.isEmpty
          ? _cachedUsers
          : _cachedUsers
              .where((user) =>
                  user.name.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();

      getUsersWithLastMessage(usersToSort).then((sortedUsers) {
        if (mounted) {
          setState(() {
            _sortedUsers = sortedUsers;
            _isLoadingSortedUsers = false;
          });
        }
      });
    }

    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _cachedUsers.isEmpty
                ? _buildEmptyUsersView()
                : _buildUsersList(_cachedUsers),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          hintText:
              AppLocalizations.of(context)?.searchUsers ?? 'Search users...',
          hintStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: Colors.grey[600],
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
            // Clear sorted users when searching to force re-sort
            if (value.isNotEmpty) {
              _sortedUsers = null;
            }
          });
        },
      ),
    );
  }

  Widget _buildEmptyUsersView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)?.noUsersAvailable ??
                'No users available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(int timestamp) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getDateHeader(timestamp),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldShowTimestamp({
    required int? currentTimestamp,
    required dynamic previousMessage,
  }) {
    if (currentTimestamp == null) return false;
    if (previousMessage == null) return true;

    final previousTimestamp = previousMessage['timestamp'] as int?;
    if (previousTimestamp == null) return true;

    return (currentTimestamp - previousTimestamp) > _timeGapThreshold;
  }

  String _getMessageTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getDateHeader(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return AppLocalizations.of(context)?.today ?? 'Today';
    } else if (difference.inDays == 1) {
      return AppLocalizations.of(context)?.yesterday ?? 'Yesterday';
    } else {
      final day = _getDayName(date.weekday);
      return '$day, ${date.day}/${date.month}/${date.year}';
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  Widget _buildUsersList(List<UserData> users) {
    // Filter users based on search query first
    final filteredUsers = _searchQuery.isEmpty
        ? users
        : users
            .where((user) =>
                user.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'No users found'
                  : 'No users match your search',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        final chatRoomId = _getChatRoomId(_currentUserId, user.id);

        // Use cached messages if offline or while loading
        final cachedMessages = _cachedPrivateMessages[chatRoomId];

        return StreamBuilder(
          stream: _dbRef
              .child('messages/private/$chatRoomId')
              .limitToLast(1)
              .onValue,
          builder: (context, snapshot) {
            String? lastMessage = user.lastMessage;
            String timeAgo = '';
            bool isUnread = false;

            // First check if we have new data from the stream
            if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
              try {
                final messagesMap =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                final lastMessageData =
                    messagesMap.values.last as Map<dynamic, dynamic>;
                lastMessage = lastMessageData['text']?.toString();
                user.lastMessage = lastMessage;
                user.lastMessageTimestamp =
                    lastMessageData['timestamp'] as int?;
                
                if (user.lastMessageTimestamp != null) {
                  timeAgo = _formatLastMessageTime(user.lastMessageTimestamp!);
                }

                isUnread = lastMessageData['userId'] != _currentUserId &&
                    !(lastMessageData['read'] ?? false);
              } catch (e) {
                debugPrint('Error processing message: $e');
              }
            }
            // If no stream data, use cached data
            else if (cachedMessages != null && cachedMessages.isNotEmpty) {
              try {
                final lastMessageData = cachedMessages.first.value;
                lastMessage = lastMessageData['text']?.toString();
                if (lastMessageData['timestamp'] != null) {
                  timeAgo = _formatLastMessageTime(lastMessageData['timestamp']);
                }
                isUnread = lastMessageData['userId'] != _currentUserId &&
                    !(lastMessageData['read'] ?? false);
              } catch (e) {
                debugPrint('Error processing cached message: $e');
              }
            }

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user.profilePicture?.isNotEmpty == true &&
                        Uri.tryParse(user.profilePicture!)?.hasScheme == true
                    ? NetworkImage(user.profilePicture!)
                    : null,
                child: (user.profilePicture?.isEmpty ?? true) ||
                        Uri.tryParse(user.profilePicture!)?.hasScheme != true
                    ? Text(user.name[0].toUpperCase())
                    : null,
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      user.name,
                      style: TextStyle(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (timeAgo.isNotEmpty)
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnread ? Colors.black87 : Colors.grey[600],
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                ],
              ),
              subtitle: lastMessage != null
                  ? Text(
                      lastMessage,
                      style: TextStyle(
                        color: isUnread ? Colors.black87 : Colors.grey[600],
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              onTap: () => _showPrivateChat(
                context,
                {
                  'userName': user.name,
                  'email': user.email,
                  'profileImageUrl': user.profilePicture,
                },
                user.id,
              ),
            );
          },
        );
      },
    );
  }

  Future<List<UserData>> getUsersWithLastMessage(List<UserData> users) async {
    List<UserData> usersWithMessages = List.from(users);

    // Fetch last messages for each user
    for (var user in usersWithMessages) {
      try {
        final chatRoomId = _getChatRoomId(_currentUserId, user.id);
        final snapshot = await _dbRef
            .child('messages/private/$chatRoomId')
            .limitToLast(1)
            .get();

        if (snapshot.value != null) {
          final messagesMap = snapshot.value as Map<dynamic, dynamic>;
          final lastMessageData = messagesMap.values.last as Map<dynamic, dynamic>;
          user.lastMessage = lastMessageData['text']?.toString();
          user.lastMessageTimestamp = lastMessageData['timestamp'] as int?;
        }
      } catch (e) {
        debugPrint('Error fetching last message for user ${user.id}: $e');
      }
    }

    // Sort users by last message timestamp
    usersWithMessages.sort((a, b) {
      final aTimestamp = a.lastMessageTimestamp ?? 0;
      final bTimestamp = b.lastMessageTimestamp ?? 0;
      return bTimestamp.compareTo(aTimestamp);
    });

    return usersWithMessages;
  }

  String _formatLastMessageTime(int timestamp) {
    final now = DateTime.now();
    final messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(messageTime);

    if (difference.inDays > 7) {
      return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _getChatRoomId(String userId1, String userId2) {
    final ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }

  void _showPrivateChat(
      BuildContext context, Map<String, dynamic> userData, String userId) {
    _clearSearchFocus();

    final chatRoomId = _getChatRoomId(_currentUserId, userId);

    // Subscribe to private messages and cache them when online
    _privateMessageSubscriptions[chatRoomId]?.cancel();
    _privateMessageSubscriptions[chatRoomId] =
        _dbRef.child('messages/private/$chatRoomId').onValue.listen((event) {
      if (event.snapshot.value != null) {
        try {
          final messages = _processPrivateMessages(event.snapshot.value);
          _cachedPrivateMessages[chatRoomId] = messages;

          // Cache all private messages
          _preferences.setString(
            _privateMessagesCacheKey,
            json.encode(_cachedPrivateMessages.map((key, value) => MapEntry(
                  key,
                  value
                      .map((entry) => {
                            'key': entry.key,
                            'value': entry.value,
                          })
                      .toList(),
                ))),
          );
        } catch (e) {
          debugPrint('Error caching private messages: $e');
        }
      }
    });

    _markMessagesAsRead(chatRoomId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // User info
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: userData['profileImageUrl'] !=
                                          null &&
                                      Uri.tryParse(userData['profileImageUrl'])
                                              ?.hasScheme ==
                                          true
                                  ? NetworkImage(userData['profileImageUrl'])
                                  : null,
                              child: userData['profileImageUrl'] == null ||
                                      Uri.tryParse(userData['profileImageUrl'])
                                              ?.hasScheme !=
                                          true
                                  ? Text(
                                      userData['userName'][0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userData['userName'] ?? 'Chat',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (userData['email'] != null)
                                    Text(
                                      userData['email'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              color: Colors.white,
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Messages
                Expanded(
                  child: Container(
                    color: Colors.grey[50],
                    child: StreamBuilder(
                      stream:
                          _dbRef.child('messages/private/$chatRoomId').onValue,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                              child: Text('Something went wrong'));
                        }

                        // Show cached messages while loading
                        if (!snapshot.hasData ||
                            snapshot.data?.snapshot.value == null) {
                          if (_cachedPrivateMessages.containsKey(chatRoomId)) {
                            final cachedMessages =
                                _cachedPrivateMessages[chatRoomId]!;
                            return _buildPrivateMessagesList(
                                cachedMessages, scrollController);
                          }
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  'No messages yet\nStart a conversation!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        try {
                          final messagesMap = Map<dynamic, dynamic>.from(
                              snapshot.data!.snapshot.value as Map);
                          final messages = messagesMap.entries.toList()
                            ..sort((a, b) => ((b.value['timestamp'] ?? 0)
                                    as int)
                                .compareTo((a.value['timestamp'] ?? 0) as int));

                          // Cache the messages
                          _cachedPrivateMessages[chatRoomId] = messages;

                          return _buildPrivateMessagesList(
                              messages, scrollController);
                        } catch (e) {
                          return Center(child: Text('Error: ${e.toString()}'));
                        }
                      },
                    ),
                  ),
                ),
                // Message input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: _buildMessageInput(
                    () => _sendPrivateMessage(userId),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendPrivateMessage(String recipientId) async {
    if (_messageController.text.trim().isEmpty) return;

    debugPrint('Sending private message to user: $recipientId');

    if (!_isUserNameLoaded) {
      await _fetchCurrentUserName();
    }

    final chatRoomId = _getChatRoomId(_currentUserId, recipientId);
    final messageData = {
      'text': _messageController.text.trim(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'userId': _currentUserId,
      'userName': _currentUserProfileName,
      'read': false,
    };

    if (!_isOnline) {
      debugPrint('Device is offline, queueing message');
      _offlineMessageQueue.add({
        'type': 'private',
        'chatRoomId': chatRoomId,
        'data': messageData,
      });
    } else {
      try {
        debugPrint('Sending message to Firebase');
        await _dbRef.child('messages/private/$chatRoomId').push().set(messageData);
      } catch (e) {
        debugPrint('Error sending private message: $e');
      }
    }

    _messageController.clear();
  }

  void _markMessagesAsRead(String chatRoomId) {
    _dbRef.child('messages/private/$chatRoomId').get().then((snapshot) {
      if (snapshot.value != null) {
        final messages = snapshot.value as Map<dynamic, dynamic>;
        messages.forEach((key, value) {
          if (value['userId'] != _currentUserId && !(value['read'] ?? false)) {
            _dbRef
                .child('messages/private/$chatRoomId/$key')
                .update({'read': true});
          }
        });
      }
    });
  }

  Widget _buildPrivateMessagesList(
    List<MapEntry<dynamic, dynamic>> messages,
    ScrollController scrollController,
  ) {
    return ListView.builder(
      reverse: true,
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index].value as Map<dynamic, dynamic>;
        final isCurrentUser = message['userId'] == _currentUserId;
        final timestamp = message['timestamp'] as int?;

        // Add date header logic
        Widget? dateHeader;
        if (timestamp != null) {
          if (index == messages.length - 1) {
            dateHeader = _buildDateHeader(timestamp);
          } else {
            final nextMessage = messages[index + 1].value;
            final nextTimestamp = nextMessage['timestamp'] as int?;
            if (nextTimestamp != null) {
              final currentDate =
                  DateTime.fromMillisecondsSinceEpoch(timestamp);
              final nextDate =
                  DateTime.fromMillisecondsSinceEpoch(nextTimestamp);
              if (currentDate.day != nextDate.day ||
                  currentDate.month != nextDate.month ||
                  currentDate.year != nextDate.year) {
                dateHeader = _buildDateHeader(timestamp);
              }
            }
          }
        }

        return Column(
          children: [
            if (dateHeader != null) dateHeader,
            Align(
              alignment:
                  isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                margin: EdgeInsets.only(
                  left: isCurrentUser ? 50 : 0,
                  right: isCurrentUser ? 0 : 50,
                  bottom: 4,
                ),
                child: Column(
                  crossAxisAlignment: isCurrentUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (timestamp != null &&
                        _shouldShowTimestamp(
                          currentTimestamp: timestamp,
                          previousMessage: index < messages.length - 1
                              ? messages[index + 1].value
                              : null,
                        ))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          _getMessageTime(timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isCurrentUser
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(isCurrentUser ? 20 : 5),
                          topRight: Radius.circular(isCurrentUser ? 5 : 20),
                          bottomLeft: const Radius.circular(20),
                          bottomRight: const Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: isCurrentUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (!isCurrentUser)
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(message['userId']?.toString() ?? '')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                String displayName =
                                    message['userName']?.toString() ??
                                        'Unknown';
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  final userData = snapshot.data!.data()
                                      as Map<String, dynamic>;
                                  displayName = userData['profileName'] ??
                                      userData['name'] ??
                                      displayName;
                                }
                                return Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          if (!isCurrentUser) const SizedBox(height: 4),
                          Text(
                            message['text']?.toString() ?? '',
                            style: TextStyle(
                              color:
                                  isCurrentUser ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchCurrentUserName() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _currentUserProfileName = userDoc.data()?['profileName'] ??
              userDoc.data()?['name'] ??
              'Unknown User';
          _isUserNameLoaded = true;
        });
      }
      debugPrint('Fetched user name: $_currentUserProfileName');
    } catch (e) {
      debugPrint('Error fetching user name: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();

    _publicMessagesController.close();
    _usersController.close();

    _publicMessagesSubscription?.cancel();
    _usersSubscription?.cancel();

    // Cancel all private message subscriptions
    for (var subscription in _privateMessageSubscriptions.values) {
      subscription?.cancel();
    }
    _privateMessageSubscriptions.clear();

    _cachedUsers.clear();
    _isUsersLoaded = false;
    _cachedPrivateMessages.clear();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  List<MapEntry<dynamic, dynamic>> _processPublicMessages(dynamic value) {
    List<MapEntry<dynamic, dynamic>> messages = [];

    if (value is Map) {
      final messagesMap = Map<dynamic, dynamic>.from(value);
      messages = messagesMap.entries.toList();
    } else if (value is List) {
      messages =
          value.asMap().entries.where((entry) => entry.value != null).toList();
    }

    messages.sort((a, b) {
      final aTimestamp = (a.value['timestamp'] ?? 0) as int;
      final bTimestamp = (b.value['timestamp'] ?? 0) as int;
      return bTimestamp.compareTo(aTimestamp);
    });

    return messages;
  }

  List<MapEntry<dynamic, dynamic>> _processPrivateMessages(dynamic value) {
    List<MapEntry<dynamic, dynamic>> messages = [];

    if (value is Map) {
      final messagesMap = Map<dynamic, dynamic>.from(value);
      messages = messagesMap.entries.toList();
    } else if (value is List) {
      messages =
          value.asMap().entries.where((entry) => entry.value != null).toList();
    }

    messages.sort((a, b) {
      final aTimestamp = (a.value['timestamp'] ?? 0) as int;
      final bTimestamp = (b.value['timestamp'] ?? 0) as int;
      return bTimestamp.compareTo(aTimestamp);
    });

    return messages;
  }

  static bool hasUnreadMessages() {
    final dbRef = FirebaseDatabase.instance.ref();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    bool hasUnread = false;

    dbRef.child('messages/private').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final messages = event.snapshot.value as Map<dynamic, dynamic>;
        
        for (var chatRoom in messages.values) {
          if (chatRoom is Map) {
            for (var message in chatRoom.values) {
              if (message is Map &&
                  message['userId'] != currentUserId &&
                  !(message['read'] ?? false)) {
                hasUnread = true;
                break;
              }
            }
          }
          if (hasUnread) break;
        }
      }
    });

    dbRef.child('messages/public')
        .orderByChild('timestamp')
        .limitToLast(1)
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        final message = (event.snapshot.value as Map<dynamic, dynamic>)
            .values
            .first as Map<dynamic, dynamic>;
            
        if (message['userId'] != currentUserId) {
          hasUnread = true;
        }
      }
    });

    return hasUnread;
  }
}

class UserData {
  final String id;
  final String name;
  final String? profilePicture;
  final String? email;
  String? lastMessage;
  int? lastMessageTimestamp;

  UserData({
    required this.id,
    required this.name,
    this.profilePicture,
    this.email,
    this.lastMessage,
    this.lastMessageTimestamp,
  });

  @override
  String toString() {
    return 'UserData{id: $id, name: $name, email: $email}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserData && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
