import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/api/nuvola_api_service.dart';
import '../models/materia_voti.dart';
import '../models/frazione_temporale.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/utils/ui_utils.dart';
import 'subject_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/grade_streak_service.dart';
import 'streak_level_up_dialog.dart';

class VotiScreen extends StatefulWidget {
  const VotiScreen({super.key});

  @override
  State<VotiScreen> createState() => _VotiScreenState();
}

class _VotiScreenState extends State<VotiScreen> {
  late final NuvolaApiService _apiService;
  late final GradeStreakService _streakService;
  bool _isLoading = true;
  List<MateriaVoti> _materieVoti = [];
  int? _frazioneId;
  int _currentStreak = 0;
  List<FrazioneTemporale> _frazioni = [];
  FrazioneTemporale? _selectedFrazione;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _apiService = NuvolaApiService(authProvider.authService.apiClient);
    _initStreakService();
    _loadVoti();
  }

  Future<void> _initStreakService() async {
    final prefs = await SharedPreferences.getInstance();
    _streakService = GradeStreakService(prefs);
    if (mounted) {
      final streak = await _streakService.getStreak();
      setState(() => _currentStreak = streak);
    }
  }

  Future<void> _loadVoti() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final student = authProvider.currentStudent;

      if (student != null) {

        if (_frazioni.isEmpty) {
          _frazioni =
              await _apiService.getFrazioniTemporaliTyped(student.id);
          if (_frazioni.isNotEmpty) {
            _selectedFrazione = _frazioni.firstWhere(
              (f) => f.corrente,
              orElse: () => _frazioni.last,
            );
          }
        }

        _frazioneId = _selectedFrazione?.id;

        final materieVoti = await _apiService.getMaterieConVoti(
          student.id,
          frazioneId: _frazioneId,
        );

        final prefs = await SharedPreferences.getInstance();
        final streakService = GradeStreakService(prefs);

        final update =
            await streakService.checkAndUpdateStreak(student.id, materieVoti);

        if (mounted) {
          setState(() {
            _materieVoti = materieVoti;
            if (update != null) {
              _currentStreak = update.newStreak;
            }
          });

          if (update != null && update.didIncrease) {
            _showStreakAnimation(update.newStreak);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore caricamento voti: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showStreakAnimation(int newStreak) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StreakLevelUpDialog(streak: newStreak),
    );
  }

  double? _calcolaMediaGenerale() {
    final mediaMaterie = _materieVoti
        .map((m) => double.tryParse(m.media?.replaceAll(',', '.') ?? ''))
        .whereType<double>()
        .toList();

    if (mediaMaterie.isEmpty) return null;

    return mediaMaterie.reduce((a, b) => a + b) / mediaMaterie.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_materieVoti.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.grade,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Nessun voto disponibile',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    final mediaGenerale = _calcolaMediaGenerale();
    final allVoti = _materieVoti.expand((m) => m.voti).toList();
    allVoti.sort((a, b) => b.data.compareTo(a.data));

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _loadVoti,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 80 + MediaQuery.paddingOf(context).bottom),
        children: [

          if (_frazioni.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Material(
                color: Colors.transparent,
                child: Row(
                  spacing: 8,
                  children: _frazioni.map((frazione) {
                    final isSelected =
                        _selectedFrazione?.id == frazione.id;
                    return ChoiceChip(
                      label: Text(frazione.nome),
                      selected: isSelected,
                      onSelected: (_) async {
                        if (!isSelected) {
                          setState(() => _selectedFrazione = frazione);
                          await _loadVoti();
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            ),

          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 20),
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Media Generale',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mediaGenerale?.toStringAsFixed(2) ?? '-',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _currentStreak > 0
                                ? Icons.local_fire_department
                                : Icons.analytics_outlined,
                            color: _currentStreak > 0
                                ? Colors.orangeAccent
                                : Colors.white,
                            size: 32,
                          ),
                          if (_currentStreak > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              '$_currentStreak',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                SizedBox(
                  height: 120,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: allVoti.length.toDouble() - 1,
                      minY: 0,
                      maxY: 10,
                      lineBarsData: [
                        LineChartBarData(
                          spots: allVoti.asMap().entries.map((e) {
                            final val = double.tryParse(e.value.valore
                                    .replaceAll(',', '.')
                                    .replaceAll('½', '.5')) ??
                                0;
                            return FlSpot(e.key.toDouble(), val);
                          }).toList(),
                          isCurved: true,
                          color: Colors.white,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            cacheExtent: 500,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _materieVoti.length,
            itemBuilder: (context, index) {
              final materiaVoti = _materieVoti[index];
              final media = double.tryParse(
                  materiaVoti.media?.replaceAll(',', '.') ?? '');
              final hasInsufficientAverage = media != null && media < 6;
              final color = media != null
                  ? UiUtils.getVotoColor(media.toString())
                  : Colors.grey;

              final delay = (index * 60).clamp(0, 480);
              return TweenAnimationBuilder<double>(
                key: ValueKey(materiaVoti.id),
                duration: Duration(milliseconds: 400 + delay),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Transform.translate(
                  offset: Offset(0, 24 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                ),
                child: RepaintBoundary(
                child: Hero(
                  tag: 'subject_${materiaVoti.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: () {
                        if (_frazioneId != null) {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      SubjectDetailScreen(
                                materia: materiaVoti,
                                materiaId: materiaVoti.id,
                                frazioneId: _frazioneId!,
                              ),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOutCubic;

                                var tween = Tween(begin: begin, end: end)
                                    .chain(CurveTween(curve: curve));
                                var offsetAnimation = animation.drive(tween);

                                return SlideTransition(
                                  position: offsetAnimation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: hasInsufficientAverage
                                ? Colors.red.shade300
                                : color.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.book,
                                      color: color,
                                      size: 24,
                                    ),
                                  ),
                                  if (hasInsufficientAverage)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.warning_rounded,
                                        color: Colors.red.shade700,
                                        size: 16,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                materiaVoti.materia,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.color,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Media',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color,
                                        ),
                                      ),
                                      Text(
                                        media?.toStringAsFixed(2) ?? '-',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${materiaVoti.conteggioVoti} voti',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: color,
                                      ),
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
              ),
            );
            },
          ),
        ],
      ),
    ),
  );
  }
}
