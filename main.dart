import 'package:flutter/material.dart';
import 'ui/screens/poker_game_screen.dart';

void main() {
  runApp(const PouchApePokerApp());
}

class PouchApePokerApp extends StatelessWidget {
  const PouchApePokerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PouchApe Poker 2026 preview',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A6D9E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const ExpiryCheckWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ExpiryCheckWrapper extends StatefulWidget {
  const ExpiryCheckWrapper({super.key});

  @override
  State<ExpiryCheckWrapper> createState() => _ExpiryCheckWrapperState();
}

class _ExpiryCheckWrapperState extends State<ExpiryCheckWrapper> {
  bool _isExpired = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkExpiry();
  }

  Future<void> _checkExpiry() async {
    final now = DateTime.now();
    final expiryDate = DateTime(2026, 12, 31);

    setState(() {
      _isExpired = now.isAfter(expiryDate);
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isExpired) {
      return _buildExpiredScreen();
    }

    return const PokerGameScreen();
  }

  Widget _buildExpiredScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.red, width: 3),
            ),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Warning icon
                  const Icon(
                    Icons.lock_clock,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'Game Expired',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Message
                  const Text(
                    'The game is expired, please contact the developer at raymondlou2025@outlook.com',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Close button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}




