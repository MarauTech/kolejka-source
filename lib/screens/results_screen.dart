import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/train_card.dart';
import 'train_details_screen.dart';

class ResultsScreen extends StatelessWidget {
  final List<ConnectionResult> results;
  final String fromStationName;
  final String toStationName;
  final String date;

  const ResultsScreen({
    super.key,
    required this.results,
    required this.fromStationName,
    required this.toStationName,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$fromStationName → $toStationName',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              date,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
      body: results.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'Nie znaleziono połączeń',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Spróbuj zmienić datę lub godzinę wyszukiwania.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                return TrainCard(
                  connection: result,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrainDetailsScreen(result: result),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
