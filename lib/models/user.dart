class User {
  final String uuid;
  final String username;
  final String fullName;
  final String role;
  final String? phone;
  final String? address;
  final String? dateEngagement;

  User({
    required this.uuid,
    required this.username,
    required this.fullName,
    required this.role,
    this.phone,
    this.address,
    this.dateEngagement,
  });

  // Créer un utilisateur à partir des données de la base de données
  factory User.fromDatabase(Map<String, dynamic> data) {
    return User(
      uuid: data['uuid'] as String,
      username: data['nom_utilisateur'] as String,
      fullName: data['nom_complet'] as String,
      role: data['role'] as String,
      phone: data['telephone'] as String?,
      address: data['adresse'] as String?,
      dateEngagement: data['date_engagement'] as String?,
    );
  }

  // Convertir en Map pour la sauvegarde
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'username': username,
      'fullName': fullName,
      'role': role,
      'phone': phone,
      'address': address,
      'dateEngagement': dateEngagement,
    };
  }

  @override
  String toString() {
    return 'User(uuid: $uuid, username: $username, fullName: $fullName, role: $role)';
  }
}
