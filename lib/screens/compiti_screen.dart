import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../core/api/nuvola_api_service.dart';
import '../models/compito.dart';
import '../core/utils/ui_utils.dart';

/// Schermata compiti moderna
class CompitiScreen extends StatefulWidget {
  const CompitiScreen({super.key});

  @override
  State<CompitiScreen> createState() => _CompitiScreenState();
}

class _CompitiScreenState extends State<CompitiScreen>
    with TickerProviderStateMixin {
  late final NuvolaApiService _apiService;
  bool _isLoading = true;
  List<Compito> _compiti = [];
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  String _filterType = 'all'; // 'all', 'pending', 'completed'
  Set<String> _completedCompitiIds = {};

  late AnimationController _statsAnimationController;
  late Animation<double> _statsAnimation;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _apiService = NuvolaApiService(authProvider.authService.apiClient);

    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _statsAnimation = CurvedAnimation(
      parent: _statsAnimationController,
      curve: Curves.easeOutCubic,
    );

    _loadCompletedCompiti();
    _loadCompiti();
    _statsAnimationController.forward();
  }

  Future<void> _loadCompletedCompiti() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList('completed_compiti') ?? [];
    setState(() {
      _completedCompitiIds = completed.toSet();
    });
  }

  Future<void> _saveCompletedCompiti() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'completed_compiti', _completedCompitiIds.toList());
  }

  @override
  void dispose() {
    _statsAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadCompiti() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final student = authProvider.currentStudent;

      if (student != null) {
        final compiti = await _apiService.getCompiti(student.id, _selectedDate);

        // Apply saved completion status and validate dates
        for (var compito in compiti) {
          final isPast = compito.dataConsegna
              .isBefore(DateTime.now().subtract(const Duration(days: 1)));

          if (isPast) {
            // Remove from completed if date has passed
            _completedCompitiIds.remove(compito.id.toString());
            compito.completato = false;
          } else {
            // Restore completion status
            compito.completato =
                _completedCompitiIds.contains(compito.id.toString());
          }
        }

        setState(() {
          _compiti = compiti;
        });
        await _saveCompletedCompiti();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore caricamento compiti: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleCompletato(int index) {
    final compito = _compiti[index];
    final isPast = compito.dataConsegna
        .isBefore(DateTime.now().subtract(const Duration(days: 1)));

    if (isPast) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Non puoi modificare compiti passati'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _compiti[index].completato = !_compiti[index].completato;
      final id = _compiti[index].id.toString();
      if (_compiti[index].completato) {
        _completedCompitiIds.add(id);
      } else {
        _completedCompitiIds.remove(id);
      }
    });
    _saveCompletedCompiti();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _compiti[index].completato
              ? 'Compito completato! 🎉'
              : 'Compito segnato come da fare',
        ),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Annulla',
          onPressed: () => _toggleCompletato(index),
        ),
      ),
    );
  }

  List<Compito> get _filteredCompiti {
    switch (_filterType) {
      case 'pending':
        return _compiti.where((c) => !c.completato).toList();
      case 'completed':
        return _compiti.where((c) => c.completato).toList();
      default:
        return _compiti;
    }
  }

  int get _totalCount => _compiti.length;
  int get _completedCount => _compiti.where((c) => c.completato).length;
  int get _pendingCount => _compiti.where((c) => !c.completato).length;
  int get _overdueCount => _compiti
      .where((c) => !c.completato && c.dataConsegna.isBefore(DateTime.now()))
      .length;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStatsPanel(),
        _buildCalendar(),
        _buildFilterChips(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildStatsPanel() {
    return FadeTransition(
      opacity: _statsAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Totali', _totalCount, Icons.assignment),
            Container(width: 1, height: 40, color: Colors.white30),
            _buildStatItem('Da fare', _pendingCount, Icons.pending_actions),
            Container(width: 1, height: 40, color: Colors.white30),
            _buildStatItem('Fatti', _completedCount, Icons.check_circle),
            if (_overdueCount > 0) ...[
              Container(width: 1, height: 40, color: Colors.white30),
              _buildStatItem('Scaduti', _overdueCount, Icons.warning_amber,
                  color: Colors.orange.shade200),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon,
      {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: (color ?? Colors.white).withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDate,
        selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
        calendarFormat: CalendarFormat.week,
        startingDayOfWeek: StartingDayOfWeek.monday,
        locale: 'it_IT',
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: Theme.of(context).colorScheme.primary,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          weekendTextStyle: TextStyle(
            color: Colors.red.shade300,
          ),
          outsideDaysVisible: false,
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDate = selectedDay;
            _focusedDate = focusedDay;
          });
          _loadCompiti();
        },
        onPageChanged: (focusedDay) {
          _focusedDate = focusedDay;
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('Tutti', 'all', Icons.list),
          const SizedBox(width: 8),
          _buildFilterChip('Da fare', 'pending', Icons.pending_actions),
          const SizedBox(width: 8),
          _buildFilterChip('Completati', 'completed', Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _filterType == value;
    return FilterChip(
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).textTheme.bodyLarge?.color,
      ),
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

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _filteredCompiti;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _filterType == 'completed'
                  ? Icons.sentiment_satisfied_alt
                  : Icons.assignment_turned_in_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _filterType == 'completed'
                  ? 'Nessun compito completato'
                  : 'Nessun compito per questa data',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_filterType == 'pending' && _completedCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Ottimo lavoro! Tutti i compiti sono completati! 🎉',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCompiti,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: _buildCompitoCard(filtered[index], index),
          );
        },
      ),
    );
  }

  Widget _buildCompitoCard(Compito compito, int index) {
    final isOverdue =
        !compito.completato && compito.dataConsegna.isBefore(DateTime.now());
    final color = _getSubjectColor(compito.materia);

    return RepaintBoundary(
      child: Dismissible(
        key: Key('${compito.id}_$index'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          _toggleCompletato(_compiti.indexOf(compito));
          return false;
        },
        background: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.check, color: Colors.white, size: 32),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ??
                Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border(
              left: BorderSide(color: color, width: 5),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showCompitoDetails(compito),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () =>
                              _toggleCompletato(_compiti.indexOf(compito)),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: compito.completato
                                  ? Colors.green
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: compito.completato
                                    ? Colors.green
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: compito.completato
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 18)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            compito.materia,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              decoration: compito.completato
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: compito.completato
                                  ? Theme.of(context).disabledColor
                                  : color,
                            ),
                          ),
                        ),
                        if (isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber,
                                    size: 14, color: Colors.red.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Scaduto',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      compito.descrizione,
                      style: TextStyle(
                        fontSize: 14,
                        color: compito.completato
                            ? Theme.of(context).disabledColor
                            : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (compito.docente != null) ...[
                          Icon(Icons.person_outline,
                              size: 16,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              compito.docente!,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Icon(Icons.event,
                            size: 16,
                            color:
                                Theme.of(context).textTheme.bodySmall?.color),
                        const SizedBox(width: 4),
                        Text(
                          'Consegna: ${DateFormat('dd/MM').format(compito.dataConsegna)}',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getSubjectColor(String materia) {
    // Simple hash-based color assignment
    final hash = materia.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[hash.abs() % colors.length];
  }

  void _showCompitoDetails(Compito compito) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      compito.materia,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getSubjectColor(compito.materia),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                        Icons.description, 'Descrizione', compito.descrizione),
                    const SizedBox(height: 16),
                    if (compito.docente != null)
                      _buildDetailRow(
                          Icons.person, 'Docente', compito.docente!),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Data Assegnazione',
                      DateFormat('dd MMMM yyyy', 'it_IT')
                          .format(compito.dataAssegnazione),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.event,
                      'Data Consegna',
                      DateFormat('dd MMMM yyyy', 'it_IT')
                          .format(compito.dataConsegna),
                    ),
                    if (compito.allegati != null &&
                        compito.allegati!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Allegati',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...compito.allegati!.map((allegato) => ListTile(
                            leading: const Icon(Icons.attachment),
                            title: Text(allegato),
                            dense: true,
                          )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
