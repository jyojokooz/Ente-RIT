import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/chat_service.dart';
import 'chat_room_screen.dart';

class PeerRoomsScreen extends StatefulWidget {
  const PeerRoomsScreen({super.key});

  @override
  State<PeerRoomsScreen> createState() => _PeerRoomsScreenState();
}

class _PeerRoomsScreenState extends State<PeerRoomsScreen> {
  final ChatService _chatService = ChatService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Helper to generate a default avatar if the user's photoURL is null
  String _generateDefaultAvatar(String userId) {
    return 'https://api.dicebear.com/7.x/pixel-art/png?seed=$userId';
  }

  // --- Dialog to create a new room ---
  Future<void> _showCreateRoomDialog() async {
    // This check is important. We can only create a room if a user is logged in.
    if (_currentUser == null) return;

    final roomNameController = TextEditingController();
    final passwordController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text('Create Room', style: GoogleFonts.poppins(color: Colors.white)),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                TextField(
                  controller: roomNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Room Name",
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Password",
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text('Create', style: TextStyle(color: Colors.cyan.shade400)),
              onPressed: () async {
                final name = roomNameController.text.trim();
                final password = passwordController.text.trim();

                final success = await _chatService.createRoom(name, password, _currentUser.uid);

                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();

                if (success) {
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => ChatRoomScreen(
                        roomName: name,
                        userId: _currentUser.uid,
                        userName: _currentUser.displayName ?? 'Anonymous User',
                        userProfilePicUrl: _currentUser.photoURL ?? _generateDefaultAvatar(_currentUser.uid),
                        isHost: true,
                      ),
                    ),
                  );
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room name exists or fields are empty!')));
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- Dialog to join an existing room ---
  Future<void> _showJoinRoomDialog(Room room) async {
    if (_currentUser == null) return;
    final passwordController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text('Join "${room.name}"', style: GoogleFonts.poppins(color: Colors.white)),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Password",
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text('Join', style: TextStyle(color: Colors.cyan.shade400)),
              onPressed: () async {
                final correctPassword = await _chatService.verifyPassword(room.name, passwordController.text.trim());

                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();

                if (correctPassword) {
                   if (!mounted) return;
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => ChatRoomScreen(
                        roomName: room.name,
                        userId: _currentUser.uid,
                        userName: _currentUser.displayName ?? 'Anonymous User',
                        userProfilePicUrl: _currentUser.photoURL ?? _generateDefaultAvatar(_currentUser.uid),
                        isHost: room.hostId == _currentUser.uid,
                      ),
                    ),
                  );
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect password!')));
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- Dialog to confirm deletion from the room list ---
  Future<void> _showListDeleteConfirmationDialog(String roomName) async {
    if (_currentUser == null) return;
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text('Delete Room?', style: GoogleFonts.poppins(color: Colors.white)),
          content: Text('Permanently delete the room "$roomName"?', style: const TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red.shade400)),
              onPressed: () async {
                await _chatService.deleteRoom(roomName, _currentUser.uid);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Handle the case where the user is not logged in
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            title: Text("Peer Rooms", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.grey.shade900,
            iconTheme: const IconThemeData(color: Colors.white),
            ),
        body: Center(
          child: Text('You must be logged in to use this feature.', style: GoogleFonts.poppins(color: Colors.white70)),
        ),
      );
    }

    // Main UI for logged-in users
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Internet Rooms', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Room>>(
        stream: _chatService.onRoomListChanged,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading rooms.', style: GoogleFonts.poppins(color: Colors.red)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No active rooms.\nCreate one to get started!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 18),
              ),
            );
          }

          final rooms = snapshot.data!;
          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final isMyRoom = room.hostId == _currentUser.uid;

              return Card(
                color: Colors.grey.shade900,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: Icon(Icons.group_work, color: Colors.cyan.shade400),
                  title: Text(room.name, style: GoogleFonts.poppins(color: Colors.white)),
                  onTap: () => _showJoinRoomDialog(room),
                  trailing: isMyRoom
                      ? IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                          tooltip: 'Delete your room',
                          onPressed: () => _showListDeleteConfirmationDialog(room.name),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateRoomDialog,
        label: Text('Create Room', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.cyan.shade400,
      ),
    );
  }
}