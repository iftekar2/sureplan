import 'package:flutter/material.dart';
import 'package:sureplan/home/homePage.dart';
import 'package:sureplan/home/invitationsPage.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  late final List<Key> _pageKeys = [UniqueKey(), UniqueKey()];
  late final List<Widget> _pages = [
    HomePage(key: _pageKeys[0]),
    InvitationsPage(key: _pageKeys[1]),
  ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      setState(() {
        _pageKeys[index] = UniqueKey();
        _pages[0] = HomePage(key: _pageKeys[0]);
        _pages[1] = InvitationsPage(key: _pageKeys[1]);
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
        ],
      ),
    );
  }
}
