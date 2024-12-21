import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_screen.dart';
import 'search_screen.dart';
import 'sign_in.dart';
import 'home_screen.dart';
import ' customer_orders_screen.dart'; // استيراد صفحة الطلبات

class ProductsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const ProductsScreen({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),   // الشاشة الرئيسية
    const SearchScreen(), // البحث
    const CartScreen(),   // السلة
    const CustomerOrdersScreen(), // شاشة الطلبات
    const SignInScreen(), // تسجيل الدخول
  ];

  Future<void> addToCart(BuildContext context, Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add products to the cart!')),
      );
      return;
    }

    try {
      final cartQuery = await FirebaseFirestore.instance
          .collection('cart')
          .where('user_id', isEqualTo: user.uid)
          .where('product_id', isEqualTo: product['id'])
          .get();

      if (cartQuery.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('cart').add({
          'user_id': user.uid,
          'product_id': product['id'],
          'product_name': product['name'],
          'price': product['price'],
          'image_url': product['image_url'],
          'quantity': 1,
          'added_at': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added to cart successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product already exists in the cart!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
              title: Text(widget.categoryName),
              centerTitle: true,
              backgroundColor: const Color.fromARGB(253, 238, 234, 0),
            )
          : null, // إخفاء AppBar عند البحث أو السلة
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildProductsView(), // عرض المنتجات في صفحة الفئات
          _screens[1],          // البحث
          _screens[2],          // السلة
          _screens[3],          // الطلبات
          _screens[4],          // تسجيل الدخول
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color.fromARGB(253, 238, 234, 0),
        selectedItemColor: const Color.fromARGB(255, 49, 49, 49),
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
           const BottomNavigationBarItem(
            icon: Icon(Icons.receipt), // أيقونة الطلبات
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              FirebaseAuth.instance.currentUser != null ? Icons.logout : Icons.login,
            ),
            label: FirebaseAuth.instance.currentUser != null ? 'Logout' : 'Sign in',
          ),
        ],
      ),
    );
  }

  Widget _buildProductsView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('category_id', isEqualTo: widget.categoryId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No Products Available'));
        }

        final products = snapshot.data!.docs;

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: ListTile(
                leading: Image.network(
                  product['image_url'] ?? '',
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                ),
                title: Text(
                  product['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '\$${product['price']}',
                  style: const TextStyle(color: Colors.green, fontSize: 16),
                ),
                trailing: ElevatedButton.icon(
                  onPressed: () {
                    addToCart(context, {
                      'id': product.id,
                      'name': product['name'],
                      'price': product['price'],
                      'image_url': product['image_url'],
                    });
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
