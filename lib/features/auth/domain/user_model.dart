/// Modelo de dominio que representa al usuario autenticado.
/// Separa la lógica de la app del objeto User de Firebase.
/// Si en el futuro cambiamos de proveedor de auth, solo tocamos este archivo.
class UserModel {
  final String uid;
  final String email;
  final String? displayName;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
  });
}
