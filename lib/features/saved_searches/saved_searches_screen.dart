import 'package:flutter/material.dart';
import 'package:dary/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/saved_search.dart';
import '../../models/property.dart';
import '../../providers/auth_provider.dart';
import '../../services/language_service.dart';
import '../../widgets/language_toggle_button.dart';
import '../../widgets/login_required_screen.dart';
import 'saved_search_service.dart';

class SavedSearchesScreen extends StatefulWidget {
  const SavedSearchesScreen({super.key});

  @override
  State<SavedSearchesScreen> createState() => _SavedSearchesScreenState();
}

class _SavedSearchesScreenState extends State<SavedSearchesScreen> {
  final SavedSearchService _savedSearchService = SavedSearchService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    setState(() {
      _isLoading = true;
    });
    
    await _savedSearchService.initialize();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _deleteSearch(SavedSearch search) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Saved Search'),
        content: Text('Are you sure you want to delete "${search.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _savedSearchService.deleteSearch(search.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? 'Search deleted successfully'
                  : 'Failed to delete search',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _runSearch(SavedSearch search) async {
    final properties = _savedSearchService.runSavedSearch(search.id);
    
    if (mounted) {
      // Navigate to homepage with search results
      context.go('/');
      
      // Show results count
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found ${properties.length} properties matching "${search.name}"'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _checkNewMatches(SavedSearch search) async {
    final newMatches = await _savedSearchService.checkNewMatches(search.id);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newMatches > 0 
                ? 'Found $newMatches new properties matching "${search.name}"'
                : 'No new properties found for "${search.name}"',
          ),
          backgroundColor: newMatches > 0 ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatFilters(SavedSearch search) {
    final filters = <String>[];
    
    if (search.filters['searchQuery'] != null && 
        search.filters['searchQuery'].toString().isNotEmpty) {
      filters.add('Query: ${search.filters['searchQuery']}');
    }
    
    if (search.filters['type'] != null) {
      filters.add('Type: ${search.filters['type']}');
    }
    
    if (search.filters['status'] != null) {
      filters.add('Status: ${search.filters['status']}');
    }
    
    if (search.filters['city'] != null && 
        search.filters['city'].toString().isNotEmpty) {
      filters.add('City: ${search.filters['city']}');
    }
    
    if (search.filters['priceRange'] != null) {
      final priceRange = search.filters['priceRange'] as Map<String, dynamic>;
      final min = priceRange['min']?.toString() ?? '0';
      final max = priceRange['max']?.toString() ?? '∞';
      filters.add('Price: $min - $max');
    }
    
    if (search.filters['features'] != null) {
      final features = List<String>.from(search.filters['features'] as List);
      if (features.isNotEmpty) {
        filters.add('Features: ${features.join(', ')}');
      }
    }
    
    return filters.isEmpty ? 'No filters applied' : filters.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = Provider.of<LanguageService>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Check authentication
    if (!authProvider.isAuthenticated) {
      return LoginRequiredScreen(
        featureName: l10n?.savedSearches ?? 'Saved Searches',
        description: 'Please login to save and manage your property searches',
      );
    }

    final currentUser = authProvider.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userSearches = _savedSearchService.getSavedSearchesForUser(currentUser.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.savedSearches ?? 'Saved Searches'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          LanguageToggleButton(languageService: languageService),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : userSearches.isEmpty
              ? _buildEmptyState(l10n)
              : _buildSearchesList(userSearches, l10n),
    );
  }

  Widget _buildEmptyState(AppLocalizations? l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              l10n?.noSavedSearches ?? 'No Saved Searches',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.noSavedSearchesDescription ?? 
                  'Save your property searches to get notified when new matching properties are added',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.search),
              label: Text(l10n?.startSearching ?? 'Start Searching'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchesList(List<SavedSearch> searches, AppLocalizations? l10n) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: searches.length,
      itemBuilder: (context, index) {
        final search = searches[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            search.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatFilters(search),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (search.newMatchesCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${search.newMatchesCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Created: ${_formatDate(search.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    if (search.lastCheckedAt != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        'Last checked: ${_formatDate(search.lastCheckedAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _runSearch(search),
                        icon: const Icon(Icons.search, size: 18),
                        label: Text(l10n?.runSearch ?? 'Run Search'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _checkNewMatches(search),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(l10n?.checkNewMatches ?? 'Check New'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _deleteSearch(search),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: l10n?.delete ?? 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
