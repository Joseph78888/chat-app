import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewMessage extends StatefulWidget {
  const NewMessage({super.key});

  @override
  State<NewMessage> createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// Submits the current input from the message text field.
  ///
  /// - Reads the current text from `_messageController`.
  /// - If the text is empty, the method returns immediately (no upload).
  /// - If non-empty, it clears the text field and removes focus from the input
  ///   (hiding the keyboard) to keep the UI responsive, then awaits the
  ///   asynchronous upload performed by `_uploadeMessageToFirebase`.
  ///
  /// This method is asynchronous and returns a `Future<void>`. Any exceptions
  /// thrown by `_uploadeMessageToFirebase` will propagate unless handled there.
  ///
  /// Note: This is a private helper intended to be used by the widget that
  /// owns `_messageController` and `context`.
  void _submitMessage() async {
    final enteredMessage = _messageController.text;
    if (enteredMessage.isEmpty) {
      return;
    }

    _messageController.clear();
    FocusScope.of(context).unfocus();

    await _uploadeMessageToFirebase(enteredMessage);
  }

  /// Uploads a chat message to Cloud Firestore for the currently authenticated user.
  ///
  /// This method:
  /// - Obtains the currently authenticated Firebase user (assumes a non-null user).
  /// - Retrieves the user's metadata from Firestore (username and image URL).
  /// - Adds a new document to the 'chat' collection with the following fields:
  ///   - 'text': the provided message text,
  ///   - 'createAt': the current server timestamp,
  ///   - 'userId': the authenticated user's UID,
  ///   - 'username': the user's display name from Firestore,
  ///   - 'userImage': the user's profile image URL from Firestore.
  ///
  /// Parameters:
  /// - [enteredMessage]: The message text to be stored in the chat collection.
  ///
  /// Returns:
  /// - A Future that completes when the write operation finishes (Future<void>).
  ///
  /// Throws:
  /// - May throw a runtime error if there is no authenticated user (the implementation uses a non-null assertion).
  /// - May propagate Firebase exceptions (network errors, permission denied, missing fields, etc.) originating from Firestore or the helper that fetches user data.
  ///
  /// Notes:
  /// - Ensure the caller has an authenticated Firebase user before invoking this method.
  /// - Ensure the Firestore rules allow writing to the 'chat' collection and that the expected user fields exist.
  Future<void> _uploadeMessageToFirebase(String enteredMessage) async {
    final user = FirebaseAuth.instance.currentUser!;
    DocumentSnapshot<Map<String, dynamic>> userData =
        await _getUserDataFromFirebase(user);

    FirebaseFirestore.instance.collection('chat').add({
      'text': enteredMessage,
      'createAt': Timestamp.now(),
      'userId': user.uid,
      'username': userData.data()!['userName'],
      'userImage': userData.data()!['imageUrl'],
    });
  }

  /// Retrieves the Firestore document for the provided Firebase [User].
  ///
  /// Queries the 'users' collection and returns the document whose ID matches
  /// `user.uid`. The returned snapshot contains a `Map<String, dynamic>` of the
  /// stored user fields (if the document exists).
  ///
  /// Parameters:
  /// - [user]: An authenticated Firebase `User` whose UID is used to locate the
  ///   corresponding document in Firestore. Must not be null.
  ///
  /// Returns:
  /// A [Future] that completes with a [DocumentSnapshot<Map<String, dynamic>>].
  /// If the document does not exist, the snapshot's `exists` property will be
  /// false and `data()` will return null.
  ///
  /// Throws:
  /// - [FirebaseException] if the read operation fails (e.g., due to network
  ///   issues or permission errors).
  ///
  /// Example:
  /// ```dart
  /// final snapshot = await _getUserDataFromFirebase(currentUser);
  /// if (snapshot.exists) {
  ///   final data = snapshot.data();
  ///   // use user data...
  /// }
  /// ```
  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserDataFromFirebase(
    User user,
  ) async {
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return userData;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enableSuggestions: true,
              controller: _messageController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
                // labelText: 'send message...',
                fillColor: Color.fromARGB(255, 237, 237, 237),
                filled: true,
                hintText: 'What\'s up',
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            maxRadius: 30,
            child: IconButton(
              onPressed: _submitMessage,
              icon: Icon(Icons.send, size: 35),
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
