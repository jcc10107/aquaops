import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class CustomerPaymentsScreen extends StatefulWidget {
  final List<OrderModel> myOrders;
  final Future<UserModel?> userFuture;
  final String? uid;

  const CustomerPaymentsScreen({
    super.key,
    required this.myOrders,
    required this.userFuture,
    required this.uid,
  });

  @override
  State<CustomerPaymentsScreen> createState() => _CustomerPaymentsScreenState();
}

class _CustomerPaymentsScreenState extends State<CustomerPaymentsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  Future<void> _downloadMonthlyStatement(List<OrderModel> thisMonthOrders, double totalSpent, String monthLabel) async {
    final messenger = ScaffoldMessenger.of(context);
    if (thisMonthOrders.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('No completed orders this month yet.')));
      return;
    }
    try {
      final customer = await widget.userFuture;
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pdfContext) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('AquaOps — Drink 8 Purified Water', style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Monthly Statement — $monthLabel'),
              pw.SizedBox(height: 12),
              pw.Text('Customer: ${customer?.name ?? 'N/A'}'),
              pw.Text('Email: ${customer?.email ?? 'N/A'}'),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Order #', 'Items', 'Amount'],
                data: thisMonthOrders.map((o) => [
                  '${o.createdAt.month}/${o.createdAt.day}/${o.createdAt.year}',
                  o.orderNumber,
                  o.items.isEmpty ? '-' : o.items.map((i) => '${i.quantity}x ${i.name}').join(', '),
                  'PHP ${o.totalAmount.toStringAsFixed(2)}',
                ]).toList(),
              ),
              pw.SizedBox(height: 16),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Total: PHP ${totalSpent.toStringAsFixed(2)}', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
      );
      final bytes = await doc.save();
      await Printing.sharePdf(bytes: bytes, filename: 'aquaops_statement_${monthLabel.replaceAll(' ', '_')}.pdf');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to generate statement: $e'), backgroundColor: AppColors.error));
    }
  }

  Widget _buildTransactionItem({required IconData icon, required String title, required String subtitle, required String amount, required String status, required String details, required bool isCredit}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceLowest, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 8)]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: isCredit ? AppColors.secondaryContainer : AppColors.surfaceFrost, shape: BoxShape.circle), child: Icon(icon, size: 18, color: isCredit ? AppColors.secondary : AppColors.primary)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain), overflow: TextOverflow.ellipsis),
                          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(amount, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isCredit ? AppColors.secondary : AppColors.textMain)),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: isCredit ? AppColors.surfaceFrost : AppColors.secondaryContainer, borderRadius: BorderRadius.circular(100)), child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCredit ? AppColors.primary : AppColors.secondary))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(details, style: const TextStyle(fontSize: 11, color: AppColors.outline), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              const Row(
                children: [
                  Icon(Icons.receipt, size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text('E-Receipt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonthOrders = widget.myOrders.where((o) =>
    o.status == OrderStatus.delivered &&
        o.revenueDate.year == now.year &&
        o.revenueDate.month == now.month).toList();
    final totalSpentThisMonth = thisMonthOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);
    final monthLabel = '${_monthNames[now.month - 1]} ${now.year}';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(top: 24, bottom: 100, left: 24, right: 24),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primaryContainer, AppColors.primary, AppColors.cyanElectric]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.analytics, color: AppColors.cyanHighlight, size: 20),
                        SizedBox(width: 8),
                        Text('SPENDING OVERVIEW', style: TextStyle(color: AppColors.cyanHighlight, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ],
                    ),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(100)), child: Text(monthLabel, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Spent this month', style: TextStyle(color: Colors.white70, fontSize: 11)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text('₱', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 2),
                    Text(totalSpentThisMonth.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.water_drop, color: Colors.white, size: 16)),
                            const SizedBox(width: 8),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${thisMonthOrders.length} Orders', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)), const Text('This Month', style: TextStyle(color: Colors.white70, fontSize: 10))])),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.inventory_2, color: Colors.white, size: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FutureBuilder<UserModel?>(
                                future: widget.uid == null ? null : _firestoreService.getUser(widget.uid!),
                                builder: (context, snapshot) {
                                  final count = snapshot.data?.unreturnedContainers ?? 0;
                                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$count Container${count == 1 ? '' : 's'}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)), const Text('At Your Home', style: TextStyle(color: Colors.white70, fontSize: 10))]);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Recent Transactions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textMain)),
          const SizedBox(height: 16),

          if (widget.myOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('No transactions yet.', style: TextStyle(color: AppColors.outline))),
            ),
          ...widget.myOrders.map((o) {
            final subtitle = '${o.createdAt.month}/${o.createdAt.day}/${o.createdAt.year} • ${o.paymentMethod == PaymentMethod.gcash ? 'GCash' : 'Cash'}';
            final status = o.status == OrderStatus.delivered ? 'Completed' : (o.status == OrderStatus.cancelled ? 'Cancelled' : 'Pending');
            final details = o.items.isEmpty ? '—' : o.items.map((i) => '${i.quantity}x ${i.name}').join(', ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTransactionItem(
                icon: Icons.local_shipping,
                title: 'Refill Order ${o.orderNumber}',
                subtitle: subtitle,
                amount: '-₱${o.totalAmount.toStringAsFixed(2)}',
                status: status,
                details: details,
                isCredit: false,
              ),
            );
          }),

          const SizedBox(height: 12),
          InkWell(
            onTap: () => _downloadMonthlyStatement(thisMonthOrders, totalSpentThisMonth, monthLabel),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFEAEDFF), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(width: 36, height: 36, decoration: const BoxDecoration(color: AppColors.surfaceLowest, shape: BoxShape.circle), child: const Icon(Icons.description, color: AppColors.primary, size: 20)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Download Monthly Statement', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                        Text('Includes all receipts & return credits (.PDF)', style: TextStyle(fontSize: 11, color: AppColors.textVariant)),
                      ],
                    ),
                  ),
                  const Icon(Icons.download, color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}