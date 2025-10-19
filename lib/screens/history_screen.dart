import 'package:flutter/material.dart';
import '../widgets/customize_appbar.dart';
import '../widgets/history_list_widget.dart';


class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Space between app bar and history container
          const SizedBox(height: 20),
          // History Header Container with rounded edges
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF004C85),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'History',
              textAlign: TextAlign.center, // Center aligned text
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // History Items List
          const Expanded(
            child: HistoryListContainer(),
          ),
        ],
      ),
    );
  }
}
