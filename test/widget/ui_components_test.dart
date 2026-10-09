import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Standalone status badge widget test for Market app statuses
class StatusBadgeWidget extends StatelessWidget {
  final String status;

  const StatusBadgeWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'active':
        color = Colors.green;
        label = 'Active';
        break;
      case 'pending_payment':
        color = Colors.orange;
        label = 'Payment Pending';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

void main() {
  group('UI Components Widget Tests', () {
    testWidgets('StatusBadgeWidget displays "Active" badge correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadgeWidget(status: 'active'),
          ),
        ),
      );

      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('StatusBadgeWidget displays "Payment Pending" badge correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadgeWidget(status: 'pending_payment'),
          ),
        ),
      );

      expect(find.text('Payment Pending'), findsOneWidget);
    });
  });
}
