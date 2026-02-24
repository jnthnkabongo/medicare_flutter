import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _userUuidKey = 'logged_in_user_uuid';
  static const String _userNameKey = 'logged_in_user_name';
  static const String _userRoleKey = 'logged_in_user_role';
  
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Sauvegarder l'utilisateur connecté de façon persistante
  Future<void> saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Sauvegarder les informations essentielles
      await prefs.setString(_userUuidKey, user.uuid);
      await prefs.setString(_userNameKey, user.fullName);
      await prefs.setString(_userRoleKey, user.role);
      
      // Garder en mémoire
      _currentUser = user;
      
      print('Utilisateur sauvegardé: ${user.username} (${user.role})');
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'utilisateur: $e');
      // En cas d'erreur, on garde en mémoire au moins
      _currentUser = user;
    }
  }

  // Charger l'utilisateur depuis le stockage persistant
  Future<User?> loadUser() async {
    try {
      // Si déjà en mémoire, retourner directement
      if (_currentUser != null) {
        return _currentUser;
      }

      final prefs = await SharedPreferences.getInstance();
      final userUuid = prefs.getString(_userUuidKey);
      
      if (userUuid != null && userUuid.isNotEmpty) {
        // Récupérer les détails complets depuis la base de données
        final dbService = DatabaseService();
        final db = await dbService.database;
        
        var result = await db.rawQuery('''
          SELECT u.uuid, u.nom_utilisateur, u.nom_complet, u.telephone, u.adresse, u.date_engagement, r.nom as role
          FROM utilisateur u
          JOIN utilisateur_role ur ON u.uuid = ur.utilisateur_uuid
          JOIN role r ON ur.role_uuid = r.uuid
          WHERE u.uuid = ? AND ur.date_retrait IS NULL
        ''', [userUuid]);

        if (result.isNotEmpty) {
          _currentUser = User.fromDatabase(result.first);
          print('Utilisateur chargé depuis le stockage: ${_currentUser!.username}');
          return _currentUser;
        } else {
          // Si plus trouvé en base, nettoyer le stockage
          await clearStoredUser();
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors du chargement de l\'utilisateur: $e');
      return null;
    }
  }

  // Déconnexion avec nettoyage complet
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Nettoyer le stockage persistant
      await prefs.remove(_userUuidKey);
      await prefs.remove(_userNameKey);
      await prefs.remove(_userRoleKey);
      
      // Nettoyer la mémoire
      _currentUser = null;
      
      print('Utilisateur déconnecté et stockage nettoyé');
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
      // Forcer la déconnexion en mémoire même si erreur
      _currentUser = null;
    }
  }

  // Nettoyer uniquement les données stockées (pour la cohérence)
  Future<void> clearStoredUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userUuidKey);
      await prefs.remove(_userNameKey);
      await prefs.remove(_userRoleKey);
      print('Stockage utilisateur nettoyé');
    } catch (e) {
      print('Erreur lors du nettoyage du stockage: $e');
    }
  }

  // Vérifier si l'utilisateur a un rôle spécifique
  bool hasRole(String role) {
    return _currentUser?.role.toLowerCase() == role.toLowerCase();
  }

  // Vérifier si l'utilisateur est admin
  bool get isAdmin => hasRole('admin');

  // Mettre à jour l'utilisateur courant
  void updateUser(User user) {
    _currentUser = user;
    // Sauvegarder aussi dans le stockage persistant
    saveUser(user);
  }

  // Rafraîchir l'utilisateur depuis la base de données
  Future<void> refreshUser() async {
    if (_currentUser != null) {
      final dbService = DatabaseService();
      final db = await dbService.database;
      
      var result = await db.rawQuery('''
        SELECT u.uuid, u.nom_utilisateur, u.nom_complet, u.telephone, u.adresse, u.date_engagement, r.nom as role
        FROM utilisateur u
        JOIN utilisateur_role ur ON u.uuid = ur.utilisateur_uuid
        JOIN role r ON ur.role_uuid = r.uuid
        WHERE u.uuid = ? AND ur.date_retrait IS NULL
      ''', [_currentUser!.uuid]);

      if (result.isNotEmpty) {
        _currentUser = User.fromDatabase(result.first);
        await saveUser(_currentUser!); // Mettre à jour le stockage
        print('Utilisateur rafraîchi: ${_currentUser!.username}');
      }
    }
  }
}
