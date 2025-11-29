import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/api/nuvola_api_service.dart';
import '../models/assenza.dart';

/// Schermata assenze
class AssenzeScreen extends StatefulWidget {
  const AssenzeScreen({super.key});

  @override
  State<AssenzeScreen> createState() => _AssenzeScreenState();
}

class _AssenzeScreenState extends State<AssenzeScreen> {
  late final NuvolaApiService _apiService;
  bool _isLoading = true;
  List<Assenza> _assenze = [];
  String _filterType = 'tutte'; // 'tutte', 'assenza', 'ritardo', 'uscita'

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _apiService = NuvolaApiService(authProvider.authService.apiClient);
    _loadAssenze();
  }

  Future<void> _loadAssenze() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final student = authProvider.currentStudent;

      if (student != null) {
        final assenze = await _apiService.getAssenze(student.id);

        setState(() {
          _assenze = assenze;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore caricamento assenze: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Assenza> get _assenzeFiltered {
    if (_filterType == 'tutte') return _assenze;
    return _assenze.where((a) => a.tipo == _filterType).toList();
  }

  int get _assenzeCount => _assenze.where((a) => a.tipo == 'assenza').length;
  int get _ritardiCount => _assenze.where((a) => a.tipo == 'ritardo').length;
  int get _usciteCount => _assenze.where((a) => a.tipo == 'uscita').length;

  IconData _getIconForType(String tipo) {
    switch (tipo) {
      case 'ritardo':
        return Icons.schedule;
      case 'uscita':
        return Icons.exit_to_app;
      default:
        return Icons.event_busy;
    }
  }

  Color _getColorForType(String tipo) {
    switch (tipo) {
      case 'ritardo':
        return Colors.orange;
      case 'uscita':
        return Colors.blue;
      default:
        return Colors.red;
    }
  }

  String _getLabelForType(String tipo) {
    switch (tipo) {
      case 'ritardo':
        return 'Ritardo';
      case 'uscita':
        return 'Uscita Anticipata';
      default:
        return 'Assenza';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stats cards
        if (!_isLoading)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                      'Assenze', _assenzeCount, Colors.red, Icons.event_busy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                      'Ritardi', _ritardiCount, Colors.orange, Icons.schedule),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                      'Uscite', _usciteCount, Colors.blue, Icons.exit_to_app),
                ),
              ],
            ),
          ),

        // Filter chips
        if (!_isLoading)
          Container(
            height: 50,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('Tutte', 'tutte'),
                const SizedBox(width: 8),
                _buildFilterChip('Assenze', 'assenza'),
                const SizedBox(width: 8),
                _buildFilterChip('Ritardi', 'ritardo'),
                const SizedBox(width: 8),
                _buildFilterChip('Uscite', 'uscita'),
              ],
            ),
          ),

        // List
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterType = value),
      backgroundColor: Theme.of(context).cardTheme.color ??
          Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primary,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.transparent : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
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
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_assenzeFiltered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Nessuna assenza trovata',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssenze,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _assenzeFiltered.length,
        itemBuilder: (context, index) {
          final assenza = _assenzeFiltered[index];
          final color = _getColorForType(assenza.tipo);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ??
                  Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(color: color, width: 4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconForType(assenza.tipo),
                  color: color,
                  size: 24,
                ),
              ),
              title: Text(
                _getLabelForType(assenza.tipo),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color),
                      const SizedBox(width: 4),
                      Text(
                        '${assenza.data.day}/${assenza.data.month}/${assenza.data.year}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (assenza.motivazione != null &&
                      assenza.motivazione!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        assenza.motivazione!,
                        style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: 13),
                      ),
                    ),
                  if (assenza.giustificata &&
                      assenza.dataGiustificazione != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 12, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Giustificata il ${assenza.dataGiustificazione!.day}/${assenza.dataGiustificazione!.month}',
                            style: TextStyle(
                                color: Colors.green.shade700, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: assenza.giustificata
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: assenza.giustificata
                        ? Colors.green.withOpacity(0.5)
                        : Colors.orange.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  assenza.giustificata ? 'Giustificata' : 'Da Giustificare',
                  style: TextStyle(
                    color: assenza.giustificata ? Colors.green : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
