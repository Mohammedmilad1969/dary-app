import 'dart:convert';

class SavedSearch {
  final String id;
  final String userId;
  final String name;
  final Map<String, dynamic> filters;
  final DateTime createdAt;
  final DateTime? lastCheckedAt;
  final int newMatchesCount;

  const SavedSearch({
    required this.id,
    required this.userId,
    required this.name,
    required this.filters,
    required this.createdAt,
    this.lastCheckedAt,
    this.newMatchesCount = 0,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'filters': filters,
      'createdAt': createdAt.toIso8601String(),
      'lastCheckedAt': lastCheckedAt?.toIso8601String(),
      'newMatchesCount': newMatchesCount,
    };
  }

  // Create from JSON
  factory SavedSearch.fromJson(Map<String, dynamic> json) {
    return SavedSearch(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      filters: json['filters'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastCheckedAt: json['lastCheckedAt'] != null 
          ? DateTime.parse(json['lastCheckedAt'] as String)
          : null,
      newMatchesCount: json['newMatchesCount'] as int? ?? 0,
    );
  }

  // Create a copy with updated fields
  SavedSearch copyWith({
    String? id,
    String? userId,
    String? name,
    Map<String, dynamic>? filters,
    DateTime? createdAt,
    DateTime? lastCheckedAt,
    int? newMatchesCount,
  }) {
    return SavedSearch(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      filters: filters ?? this.filters,
      createdAt: createdAt ?? this.createdAt,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      newMatchesCount: newMatchesCount ?? this.newMatchesCount,
    );
  }

  // Convert filters to JSON string for storage
  String get filtersJson => jsonEncode(filters);

  // Parse filters from JSON string
  static Map<String, dynamic> parseFiltersFromJson(String jsonString) {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  @override
  String toString() {
    return 'SavedSearch(id: $id, name: $name, userId: $userId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SavedSearch && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
