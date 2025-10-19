import 'package:flutter/material.dart';

class HistoryListContainer extends StatelessWidget {
  const HistoryListContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          HistoryItem(
            address: 'Address., lorem ipsum rorororor',
          ),
          SizedBox(height: 12),
          HistoryItem(
            address: 'Address., lorem ipsum rorororor',
          ),
          SizedBox(height: 12),
          HistoryItem(
            address: 'Address., lorem ipsum rorororor',
          ),
          SizedBox(height: 12),
          HistoryItem(
            address: 'Address., lorem ipsum rorororor',
          ),
        ],
      ),
    );
  }
}

class HistoryItem extends StatelessWidget {
  final String address;

  const HistoryItem({
    super.key,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF406F92),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Big location icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF004C85).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on,
              color: Color(0xFF004C85),
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location 1',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
