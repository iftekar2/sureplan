// import 'package:flutter/material.dart';
// import 'package:sureplan/models/event.dart';

// class SearchEvent extends StatefulWidget {
//   const SearchEvent({super.key});

//   @override
//   State<SearchEvent> createState() => _SearchEventState();
// }

// class _SearchEventState extends State<SearchEvent> {
//   bool _isLoading = false;
//   List<Event> _searchResults = [];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           "Search for Events",
//           style: TextStyle(fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),

//       backgroundColor: Colors.white,
//       body: Padding(
//         padding: EdgeInsets.all(20),
//         child: Column(
//           children: [
//             TextField(
//               decoration: InputDecoration(
//                 hintText: 'Search Events by ID',
//                 prefixIcon: Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15),
//                 ),

//                 suffixIcon: IconButton(
//                   icon: Icon(Icons.arrow_forward),
//                   onPressed: () {},
//                 ),
//               ),
//             ),

//             SizedBox(height: 20),
//             Expanded(
//               child: _isLoading
//                   ? Center(
//                       child: CircularProgressIndicator(color: Colors.black),
//                     )
//                   : _searchResults.isEmpty
//                   ? Column(
//                       children: [
//                         Image.network(
//                           "https://img.icons8.com/?size=100&id=4CcGKQk6u4O0&format=png&color=000000",
//                           width: 30,
//                           height: 30,

//                           color: Colors.grey,
//                         ),
//                         Text(
//                           'Search for users to invite',
//                           style: TextStyle(color: Colors.grey),
//                         ),
//                       ],
//                     )
//                   : ListView.builder(
//                       itemCount: _searchResults.length,
//                       itemBuilder: (context, index) {
//                         final event = _searchResults[index];
//                         return ListTile(
//                           leading: CircleAvatar(
//                             child: Text(event.name[0].toUpperCase()),
//                             backgroundColor: Colors.grey[200],
//                             foregroundColor: Colors.black,
//                           ),

//                           title: Text(event.name),
//                           subtitle: Text(event.description),
//                           trailing: IconButton(
//                             icon: Icon(Icons.send, color: Colors.blue),
//                             onPressed: () => _sendInvite(event),
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
