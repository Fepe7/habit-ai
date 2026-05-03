import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

// Sube y borra el avatar del usuario en Firebase Storage
// Path: users/{uid}/avatar.jpg (se sobreescribe, sin acumular archivos)
class AvatarStorageRepository {
  final FirebaseStorage _storage;
  final String _uid;

  AvatarStorageRepository({
    required String uid,
    FirebaseStorage? storage,
  })  : _uid = uid,
        _storage = storage ?? FirebaseStorage.instance;

  Reference get _avatarRef => _storage.ref('users/$_uid/avatar.jpg');

  Future<String> uploadAvatar(File file) async {
    final task = await _avatarRef.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await task.ref.getDownloadURL();
  }

  Future<void> deleteAvatar() async {
    try {
      await _avatarRef.delete();
    } catch (_) {
      // ignorar si el archivo no existe
    }
  }
}
