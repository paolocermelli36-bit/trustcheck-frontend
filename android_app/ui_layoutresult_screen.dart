import 'package:flutter/material.dart';

class MicroboResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  MicroboResultScreen({required this.result});

  @override
  Widget build(BuildContext context) {
    final query = result["query"] ?? "N/A";
    final total = result["total_results"] ?? 0;
    final negatives = result["negative_results"] ?? 0;
    final level = result["level"] ?? "N/A";
    final List<dynamic> links = result["results"] ?? [];

    // Microbo icona semaforo
    Widget microboIcon;
    Color riskColor;

    if (level == "LOW") {
      microboIcon = Icon(Icons.sentiment_satisfied, size: 60, color: Colors.green);
      riskColor = Colors.green;
    } else if (level == "MEDIUM") {
      microboIcon = Icon(Icons.sentiment_neutral, size: 60, color: Colors.orange);
      riskColor = Colors.orange;
    } else {
      microboIcon = Icon(Icons.sentiment_very_dissatisfied, size: 60, color: Colors.red);
      riskColor = Colors.red;
    }

    return Scaffold(
      appBar: AppBar(title: Text("Risultati per: $query")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                microboIcon,
                SizedBox(width: 12),
                Text(
                  "Rischio: $level",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: riskColor),
                ),
              ],
            ),
            SizedBox(height: 20),

            Text("Totale risultati: $total"),
            Text(
              "Risultati negativi: $negatives",
              style: TextStyle(
                color: negatives == 0
                    ? Colors.green
                    : (negatives <= 3 ? Colors.orange : Colors.red),
              ),
            ),
            SizedBox(height: 20),

            Text("Link trovati:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: links.length,
                itemBuilder: (context, index) {
                  final item = links[index];
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      title: Text(
                        item["title"] ?? "Titolo mancante",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        item["url"] ?? "",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
