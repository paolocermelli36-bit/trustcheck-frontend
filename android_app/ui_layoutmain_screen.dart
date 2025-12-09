import 'package:flutter/material.dart';
import '../logic/logicapp_logic.dart';
import 'ui_layoutresult_screen.dart';

class MicroboMainScreen extends StatefulWidget {
  @override
  _MicroboMainScreenState createState() => _MicroboMainScreenState();
}

class _MicroboMainScreenState extends State<MicroboMainScreen> {
  final TextEditingController _controller = TextEditingController();
  bool isLoading = false;

  void startAnalyze() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final result = await analyzeReputation(input);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MicroboResultScreen(result: result),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Microbo Reputation Scanner")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "Nome o Azienda",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : startAnalyze,
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("ANALIZZA ORA"),
            ),
          ],
        ),
      ),
    );
  }
}
