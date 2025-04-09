import 'package:firebase_database/firebase_database.dart';

class FirebaseSongService {
  Future<void> saveSession(String userId, Map<String, dynamic> session) async {
    final ref = FirebaseDatabase.instance.ref('users/$userId/sessions');
    final newRef = ref.push();
    await newRef.set(session);
  }
}