import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_product.dart';
import 'add_category.dart';
import 'edit_product.dart';
import 'edit_category.dart';
import 'reports.dart';
import 'orders_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({Key? key}) : super(key: key);

  void _navigateToProducts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProductsScreen()),
    );
  }

  void _navigateToCategories(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoriesScreen()),
    );
  }

  void _navigateToReports(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportsScreen()),
    );
  }

  void _navigateToOrders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OrdersScreen()),
    );
  }

  void _logout(BuildContext context) {
    FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/'); // توجيه للشاشة الرئيسية
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // حذف سهم الرجوع
        title: const Text('Admin Panel'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(253, 238, 234, 0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // تقسيم العناصر إلى عمودين
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildAdminCard(
              context,
              title: 'Products',
              icon: Icons.shopping_bag,
              onTap: () => _navigateToProducts(context),
            ),
            _buildAdminCard(
              context,
              title: 'Categories',
              icon: Icons.category,
              onTap: () => _navigateToCategories(context),
            ),
            _buildAdminCard(
              context,
              title: 'Reports',
              icon: Icons.bar_chart,
              onTap: () => _navigateToReports(context),
            ),
            _buildAdminCard(
              context,
              title: 'Orders',
              icon: Icons.list_alt,
              onTap: () => _navigateToOrders(context),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color.fromARGB(253, 238, 234, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.logout, color: Color.fromARGB(255, 38, 38, 38)),
              tooltip: 'Logout',
              onPressed: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context,
      {required String title, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(250, 249, 249, 249), 
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: const Color.fromARGB(252, 38, 38, 38)), 
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: Color.fromARGB(255, 36, 36, 36), 
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// شاشة عرض المنتجات
class ProductsScreen extends StatelessWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  Future<void> deleteProduct(String productId) async {
    await FirebaseFirestore.instance.collection('products').doc(productId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddProductScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final products = snapshot.data!.docs;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(product['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Price: \$${product['price']}'),
                      Text(
                        'In Stock: ${product['stock'] ?? 0} pcs',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditProductScreen(productId: product.id),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          deleteProduct(product.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Product deleted successfully!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// شاشة عرض الفئات
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  Future<void> deleteCategory(String categoryId) async {
    await FirebaseFirestore.instance.collection('categories').doc(categoryId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddCategoryScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final categories = snapshot.data!.docs;

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(category['name']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditCategoryScreen(categoryId: category.id),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          deleteCategory(category.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Category deleted successfully!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
