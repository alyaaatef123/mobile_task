import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerOrdersScreen extends StatelessWidget {
  const CustomerOrdersScreen({Key? key}) : super(key: key);

  Future<void> submitFeedback(String orderId, int rating, String feedback) async {
    try {
      await FirebaseFirestore.instance.collection('ratings').add({
        'order_id': orderId,          // ربط التقييم بالطلب
        'user_id': FirebaseAuth.instance.currentUser?.uid, // معرّف المستخدم
        'rating': rating,             // قيمة التقييم
        'feedback': feedback,         // الملاحظات
        'timestamp': Timestamp.now(), // وقت التقديم
      });
      print('Feedback submitted successfully!');
    } catch (e) {
      print('Error submitting feedback: $e');
    }
  }

  void showFeedbackDialog(BuildContext context, String orderId) {
    final TextEditingController feedbackController = TextEditingController();
    int selectedRating = 5;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rate Your Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Rating:'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      selectedRating = index + 1;
                      (context as Element).markNeedsBuild(); // تحديث الواجهة
                    },
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: feedbackController,
                decoration: const InputDecoration(
                  labelText: 'Feedback',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                submitFeedback(orderId, selectedRating, feedbackController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(253, 238, 234, 0),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('user_id', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No orders available.'),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final items = order['items'] as List<dynamic>? ?? [];
              final total = (order['total'] ?? 0.0).toDouble();
              final status = order['status'] ?? 'Pending';

              return Card(
                margin: const EdgeInsets.all(8),
                child: ExpansionTile(
                  title: Text(
                    'Order ID: ${order.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Total: \$${total.toStringAsFixed(2)} • Status: $status',
                  ),
                  children: [
                    const Divider(),
                    ...items.map((item) {
                      return ListTile(
                        title: Text(item['product_name'] ?? 'Unknown'),
                        subtitle: Text('Quantity: ${item['quantity']}'),
                        trailing: Text('\$${item['price']}'),
                      );
                    }).toList(),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Ratings & Feedback:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('ratings')
                          .where('order_id', isEqualTo: order.id)
                          .snapshots(),
                      builder: (context, ratingSnapshot) {
                        if (!ratingSnapshot.hasData || ratingSnapshot.data!.docs.isEmpty) {
                          if (status == 'Delivered') {
                            return ElevatedButton.icon(
                              onPressed: () => showFeedbackDialog(context, order.id),
                              icon: const Icon(Icons.rate_review),
                              label: const Text('Rate Order'),
                            );
                          } else {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('No feedback available.'),
                            );
                          }
                        }

                        final ratingDocs = ratingSnapshot.data!.docs;
                        return Column(
                          children: ratingDocs.map((rating) {
                            return ListTile(
                              title: Text('Rating: ${rating['rating']} ⭐'),
                              subtitle: Text('Feedback: ${rating['feedback']}'),
                            );
                          }).toList(),
                        );
                      },
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
