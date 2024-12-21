import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController stockController = TextEditingController(); // حقل إدخال الكمية

  String? selectedCategory;
  bool isLoading = false;

  // دالة إضافة المنتج إلى Firestore
  Future<void> addProduct() async {
    if (nameController.text.isEmpty ||
        priceController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        selectedCategory == null ||
        imageUrlController.text.isEmpty ||
        barcodeController.text.isEmpty ||
        stockController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields including stock and barcode')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('products').add({
        'name': nameController.text.trim(),
        'price': double.parse(priceController.text.trim()),
        'description': descriptionController.text.trim(),
        'category_id': selectedCategory,
        'image_url': imageUrlController.text.trim(),
        'barcode': barcodeController.text.trim(),
        'stock': int.parse(stockController.text.trim()), // إضافة المخزون
        'created_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );

      // إعادة ضبط الحقول
      nameController.clear();
      priceController.clear();
      descriptionController.clear();
      imageUrlController.clear();
      barcodeController.clear();
      stockController.clear();
      setState(() {
        selectedCategory = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('categories').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final categories = snapshot.data!.docs;

                  return DropdownButton<String>(
                    value: selectedCategory,
                    hint: const Text('Select Category'),
                    isExpanded: true,
                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'Enter image URL here',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: barcodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Barcode',
                  hintText: 'Enter product barcode here',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock',
                  hintText: 'Enter stock quantity',
                ),
              ),
              const SizedBox(height: 10),
              if (imageUrlController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.network(
                    imageUrlController.text,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                  ),
                ),
              const SizedBox(height: 20),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: addProduct,
                      child: const Text('Add Product'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
