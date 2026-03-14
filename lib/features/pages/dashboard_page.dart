import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/user.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  Map<String, int>? _statistics;
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserAndDashboard();
  }

  Future<void> _loadUserAndDashboard() async {
    // D'abord, charger l'utilisateur depuis le stockage
    await _authService.loadUser();

    // Puis charger les données du dashboard
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await _dbService.database;

      // Récupérer les statistiques
      final patientsResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM fiche',
      );
      final consultationsResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM diagnostique',
      );
      final medicamentsResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM medicament',
      );
      final hospitalisationsResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM occupation_lit WHERE date_fin_occupation IS NULL',
      );

      setState(() {
        _statistics = {
          'patients': patientsResult.first['count'] as int,
          'consultations': consultationsResult.first['count'] as int,
          'medicaments': medicamentsResult.first['count'] as int,
          'hospitalisations': hospitalisationsResult.first['count'] as int,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Fermer la sidebar
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      drawer: _buildSidebar(user),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildSelectedPage(),
      ),
    );
  }

  Widget _buildSidebar(User user) {
    return Drawer(
      child: Container(
        color: Colors.blue.shade50,
        child: Column(
          children: [
            // Header avec info utilisateur
            UserAccountsDrawerHeader(
              accountName: Text(
                user.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text('@${user.username}'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.blue.shade700,
                child: Text(
                  user.fullName.isNotEmpty
                      ? user.fullName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              decoration: BoxDecoration(color: Colors.blue.shade700),
            ),

            // Menu de navigation
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.dashboard,
                      color: _selectedIndex == 0
                          ? Colors.blue.shade700
                          : Colors.grey,
                    ),
                    title: Text(
                      'Tableau de bord',
                      style: TextStyle(
                        fontWeight: _selectedIndex == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedIndex == 0
                            ? Colors.blue.shade700
                            : Colors.black87,
                      ),
                    ),
                    selected: _selectedIndex == 0,
                    onTap: () => _onItemTapped(0),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.people,
                      color: _selectedIndex == 1
                          ? Colors.blue.shade700
                          : Colors.grey,
                    ),
                    title: Text(
                      'Patients',
                      style: TextStyle(
                        fontWeight: _selectedIndex == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedIndex == 1
                            ? Colors.blue.shade700
                            : Colors.black87,
                      ),
                    ),
                    selected: _selectedIndex == 1,
                    onTap: () => _onItemTapped(1),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.medical_services,
                      color: _selectedIndex == 2
                          ? Colors.blue.shade700
                          : Colors.grey,
                    ),
                    title: Text(
                      'Consultations',
                      style: TextStyle(
                        fontWeight: _selectedIndex == 2
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedIndex == 2
                            ? Colors.blue.shade700
                            : Colors.black87,
                      ),
                    ),
                    selected: _selectedIndex == 2,
                    onTap: () => _onItemTapped(2),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.medication,
                      color: _selectedIndex == 3
                          ? Colors.blue.shade700
                          : Colors.grey,
                    ),
                    title: Text(
                      'Médicaments',
                      style: TextStyle(
                        fontWeight: _selectedIndex == 3
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedIndex == 3
                            ? Colors.blue.shade700
                            : Colors.black87,
                      ),
                    ),
                    selected: _selectedIndex == 3,
                    onTap: () => _onItemTapped(3),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.local_hospital,
                      color: _selectedIndex == 4
                          ? Colors.blue.shade700
                          : Colors.grey,
                    ),
                    title: Text(
                      'Hospitalisations',
                      style: TextStyle(
                        fontWeight: _selectedIndex == 4
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedIndex == 4
                            ? Colors.blue.shade700
                            : Colors.black87,
                      ),
                    ),
                    selected: _selectedIndex == 4,
                    onTap: () => _onItemTapped(4),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.grey),
                    title: const Text('Paramètres'),
                    onTap: () => _onItemTapped(5),
                  ),
                ],
              ),
            ),

            // Footer avec rôle
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                border: Border(top: BorderSide(color: Colors.blue.shade200)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rôle: ${user.role.toUpperCase()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return _buildPatientsPage();
      case 2:
        return _buildConsultationsPage();
      case 3:
        return _buildMedicamentsPage();
      case 4:
        return _buildHospitalisationsPage();
      case 5:
        return _buildSettingsPage();
      default:
        return _buildDashboardContent();
    }
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Tableau de bord';
      case 1:
        return 'Patients';
      case 2:
        return 'Consultations';
      case 3:
        return 'Médicaments';
      case 4:
        return 'Hospitalisations';
      case 5:
        return 'Paramètres';
      default:
        return 'Tableau de bord';
    }
  }

  Widget _buildDashboardContent() {
    final user = _authService.currentUser;
    if (user == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte d'informations utilisateur
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue.shade700,
                        child: Text(
                          user.fullName.isNotEmpty
                              ? user.fullName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '@${user.username}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor(user.role),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user.role.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (user.phone != null || user.address != null) ...[
                    const SizedBox(height: 16),
                    if (user.phone != null)
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(user.phone!),
                        ],
                      ),
                    if (user.address != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(user.address!)),
                        ],
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Statistiques
          const Text(
            'Statistiques du système',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'Patients',
                _statistics?['patients'] ?? 0,
                Icons.people,
                Colors.green,
              ),
              _buildStatCard(
                'Consultations',
                _statistics?['consultations'] ?? 0,
                Icons.medical_services,
                Colors.orange,
              ),
              _buildStatCard(
                'Médicaments',
                _statistics?['medicaments'] ?? 0,
                Icons.medication,
                Colors.purple,
              ),
              _buildStatCard(
                'Hospitalisations',
                _statistics?['hospitalisations'] ?? 0,
                Icons.local_hospital,
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsPage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Gestion des Patients',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Fonctionnalité à venir'),
        ],
      ),
    );
  }

  Widget _buildConsultationsPage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_services, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Gestion des Consultations',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Fonctionnalité à venir'),
        ],
      ),
    );
  }

  Widget _buildMedicamentsPage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Gestion des Médicaments',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Fonctionnalité à venir'),
        ],
      ),
    );
  }

  Widget _buildHospitalisationsPage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_hospital, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Gestion des Hospitalisations',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Fonctionnalité à venir'),
        ],
      ),
    );
  }

  Widget _buildSettingsPage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Paramètres',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Fonctionnalité à venir'),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(36.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'medecin':
        return Colors.blue;
      case 'infirmier':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
