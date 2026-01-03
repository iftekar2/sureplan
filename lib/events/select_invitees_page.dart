import 'package:flutter/material.dart';
import 'package:sureplan/models/user_profile.dart';
import 'package:sureplan/services/invite_service.dart';

class SelectInviteesPage extends StatefulWidget {
  final List<UserProfile> alreadySelected;

  const SelectInviteesPage({super.key, this.alreadySelected = const []});

  @override
  State<SelectInviteesPage> createState() => _SelectInviteesPageState();
}

class _SelectInviteesPageState extends State<SelectInviteesPage> {
  final _searchController = TextEditingController();
  final _inviteService = InviteService();

  List<UserProfile> _searchResults = [];
  Set<String> _selectedUserIds = {};
  List<UserProfile> _selectedUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with already selected users
    _selectedUsers = List.from(widget.alreadySelected);
    _selectedUserIds = widget.alreadySelected.map((u) => u.id).toSet();
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _inviteService.searchUsers(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error searching users: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleSelection(UserProfile user) {
    setState(() {
      if (_selectedUserIds.contains(user.id)) {
        _selectedUserIds.remove(user.id);
        _selectedUsers.removeWhere((u) => u.id == user.id);
      } else {
        _selectedUserIds.add(user.id);
        _selectedUsers.add(user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Friends',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),

        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context, _selectedUsers);
              },
              child: Text(
                'Done (${_selectedUsers.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by username or email',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: _searchUsers,
                ),
              ),
              onSubmitted: (_) => _searchUsers(),
            ),
            SizedBox(height: 20),

            // Results
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    )
                  : _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        'Search for users to invite',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        final isSelected = _selectedUserIds.contains(user.id);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black,
                            child: Text(
                              user.username.isNotEmpty
                                  ? user.username[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(user.username),
                          //subtitle: Text(user.email),
                          trailing: Checkbox(
                            value: isSelected,
                            activeColor: Colors.black,
                            onChanged: (bool? value) {
                              _toggleSelection(user);
                            },
                          ),
                          onTap: () => _toggleSelection(user),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
