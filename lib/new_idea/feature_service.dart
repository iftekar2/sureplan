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
      print('Error fetching features: $e');
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
      print('Error creating feature: $e');
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
      if (isUpvoted) {
        // Remove vote
        await _supabase.from('feature_votes').delete().match({
          'feature_id': featureId,
          'user_id': userId,
        });

        // Decrement count (optimistic approach since we don't have triggers set up yet)
        final newCount = currentCount > 0 ? currentCount - 1 : 0;
        await _supabase
            .from('feature_requests')
            .update({'upvotes_count': newCount})
            .eq('id', featureId);

        return newCount;
      } else {
        // Add vote
        await _supabase.from('feature_votes').insert({
          'feature_id': featureId,
          'user_id': userId,
        });

        // Increment count
        final newCount = currentCount + 1;
        await _supabase
            .from('feature_requests')
            .update({'upvotes_count': newCount})
            .eq('id', featureId);

        return newCount;
      }
    } catch (e) {
      print('Error toggling upvote: $e');
      throw e;
    }
  }

  /// Delete a feature request
  Future<void> deleteFeatureRequest(String featureId) async {
    try {
      await _supabase.from('feature_requests').delete().eq('id', featureId);
    } catch (e) {
      print('Error deleting feature: $e');
      throw e;
    }
  }
}
