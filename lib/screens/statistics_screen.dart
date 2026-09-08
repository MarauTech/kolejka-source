import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../utils/date_utils.dart' as app_date;

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  OperationStatistics? _stats;
  DateTime? _lastRefreshed;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = context.read<AppState>();
      final stats = await appState.getOperationStatistics();

      if (mounted) {
        setState(() {
          _stats = stats;
          _lastRefreshed = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Nie udało się odświeżyć statusu sieci. Spróbuj ponownie.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStatCard(
      String title, int count, double? percentage, Color color, IconData icon) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: color,
                      ),
                    )),
                if (percentage != null)
                  Text(
                    '${percentage.toStringAsFixed(1).replaceAll('.', ',')}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status sieci kolejowej',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadStats,
            tooltip: 'Odśwież',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final success = Color(dark ? 0xFF81C784 : 0xFF23733C);
    final warning = Color(dark ? 0xFFFFB74D : 0xFF955300);

    if (_isLoading && _stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _stats == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadStats,
                child: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        ),
      );
    }

    if (_stats == null) {
      return RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            Center(
              child: Text(
                'Brak danych statystycznych',
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            ),
          ],
        ),
      );
    }

    final total = _stats!.totalTrains;
    final shares = _stats!.percentages;

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_errorMessage ?? 'Połączono z API PLK'),
            if (_lastRefreshed != null)
              Text(
                  'Ostatnie odświeżenie: ${app_date.formatDateTime(_lastRefreshed!.toIso8601String())}'),
            Text(_stats!.generatedAt == null
                ? 'Brak informacji o aktualności danych'
                : 'Dane z: ${app_date.formatDate(_stats!.generatedAt)} ${app_date.formatDateTime(_stats!.generatedAt)}'),
            const SizedBox(height: 12),
            // Total Trains Summary Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: theme.colorScheme.primary,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'Pociągi w dobie dzisiejszej',
                      style: TextStyle(
                          color: theme.colorScheme.onPrimary, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      total.toString(),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    if (_stats!.date != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Data statystyk: ${app_date.formatDate(_stats!.date)}',
                        style: TextStyle(
                            color: theme.colorScheme.onPrimary, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Statusy pociągów',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            if (shares == null && total > 0)
              const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                      'Podział statusów jest niepełny. Pokazujemy dostępne liczby.')),

            // Grid of status cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 155,
              children: [
                _buildStatCard(
                    'W trasie',
                    _stats!.inProgress,
                    shares?['inProgress'],
                    theme.colorScheme.primary,
                    Icons.directions_railway),
                _buildStatCard('Zakończone', _stats!.completed,
                    shares?['completed'], success, Icons.check_circle_outline),
                _buildStatCard(
                    'Nie rozpoczęły',
                    _stats!.notStarted,
                    shares?['notStarted'],
                    theme.colorScheme.onSurfaceVariant,
                    Icons.schedule),
                _buildStatCard(
                    'Odwołane',
                    _stats!.cancelled,
                    shares?['cancelled'],
                    theme.colorScheme.error,
                    Icons.cancel_outlined),
              ],
            ),
            const SizedBox(height: 10),

            // Partial cancelled full-width card
            if (_stats!.partialCancelled > 0)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: warning.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.warning_amber_rounded,
                            size: 18, color: warning),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Częściowo odwołane (część trasy)',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      Text(
                        '${_stats!.partialCancelled}${shares == null ? '' : ' · ${shares['partialCancelled']!.toStringAsFixed(1).replaceAll('.', ',')}%'}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: warning),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            if (_stats!.generatedAt != null) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Wygenerowano: ${app_date.formatDateTime(_stats!.generatedAt)} (${app_date.formatDate(_stats!.generatedAt)})',
                  style:
                      TextStyle(color: theme.colorScheme.outline, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
