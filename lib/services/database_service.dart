import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  // Nom de la base de données
  static const String _databaseName = 'gestion_hopital.db';

  // Obtenir la base de données
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  // Initialiser la base de données
  Future<Database> _initDatabase() async {
    // Chemin de la base de données
    String path = join(await getDatabasesPath(), _databaseName);
    print('Chemin de la base de données: $path');

    // Ouvrir ou créer la base de données
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: _onOpen,
    );
  }

  // Créer les tables lors de la première création
  Future<void> _onCreate(Database db, int version) async {
    print('Création de la base de données et des tables...');

    // Script de création des tables pour SQLite
    final batch = db.batch();

    // Table utilisateur
    batch.execute('''
      CREATE TABLE utilisateur (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        nom_utilisateur TEXT,
        nom_complet TEXT,
        mot_de_passe TEXT,
        telephone TEXT,
        adresse TEXT,
        date_engagement TEXT
      )
    ''');

    // Table role
    batch.execute('''
      CREATE TABLE role (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        nom TEXT
      )
    ''');

    // Table utilisateur_role
    batch.execute('''
      CREATE TABLE utilisateur_role (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        utilisateur_uuid TEXT,
        role_uuid TEXT,
        date_attribution TEXT,
        date_retrait TEXT,
        FOREIGN KEY (utilisateur_uuid) REFERENCES utilisateur(uuid),
        FOREIGN KEY (role_uuid) REFERENCES role(uuid)
      )
    ''');

    // Table menu
    batch.execute('''
      CREATE TABLE menu (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        nom TEXT
      )
    ''');

    // Table role_menu
    batch.execute('''
      CREATE TABLE role_menu (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        role_uuid TEXT,
        menu_uuid TEXT,
        FOREIGN KEY (role_uuid) REFERENCES role(uuid),
        FOREIGN KEY (menu_uuid) REFERENCES menu(uuid)
      )
    ''');

    // Table fiche
    batch.execute('''
      CREATE TABLE fiche (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        nom_malade TEXT NOT NULL,
        post_nom TEXT,
        prenom TEXT,
        sexe TEXT,
        date_naissance TEXT,
        lieu_naissance TEXT,
        adresse TEXT,
        telephone TEXT,
        etat_civil TEXT,
        fonction TEXT,
        date_creation_fiche TEXT,
        etat INTEGER,
        utilisateur_uuid TEXT,
        FOREIGN KEY (utilisateur_uuid) REFERENCES utilisateur(uuid)
      )
    ''');

    // Table etat_fiche
    batch.execute('''
      CREATE TABLE etat_fiche (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        etat INTEGER,
        date_etat TEXT,
        fiche_uuid TEXT,
        utilisateur_uuid TEXT,
        FOREIGN KEY (fiche_uuid) REFERENCES fiche(uuid),
        FOREIGN KEY (utilisateur_uuid) REFERENCES utilisateur(uuid)
      )
    ''');

    // Table frais
    batch.execute('''
      CREATE TABLE frais (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        nom TEXT,
        description TEXT
      )
    ''');

    // Table cout_frais
    batch.execute('''
      CREATE TABLE cout_frais (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        frais_uuid TEXT,
        utilisateur_uuid TEXT,
        cout REAL,
        date_cout TEXT,
        FOREIGN KEY (frais_uuid) REFERENCES frais(uuid),
        FOREIGN KEY (utilisateur_uuid) REFERENCES utilisateur(uuid)
      )
    ''');

    // Table paiement
    batch.execute('''
      CREATE TABLE paiement (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        frais_uuid TEXT,
        date_paiement TEXT,
        utilisateur_uuid TEXT,
        montant_paye REAL,
        observation TEXT,
        FOREIGN KEY (frais_uuid) REFERENCES frais(uuid),
        FOREIGN KEY (utilisateur_uuid) REFERENCES utilisateur(uuid)
      )
    ''');

    // Table signe_vital
    batch.execute('''
      CREATE TABLE signe_vital (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        nom TEXT,
        description TEXT
      )
    ''');

    // Table prelevement_signe
    batch.execute('''
      CREATE TABLE prelevement_signe (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        signe_vital_uuid TEXT,
        fiche_uuid TEXT,
        valeur TEXT,
        date_heure_prelevement TEXT,
        FOREIGN KEY (signe_vital_uuid) REFERENCES signe_vital(uuid),
        FOREIGN KEY (fiche_uuid) REFERENCES fiche(uuid)
      )
    ''');

    // Table examen
    batch.execute('''
      CREATE TABLE examen (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        nom TEXT,
        description TEXT
      )
    ''');

    // Table prescription_examen
    batch.execute('''
      CREATE TABLE prescription_examen (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        fiche_uuid TEXT,
        examen_uuid TEXT,
        date_prescription TEXT,
        FOREIGN KEY (fiche_uuid) REFERENCES fiche(uuid),
        FOREIGN KEY (examen_uuid) REFERENCES examen(uuid)
      )
    ''');

    // Table resultat_examen
    batch.execute('''
      CREATE TABLE resultat_examen (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        examen_uuid TEXT,
        fiche_uuid TEXT,
        resultat TEXT,
        date_examen TEXT,
        FOREIGN KEY (examen_uuid) REFERENCES examen(uuid),
        FOREIGN KEY (fiche_uuid) REFERENCES fiche(uuid)
      )
    ''');

    // Table diagnostique
    batch.execute('''
      CREATE TABLE diagnostique (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        fiche_uuid TEXT,
        libele TEXT,
        date_diagnostique TEXT,
        FOREIGN KEY (fiche_uuid) REFERENCES fiche(uuid)
      )
    ''');

    // Table medicament
    batch.execute('''
      CREATE TABLE medicament (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        nom TEXT,
        fabriquant TEXT,
        pays_origine TEXT
      )
    ''');

    // Table prescription_medicament
    batch.execute('''
      CREATE TABLE prescription_medicament (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        fiche_uuid TEXT,
        medicament_uuid TEXT,
        prescription TEXT,
        date_prescription TEXT,
        FOREIGN KEY (fiche_uuid) REFERENCES fiche(uuid),
        FOREIGN KEY (medicament_uuid) REFERENCES medicament(uuid)
      )
    ''');

    // Table lot_medicament
    batch.execute('''
      CREATE TABLE lot_medicament (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        medicament_uuid TEXT,
        quantite INTEGER,
        date_fabrication TEXT,
        date_expiration TEXT,
        date_entree_pharmacie TEXT,
        FOREIGN KEY (medicament_uuid) REFERENCES medicament(uuid)
      )
    ''');

    // Table chambre
    batch.execute('''
      CREATE TABLE chambre (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        numero TEXT,
        reference TEXT
      )
    ''');

    // Table lit
    batch.execute('''
      CREATE TABLE lit (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        chambre_uuid TEXT,
        numero INTEGER,
        FOREIGN KEY (chambre_uuid) REFERENCES chambre(uuid)
      )
    ''');

    // Table occupation_lit
    batch.execute('''
      CREATE TABLE occupation_lit (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        lit_uuid TEXT,
        fiche_uuid TEXT,
        date_debut_occupation TEXT,
        date_fin_occupation TEXT,
        observation TEXT,
        FOREIGN KEY (lit_uuid) REFERENCES lit(uuid),
        FOREIGN KEY (fiche_uuid) REFERENCES fiche(uuid)
      )
    ''');

    // Table soins
    batch.execute('''
      CREATE TABLE soins (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        nom TEXT,
        description TEXT
      )
    ''');

    // Table soins_administrer
    batch.execute('''
      CREATE TABLE soins_administrer (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        sync INTEGER,
        fiche_uuid TEXT,
        soin_uuid TEXT,
        date_administration TEXT,
        heure_administration TEXT,
        FOREIGN KEY (fiche_uuid) REFERENCES fiche(uuid),
        FOREIGN KEY (soin_uuid) REFERENCES soins(uuid)
      )
    ''');

    await batch.commit();
    print('Base de données créée avec succès');
  }

  // Appelé à chaque ouverture de la base de données
  Future<void> _onOpen(Database db) async {
    print('Base de données ouverte');
  }

  // Vérifier si la base de données existe
  Future<bool> databaseExists() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await databaseFactory.databaseExists(path);
  }

  // Vérifier s'il existe au moins un utilisateur admin
  Future<bool> hasAdminUser() async {
    try {
      final db = await database;
      var result = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM utilisateur u 
        JOIN utilisateur_role ur ON u.uuid = ur.utilisateur_uuid 
        JOIN role r ON ur.role_uuid = r.uuid 
        WHERE r.nom = 'admin' AND ur.date_retrait IS NULL
      ''');

      final count = result.first['count'] as int;
      return count > 0;
    } catch (e) {
      print('Erreur lors de la vérification des utilisateurs admin: $e');
      return false;
    }
  }

  // Fermer la base de données
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Supprimer la base de données (pour les tests)
  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
