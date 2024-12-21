import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? selectedDate;

  Future<Map<String, dynamic>> fetchReportData() async {
    QuerySnapshot ordersSnapshot =
        await FirebaseFirestore.instance.collection('orders').get();

    Map<String, int> productSales = {};
    double totalRevenue = 0.0;

    for (var order in ordersSnapshot.docs) {
      final orderData = order.data() as Map<String, dynamic>?;
      if (orderData == null || !orderData.containsKey('items')) continue;

      final items = orderData['items'] as List<dynamic>? ?? [];
      final orderTotal = (orderData['total'] ?? 0.0).toDouble();

      totalRevenue += orderTotal;

      for (var item in items) {
        if (item is Map<String, dynamic>) {
          String productName = item['product_name'] ?? 'Unknown';
          int quantity = (item['quantity'] ?? 0).toInt();

          productSales[productName] =
              (productSales[productName] ?? 0) + quantity;
        }
      }
    }

    var sortedSales = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalRevenue': totalRevenue,
      'topProducts': sortedSales,
    };
  }

  Future<List<QueryDocumentSnapshot>> fetchTransactionsOnDate(
      DateTime date) async {
    final startOfDay = Timestamp.fromDate(
        DateTime(date.year, date.month, date.day, 0, 0, 0));
    final endOfDay = Timestamp.fromDate(
        DateTime(date.year, date.month, date.day, 23, 59, 59));

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThanOrEqualTo: endOfDay)
        .get();

    return snapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chart Section
              const Text(
                'Top Selling Products (Chart):',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              FutureBuilder<Map<String, dynamic>>(
                future: fetchReportData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final data = snapshot.data ?? {};
                  final topProducts = data['topProducts']
                          as List<MapEntry<String, int>>? ??
                      [];

                  return SizedBox(
                    height: 300,
                    child: BarChart(
                      BarChartData(
                        barGroups: topProducts.asMap().entries.map(
                          (entry) {
                            int index = entry.key;
                            int quantity = entry.value.value;

                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: quantity.toDouble(),
                                  width: 16,
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                              showingTooltipIndicators: [0],
                            );
                          },
                        ).toList(),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                int index = value.toInt();
                                if (index >= 0 && index < topProducts.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      topProducts[index].key,
                                      style: const TextStyle(fontSize: 8),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: true),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.grey, width: 0.5),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Transactions by Date Section
              const Text(
                'Transactions on Specific Date:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  setState(() {
                    selectedDate = pickedDate;
                  });
                                },
                icon: const Icon(Icons.date_range),
                label: const Text('Select Date'),
              ),
              const SizedBox(height: 10),
              if (selectedDate != null)
                FutureBuilder<List<QueryDocumentSnapshot>>(
                  future: fetchTransactionsOnDate(selectedDate!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final transactions = snapshot.data ?? [];
                    if (transactions.isEmpty) {
                      return const Center(child: Text('No transactions found.'));
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction =
                            transactions[index].data() as Map<String, dynamic>;
                        final items = transaction['items'] as List<dynamic>;
                        final total = transaction['total'] ?? 0.0;

                        return Card(
                          child: ListTile(
                            title: Text(
                              'Order Total: \$${total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: items.map((item) {
                                return Text(
                                    '${item['product_name']} - Quantity: ${item['quantity']} - Price: \$${item['price']}');
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
