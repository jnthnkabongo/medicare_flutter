import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
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
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                    const Icon(
                                      Icons.phone,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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
              ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
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
