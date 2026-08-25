import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/obligation.dart';

class ObligationCard extends StatelessWidget {
  final Obligation obligation;
  final VoidCallback onStatusTap;
  final VoidCallback? onTap;

  const ObligationCard({
    super.key,
    required this.obligation,
    required this.onStatusTap,
    this.onTap,
  });

  /// Vraća boju vezanu uz prioritet
  Color _priorityColor(BuildContext context) {
    switch (obligation.priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData _statusIcon() {
    switch (obligation.status) {
      case 'in_progress':
        return Icons.timelapse;
      case 'done':
        return Icons.check_circle;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd.MM.yyyy.').format(obligation.dueDate);
    final isOverdue =
        obligation.status != 'done' &&
        obligation.dueDate.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: Container(width: 4, color: _priorityColor(context)),
        title: Text(
          obligation.name,
          style: obligation.status == 'done'
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Text(
          isOverdue ? 'Rok: $formattedDate (kasni!)' : 'Rok: $formattedDate',
          style: TextStyle(color: isOverdue ? Colors.red : null),
        ),
        trailing: IconButton(icon: Icon(_statusIcon()), onPressed: onStatusTap),
      ),
    );
  }
}
