import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // لتنسيق الوقت

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  // دالة لتحديث حالة الطلب
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});

      print('Order status updated successfully!');
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No orders available'),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final items = order['items'] as List<dynamic>? ?? [];
              final total = (order['total'] ?? 0.0) as double;
              final customerEmail =
                  (order.data() as Map<String, dynamic>?)?.containsKey('customer_email') == true
                      ? order['customer_email']
                      : 'Not Provided';
              final status = order['status'] ?? 'Pending';
              final timestamp = order['timestamp'] as Timestamp;

              // اسم أول منتج باستخدام product_name
              final firstProductName = items.isNotEmpty ? items[0]['product_name'] ?? 'Unknown Item' : 'No Products';

              return Card(
                margin: const EdgeInsets.all(10),
                child: ExpansionTile(
                  title: Text(
                    firstProductName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Total: \$${total.toStringAsFixed(2)} • ${DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate())}',
                  ),
                  children: [
                    ListTile(
                      title: const Text('Customer Email'),
                      subtitle: Text(customerEmail),
                    ),
                    ListTile(
                      title: const Text('Status'),
                      subtitle: Text(status),
                      trailing: DropdownButton<String>(
                        value: status,
                        items: const [
                          DropdownMenuItem(
                            value: 'Pending',
                            child: Text('Pending'),
                          ),
                          DropdownMenuItem(
                            value: 'Delivered',
                            child: Text('Delivered'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            updateOrderStatus(order.id, value);
                          }
                        },
                      ),
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Items:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...items.map((item) {
                      final price = item['price'] ?? 0.0;
                      final quantity = item['quantity'] ?? 0;
                      final subtotal = price * quantity; // حساب السعر الكلي للعنصر
                      return ListTile(
                        title: Text(item['product_name'] ?? 'Unknown Item'),
                        subtitle: Text('Quantity: $quantity'),
                        trailing: Text(
                          '\$${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      );
                    }).toList(),
                    const Divider(),
                    // Display Ratings and Feedback for the Entire Order
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('ratings')
                          .where('order_id', isEqualTo: order.id)
                          .snapshots(),
                      builder: (context, ratingSnapshot) {
                        if (!ratingSnapshot.hasData || ratingSnapshot.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('No feedback for this order.'),
                          );
                        }

                        final ratingDocs = ratingSnapshot.data!.docs;

                        // Calculate average rating
                        final averageRating = ratingDocs
                                .map((doc) => doc['rating'] as int)
                                .reduce((a, b) => a + b) /
                            ratingDocs.length;

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Average Rating: ${averageRating.toStringAsFixed(1)} ⭐',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                            ...ratingDocs.map((rating) {
                              return ListTile(
                                title: Text('Feedback: ${rating['feedback']}'),
                                subtitle: Text(
                                    'Rating: ${rating['rating']} ⭐'),
                              );
                            }).toList(),
                          ],
                        );
                      },
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Order Total: \$${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color.fromARGB(255, 41, 41, 41),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
