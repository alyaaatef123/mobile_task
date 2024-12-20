import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'search_screen.dart';
import 'cart_screen.dart';
import 'sign_in.dart';
import 'products.dart';
import ' customer_orders_screen.dart'; // استيراد صفحة الطلبات

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // قائمة الشاشات المرتبطة بالشريط السفلي
  final List<Widget> _screens = [
    const HomeContent(),
    const SearchScreen(),
    const CartScreen(),
    const CustomerOrdersScreen(), // شاشة الطلبات
    const SignInScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex], // عرض الشاشة الحالية
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 4) { // تسجيل الخروج أو الذهاب لتسجيل الدخول
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              FirebaseAuth.instance.signOut();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully!')),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SignInScreen()),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignInScreen()),
              );
            }
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
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
}

class HomeContent extends StatelessWidget {
  const HomeContent({Key? key}) : super(key: key);

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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', height: 40),
            const SizedBox(width: 10),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(253, 238, 234, 0),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Categories',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('categories').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No categories found.'));
                }

                final categories = snapshot.data!.docs;

                return SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductsScreen(
                                categoryId: category.id,
                                categoryName: category['name'],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircleAvatar(
                                radius: 40,
                                backgroundColor: Color.fromARGB(252, 37, 37, 37),
                                child: Icon(
                                  Icons.category,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                category['name'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'All Products',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No products found.'));
                }

                final products = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
            ),
          ],
        ),
      ),
    );
  }
}
