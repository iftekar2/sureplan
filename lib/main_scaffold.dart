import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sureplan/bottom_navigation/home_page.dart';
import 'package:sureplan/bottom_navigation/invitations_page.dart';
import 'package:sureplan/bottom_navigation/Idea_page.dart';
import 'package:sureplan/bottom_navigation/search_event.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  late final List<Key> _pageKeys = [
    UniqueKey(),
    UniqueKey(),
    UniqueKey(),
    UniqueKey(),
  ];

  late final List<Widget> _pages = [
    HomePage(key: _pageKeys[0]),
    InvitationsPage(key: _pageKeys[1]),
    SearchEvent(key: _pageKeys[2]),
    IdeaPage(key: _pageKeys[3]),
  ];

  RealtimeChannel? _inviteChannel;

  @override
  void initState() {
    super.initState();
    // _setupInviteListener();
  }

  @override
  void dispose() {
    _inviteChannel?.unsubscribe();
    super.dispose();
  }

  // void _setupInviteListener() {
  //   final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  //   if (currentUserId == null) return;

  //   _inviteChannel = Supabase.instance.client
  //       .channel('public:event_invites')
  //       .onPostgresChanges(
  //         event: PostgresChangeEvent.insert,
  //         schema: 'public',
  //         table: 'event_invites',
  //         filter: PostgresChangeFilter(
  //           type: PostgresChangeFilterType.eq,
  //           column: 'invitee_id',
  //           value: currentUserId,
  //         ),
  //         callback: (payload) {
  //           Notificationservice().showNotification(
  //             id: payload.newRecord['id'].toString(),
  //             title: 'New Event Invitation',
  //             body: 'You have been invited to a new event!',
  //           );
  //         },
  //       )
  //       .onPostgresChanges(
  //         event: PostgresChangeEvent.update,
  //         schema: 'public',
  //         table: 'event_invites',
  //         filter: PostgresChangeFilter(
  //           type: PostgresChangeFilterType.eq,
  //           column: 'invitee_id',
  //           value: currentUserId,
  //         ),
  //         callback: (payload) {
  //           setState(() {
  //             _pageKeys[0] = UniqueKey();
  //             _pages[0] = HomePage(key: _pageKeys[0]);
  //           });
  //         },
  //       )
  //       .subscribe();
  // }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      setState(() {
        _pageKeys[index] = UniqueKey();
        _pages[0] = HomePage(key: _pageKeys[0]);
        _pages[1] = InvitationsPage(key: _pageKeys[1]);
        _pages[2] = SearchEvent(key: _pageKeys[2]);
        _pages[3] = IdeaPage(key: _pageKeys[3]);
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
        selectedLabelStyle: TextStyle(color: Colors.black, fontSize: 16),
        unselectedLabelStyle: TextStyle(color: Colors.black, fontSize: 14),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,

        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 35),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.email, size: 35),
            label: 'Invites',
          ),

          BottomNavigationBarItem(
            icon: Image.network(
              "https://img.icons8.com/?size=100&id=4CcGKQk6u4O0&format=png&color=000000",
              width: 30,
              height: 30,
              color: _selectedIndex == 2 ? Colors.black : Colors.grey,
            ),
            label: 'Search',
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
