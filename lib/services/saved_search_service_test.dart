import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'saved_search_service.dart';

/// Test widget to verify Firebase Saved Search Service functionality
/// 
/// This widget can be used to test the saved search service during development.
/// Add this to your app temporarily to verify everything works correctly.
class SavedSearchServiceTest extends StatefulWidget {
  const SavedSearchServiceTest({super.key});

  @override
  State<SavedSearchServiceTest> createState() => _SavedSearchServiceTestState();
}

class _SavedSearchServiceTestState extends State<SavedSearchServiceTest> {
  final SavedSearchService _savedSearchService = SavedSearchService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController(text: 'test_user_123');
  
  @override
  void initState() {
    super.initState();
    _savedSearchService.initialize(_userIdController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Search Service Test'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Test Controls',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _userIdController,
                      decoration: const InputDecoration(
                        labelText: 'User ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Search Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    ElevatedButton(
                      onPressed: _testSaveSearch,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Test Save Search'),
                    ),
                    const SizedBox(height: 8),
                    
                    ElevatedButton(
                      onPressed: _testListSearches,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      child: const Text('Test List Searches'),
                    ),
                    const SizedBox(height: 8),
                    
                    ElevatedButton(
                      onPressed: _testDeleteSearch,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Test Delete Search'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Service Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Loading: ${_savedSearchService.isLoading}'),
                    Text('Error: ${_savedSearchService.errorMessage ?? 'None'}'),
                    Text('Searches Count: ${_savedSearchService.savedSearches.length}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Saved Searches List
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saved Searches',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Consumer<SavedSearchService>(
                          builder: (context, service, child) {
                            if (service.isLoading) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            if (service.savedSearches.isEmpty) {
                              return const Center(
                                child: Text('No saved searches found'),
                              );
                            }
                            
                            return ListView.builder(
                              itemCount: service.savedSearches.length,
                              itemBuilder: (context, index) {
                                final search = service.savedSearches[index];
                                return ListTile(
                                  title: Text(search.name),
                                  subtitle: Text('Created: ${search.createdAt.toString()}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _testDeleteSpecificSearch(search.id),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testSaveSearch() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Please enter a search name', Colors.red);
      return;
    }

    final filters = {
      'searchQuery': 'test search',
      'city': 'Tripoli',
      'type': 'apartment',
      'status': 'forRent',
      'priceRange': {'min': 500, 'max': 1500},
      'features': ['hasBalcony', 'hasParking'],
    };

    final success = await _savedSearchService.saveSearch(
      userId: _userIdController.text.trim(),
      name: _nameController.text.trim(),
      filters: filters,
      description: 'Test search created from widget',
    );

    _showSnackBar(
      success ? 'Search saved successfully!' : 'Failed to save search',
      success ? Colors.green : Colors.red,
    );

    if (success) {
      _nameController.clear();
    }
  }

  Future<void> _testListSearches() async {
    await _savedSearchService.initialize(_userIdController.text.trim());
    _showSnackBar(
      'Found ${_savedSearchService.savedSearches.length} saved searches',
      Colors.blue,
    );
  }

  Future<void> _testDeleteSearch() async {
    if (_savedSearchService.savedSearches.isEmpty) {
      _showSnackBar('No searches to delete', Colors.orange);
      return;
    }

    final firstSearch = _savedSearchService.savedSearches.first;
    final success = await _savedSearchService.delete(firstSearch.id);
    
    _showSnackBar(
      success ? 'Search deleted successfully!' : 'Failed to delete search',
      success ? Colors.green : Colors.red,
    );
  }

  Future<void> _testDeleteSpecificSearch(String searchId) async {
    final success = await _savedSearchService.delete(searchId);
    
    _showSnackBar(
      success ? 'Search deleted successfully!' : 'Failed to delete search',
      success ? Colors.green : Colors.red,
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}

/// Helper function to add test route to your app router
/// 
/// Add this to your app_router.dart for testing:
/// 
/// GoRoute(
///   path: '/test-saved-search',
///   name: 'test-saved-search',
///   builder: (context, state) => const SavedSearchServiceTest(),
/// ),
