import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../utils/firebase_auth_helper.dart';
import '../../widgets/dary_loading_indicator.dart';

class FirebaseAuthManagementScreen extends StatefulWidget {
  const FirebaseAuthManagementScreen({super.key});

  @override
  State<FirebaseAuthManagementScreen> createState() => _FirebaseAuthManagementScreenState();
}

class _FirebaseAuthManagementScreenState extends State<FirebaseAuthManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await FirebaseAuthHelper.getUsersNotInFirebaseAuth();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading users: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _printUsersToConsole() async {
    await FirebaseAuthHelper.printUsersForFirebaseAuth();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User information printed to console. Check debug output.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _markUserAsCreated(String userId) async {
    try {
      await FirebaseAuthHelper.markUserAsFirebaseAuthCreated(userId);
      await _loadUsers(); // Refresh the list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User marked as created in Firebase Auth'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Auth Management'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printUsersToConsole,
            tooltip: 'Print users to console',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: DaryLoadingIndicator())
          : _users.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 64,
                        color: Colors.green,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'All users are already in Firebase Auth!',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.orange.shade100,
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📋 Instructions:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '1. Go to Firebase Console → Authentication → Users',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            '2. Click "Add user" for each user below',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            '3. Use the email and create a password',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            '4. Click "Mark as Created" after adding to Firebase Auth',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green,
                                child: Text(
                                  user['name']?.substring(0, 1).toUpperCase() ?? 'U',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(user['name'] ?? 'Unknown'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Email: ${user['email']}'),
                                  Text('Phone: ${user['phone'] ?? 'N/A'}'),
                                  Text('Verified: ${user['isVerified'] ? 'Yes' : 'No'}'),
                                  Text('Admin: ${user['isAdmin'] ? 'Yes' : 'No'}'),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: () => _markUserAsCreated(user['id']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Mark as Created'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
