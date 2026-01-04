import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sureplan/new_idea/feature_service.dart';

class IdeaPage extends StatefulWidget {
  const IdeaPage({super.key});

  @override
  State<IdeaPage> createState() => _IdeaPageState();
}

class _IdeaPageState extends State<IdeaPage> {
  final _ideaTitle = TextEditingController();
  final _ideaDescription = TextEditingController();
  final FeatureService _featureService = FeatureService();
  final String? _currentUserId = Supabase.instance.client.auth.currentUser?.id;

  List<Map<String, dynamic>> _features = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFeatures();
  }

  Future<void> _fetchFeatures() async {
    try {
      final features = await _featureService.getFeatureRequests();
      setState(() {
        _features = features;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching features: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDelete(String featureId) async {
    try {
      await _featureService.deleteFeatureRequest(featureId);
      _fetchFeatures();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Feature request deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleUpvote(
    String featureId,
    int currentCount,
    List<dynamic> votes,
  ) async {
    if (_currentUserId == null) return;

    // Check if user already voted
    final isUpvoted = votes.any((v) => v['user_id'] == _currentUserId);

    // Optimistic UI update
    setState(() {
      final index = _features.indexWhere((f) => f['id'] == featureId);
      if (index != -1) {
        if (isUpvoted) {
          _features[index]['upvotes_count'] = currentCount - 1;
          _features[index]['feature_votes'].removeWhere(
            (v) => v['user_id'] == _currentUserId,
          );
        } else {
          _features[index]['upvotes_count'] = currentCount + 1;
          _features[index]['feature_votes'].add({'user_id': _currentUserId});
        }
      }
    });

    try {
      await _featureService.toggleUpvote(featureId, currentCount, isUpvoted);
    } catch (e) {
      // Revert if error
      _fetchFeatures();
    }
  }

  Future<void> _submitIdea() async {
    if (_ideaTitle.text.isEmpty) return;

    try {
      await _featureService.createFeatureRequest(
        _ideaTitle.text,
        _ideaDescription.text,
      );

      _ideaTitle.clear();
      _ideaDescription.clear();
      if (mounted) Navigator.pop(context);

      _fetchFeatures();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit idea: $e')));
    }
  }

  @override
  void dispose() {
    _ideaTitle.dispose();
    _ideaDescription.dispose();
    super.dispose();
  }

  Widget _addIdea() {
    return Column(
      children: [
        TextField(
          controller: _ideaTitle,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Idea Title',
          ),
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),

        const SizedBox(height: 20),
        TextField(
          controller: _ideaDescription,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Idea Description',
          ),
          maxLines: 5,
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Request new features',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchFeatures,
              child: _features.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.network(
                              "https://img.icons8.com/?size=100&id=Fbx0R3VBZJKy&format=png&color=000000",
                              height: 50,
                              width: 50,
                              color: Colors.grey,
                            ),

                            SizedBox(height: 10),

                            Text(
                              "No new features requests yet. Be the first to add one!",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _features.length,
                      itemBuilder: (context, index) {
                        final feature = _features[index];
                        final votes = (feature['feature_votes'] as List?) ?? [];
                        final isUpvoted = votes.any(
                          (v) => v['user_id'] == _currentUserId,
                        );
                        final isCreator = feature['user_id'] == _currentUserId;

                        return Card(
                          margin: EdgeInsets.only(bottom: 15),
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[400]!),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        feature['title'] ?? '',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (feature['description'] != null &&
                                          feature['description']
                                              .isNotEmpty) ...[
                                        SizedBox(height: 8),
                                        Text(
                                          feature['description'],
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12),
                                Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        border: Border.all(color: Colors.grey),
                                      ),

                                      child: IconButton(
                                        icon: Icon(
                                          isUpvoted
                                              ? Icons.arrow_upward_rounded
                                              : Icons.arrow_upward_outlined,
                                          color: isUpvoted
                                              ? Colors.blue
                                              : Colors.black,
                                          size: 30,
                                        ),
                                        onPressed: () => _handleUpvote(
                                          feature['id'],
                                          feature['upvotes_count'] ?? 0,
                                          votes,
                                        ),
                                      ),
                                    ),

                                    Text(
                                      '${feature['upvotes_count'] ?? 0}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: isUpvoted
                                            ? Colors.blue
                                            : Colors.black,
                                      ),
                                    ),

                                    if (isCreator) ...[
                                      SizedBox(height: 10),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.black,
                                          size: 33,
                                        ),
                                        onPressed: () =>
                                            _handleDelete(feature['id']),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

      floatingActionButton: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color.fromARGB(255, 156, 156, 156)),
        ),

        child: IconButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  title: const Text("Request new features"),

                  content: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: SingleChildScrollView(child: _addIdea()),
                  ),

                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        elevation: 0,
                        side: BorderSide(color: Colors.black),
                      ),
                      onPressed: _submitIdea,
                      child: Text(
                        "Add",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          icon: const Icon(Icons.add, size: 40, color: Colors.white),
        ),
      ),
    );
  }
}
