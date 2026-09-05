import 'dart:convert';
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
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Nie udało się pobrać statystyk: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStatCard(String title, int count, int total, Color color, IconData icon) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';

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
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: color,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Colors.grey.shade600,
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
        title: const Text('Status sieci kolejowej', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
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
          children: const [
            SizedBox(height: 100),
            Center(child: Text('Brak danych statystycznych')),
          ],
        ),
      );
    }

    final total = _stats!.totalTrains;

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Total Trains Summary Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: const Color(0xFF003366),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      'Pociągi w dobie dzisiejszej',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      total.toString(),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_stats!.date != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Data statystyk: ${app_date.formatDate(_stats!.date)}',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Statusy pociągów',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF003366),
                  ),
            ),
            const SizedBox(height: 10),

            // Grid of status cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.35,
              children: [
                _buildStatCard('W trasie', _stats!.inProgress, total, Colors.blue.shade700, Icons.directions_railway),
                _buildStatCard('Zakończone', _stats!.completed, total, Colors.green.shade700, Icons.check_circle_outline),
                _buildStatCard('Nie rozpoczęły', _stats!.notStarted, total, Colors.grey.shade700, Icons.schedule),
                _buildStatCard('Odwołane', _stats!.cancelled, total, Colors.red.shade700, Icons.cancel_outlined),
              ],
            ),
            const SizedBox(height: 10),

            // Partial cancelled full-width card
            if (_stats!.partialCancelled > 0)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Częściowo odwołane (część trasy)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      Text(
                        _stats!.partialCancelled.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Raw API Data
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                title: const Text('Pełne dane API (JSON)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ').convert(_stats!.raw),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            if (_stats!.generatedAt != null) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Wygenerowano: ${app_date.formatDateTime(_stats!.generatedAt)} (${app_date.formatDate(_stats!.generatedAt)})',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
