import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeatureService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all feature requests ordered by upvotes
  Future<List<Map<String, dynamic>>> getFeatureRequests() async {
    try {
      final response = await _supabase
          .from('feature_requests')
          .select('*, feature_votes(user_id)')
          .order('upvotes_count', ascending: false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching features: $e');
      throw e;
    }
  }

  /// Create a new feature request
  Future<void> createFeatureRequest(String title, String description) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User must be logged in');

    try {
      await _supabase.from('feature_requests').insert({
        'user_id': userId,
        'title': title,
        'description': description,
        'upvotes_count': 0,
      });
    } catch (e) {
      debugPrint('Error creating feature: $e');
      throw e;
    }
  }

  /// Toggle upvote for a feature
  /// Returns the new upvote count
  Future<int> toggleUpvote(
    String featureId,
    int currentCount,
    bool isUpvoted,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User must be logged in');

    try {
      final response = await _supabase.rpc(
        'toggle_feature_upvote',
        params: {'f_id': featureId, 'u_id': userId},
      );
      return response as int;
    } catch (e) {
      debugPrint('Error toggling upvote: $e');
      throw e;
    }
  }

  /// Delete a feature request
  Future<void> deleteFeatureRequest(String featureId) async {
    try {
      await _supabase.from('feature_requests').delete().eq('id', featureId);
    } catch (e) {
      debugPrint('Error deleting feature: $e');
      throw e;
    }
  }
}
