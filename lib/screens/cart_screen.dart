
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool isSubmitting = false;

  // تحديث الكمية في Firestore
  Future<void> updateQuantity(DocumentReference itemRef, int newQuantity) async {
    if (newQuantity > 0) {
      await itemRef.update({'quantity': newQuantity});
    } else {
      await itemRef.delete(); // حذف المنتج إذا أصبحت الكمية صفر
    }
  }

  // تقديم الطلب وحفظه في Firestore
Future<void> submitOrder(List<QueryDocumentSnapshot> cartItems) async {
  setState(() {
    isSubmitting = true;
  });

  try {
    double total = cartItems.fold(
        0, (sum, item) => sum + (item['price'] * item['quantity']));
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'N/A';

    await FirebaseFirestore.instance.collection('orders').add({
      'user_id': user?.uid,
      'customer_email': userEmail,
      'items': cartItems.map((item) => item.data()).toList(),
      'total': total,
      'status': 'Pending',
      'timestamp': Timestamp.now(), // بدون إضافة rating أو feedback هنا
    });

    for (var item in cartItems) {
      await item.reference.delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order Submitted Successfully!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to submit order: $e')),
    );
  } finally {
    setState(() {
      isSubmitting = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: const Color.fromARGB(253, 238, 234, 0),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('cart')
            .where('user_id', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Your cart is empty!',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final cartItems = snapshot.data!.docs;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    int quantity = item['quantity'];

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: ListTile(
                        leading: Image.network(
                          item['image_url'] ?? '',
                          height: 50,
                          width: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image),
                        ),
                        title: Text(item['product_name']),
                        subtitle: Text(
                            'Price: \$${item['price']} x $quantity = \$${(item['price'] * quantity).toStringAsFixed(2)}'),
                    trailing: Row(
                     mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          updateQuantity(item.reference, quantity - 1);
                        },
                      ),
                      Text(quantity.toString()),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          updateQuantity(item.reference, quantity + 1);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await item.reference.delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Product removed from cart')),
                          );
                        },
                      ),
                    ],
                  ),

                      ),
                    );
                  },
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('cart')
                    .where('user_id', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final cartItems = snapshot.data!.docs;
                  double total = cartItems.fold(
                      0,
                      (sum, item) =>
                          sum + (item['price'] * item['quantity']));

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total: \$${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        isSubmitting
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: () => submitOrder(cartItems),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 12),
                                ),
                                child: const Text(
                                  'Proceed to Checkout',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}