import 'package:flutter/material.dart';
import '../models/order_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // USE THEME ENGINE HERE
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1), // Fixed color
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.status.name.toUpperCase(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.primary), // Fixed color
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                order.customerName,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              if (order.deliveryAddress != null)
                Text(
                  order.deliveryAddress!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₱${order.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.primary), // Fixed color
                  ),
                  Text(
                    order.paymentMethod.name.toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}