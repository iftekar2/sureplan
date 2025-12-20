import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sureplan/home/homePage.dart';
import 'package:sureplan/home/invitationsPage.dart';
import 'package:sureplan/new_idea/IdeaPage.dart';
import 'package:sureplan/notification/notificationService.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  late final List<Key> _pageKeys = [UniqueKey(), UniqueKey(), UniqueKey()];
  late final List<Widget> _pages = [
    HomePage(key: _pageKeys[0]),
    InvitationsPage(key: _pageKeys[1]),
    IdeaPage(key: _pageKeys[2]),
  ];

  RealtimeChannel? _inviteChannel;

  @override
  void initState() {
    super.initState();
    _setupInviteListener();
  }

  @override
  void dispose() {
    _inviteChannel?.unsubscribe();
    super.dispose();
  }

  void _setupInviteListener() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    _inviteChannel = Supabase.instance.client
        .channel('public:event_invites')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'event_invites',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'invitee_id',
            value: currentUserId,
          ),
          callback: (payload) {
            Notificationservice().showNotification(
              id: payload.newRecord['id'].toString(),
              title: 'New Event Invitation',
              body: 'You have been invited to a new event!',
            );
          },
        )
        .subscribe();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      setState(() {
        _pageKeys[index] = UniqueKey();
        _pages[0] = HomePage(key: _pageKeys[0]);
        _pages[1] = InvitationsPage(key: _pageKeys[1]);
        _pages[2] = IdeaPage(key: _pageKeys[2]);
      });
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),

      bottomNavigationBar: BottomNavigationBar(
        selectedLabelStyle: TextStyle(color: Colors.black, fontSize: 14),
        unselectedLabelStyle: TextStyle(color: Colors.black, fontSize: 12),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,

        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 35),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.email, size: 35),
            label: 'Email',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline, size: 35),
            label: 'Ideas',
          ),
        ],
      ),
    );
  }
}
