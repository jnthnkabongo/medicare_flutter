import 'database_service.dart';
import 'package:uuid/uuid.dart';

class InitializationService {
  static final InitializationService _instance =
      InitializationService._internal();
  factory InitializationService() => _instance;
  InitializationService._internal();

  final DatabaseService _dbService = DatabaseService();
  final Uuid _uuid = const Uuid(); // Instance UUID réutilisable

  // État d'initialisation
  bool _isInitialized = false;
  bool _hasAdmin = false;

  bool get isInitialized => _isInitialized;
  bool get hasAdmin => _hasAdmin;

  // Initialiser l'application
  Future<InitializationResult> initializeApp() async {
    try {
      print('Début de l\'initialisation de l\'application...');

      // 1. Vérifier si la base de données existe
      final dbExists = await _dbService.databaseExists();
      print('Base de données existe: $dbExists');

      if (!dbExists) {
        print(
          'La base de données sera créée automatiquement lors du premier accès',
        );
      }

      // 2. Accéder à la base de données (cela créera les tables si nécessaire)
      await _dbService.database;
      print('Base de données initialisée');

      // 3. Vérifier s'il existe un utilisateur admin
      _hasAdmin = await _dbService.hasAdminUser();
      print('Utilisateur admin existe: $_hasAdmin');

      _isInitialized = true;

      return InitializationResult(
        success: true,
        needsAdminSetup: !_hasAdmin,
        message: _hasAdmin
            ? 'Application initialisée avec succès'
            : 'Veuillez créer un utilisateur administrateur',
      );
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
      return InitializationResult(
        success: false,
        needsAdminSetup: false,
        message: 'Erreur d\'initialisation: $e',
      );
    }
  }

  // Créer un utilisateur admin par défaut
  Future<bool> createDefaultAdmin({
    required String username,
    required String fullName,
    required String password,
    String? phone,
    String? address,
  }) async {
    try {
      final db = await _dbService.database;

      // Générer des UUID
      final userUuid = _generateUUID();
      final roleUuid = _generateUUID();
      final userRoleUuid = _generateUUID();

      // Créer le rôle admin s'il n'existe pas
      await db.rawInsert(
        'INSERT OR IGNORE INTO role (uuid, id, sync, nom) VALUES (?, 1, 0, ?)',
        [roleUuid, 'admin'],
      );

      // Créer l'utilisateur
      await db.rawInsert(
        'INSERT INTO utilisateur (uuid, id, sync, nom_utilisateur, nom_complet, mot_de_passe, telephone, adresse, date_engagement) VALUES (?, 1, 0, ?, ?, ?, ?, ?, date("now"))',
        [userUuid, username, fullName, password, phone, address],
      );

      // Associer l'utilisateur au rôle admin
      await db.rawInsert(
        'INSERT INTO utilisateur_role (uuid, id, sync, utilisateur_uuid, role_uuid, date_attribution) VALUES (?, 1, 0, ?, ?, date("now"))',
        [userRoleUuid, userUuid, roleUuid],
      );

      _hasAdmin = true;
      print('Utilisateur admin créé avec succès');
      return true;
    } catch (e) {
      print('Erreur lors de la création de l\'utilisateur admin: $e');
      return false;
    }
  }

  // Générer un UUID sécurisé et unique
  String _generateUUID() {
    return _uuid.v4(); // UUID version 4 (aléatoire)
  }

  // Réinitialiser l'état
  void reset() {
    _isInitialized = false;
    _hasAdmin = false;
  }
}

// Résultat de l'initialisation
class InitializationResult {
  final bool success;
  final bool needsAdminSetup;
  final String message;

  InitializationResult({
    required this.success,
    required this.needsAdminSetup,
    required this.message,
  });
}
