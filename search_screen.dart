import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:qr_code_scanner/qr_code_scanner.dart'; // مكتبة الـ QR Code Scanner

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchText = '';
  bool isListening = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? qrController;

  // البحث النصي
  void performSearch(String value) {
    setState(() {
      searchText = value.trim();
    });
  }

  // البحث بالصوت
  Future<void> startListening() async {
    if (!isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              searchController.text = result.recognizedWords;
              searchText = result.recognizedWords;
            });
          },
          cancelOnError: true,
        );
      }
    } else {
      _speech.stop();
      setState(() => isListening = false);
    }
  }

  // البحث بالـ QR Code
  void openQRCodeScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('QR Code Scanner')),
          body: QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
          ),
        ),
      ),
    );
  }

  // عند قراءة الـ QR Code
  void _onQRViewCreated(QRViewController controller) {
    setState(() => qrController = controller);

    controller.scannedDataStream.listen((scanData) {
      setState(() {
        searchController.text = scanData.code ?? '';
        searchText = scanData.code ?? '';
      });

      controller.dispose(); // إغلاق الكاميرا بعد القراءة
      Navigator.of(context).pop(); // العودة للشاشة السابقة
    });
  }

  @override
  void dispose() {
    qrController?.dispose();
    super.dispose();
  }

  // إضافة المنتج إلى السلة
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
        title: const Text('Search Products'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(253, 238, 234, 0),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: performSearch,
                    decoration: const InputDecoration(
                      hintText: 'Search for products...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(isListening ? Icons.mic_off : Icons.mic),
                  onPressed: startListening,
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: openQRCodeScanner,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No products found.'));
                }

                final products = snapshot.data!.docs.where((product) {
  final barcode = product['barcode']?.toString() ?? '';
  final name = product['name']?.toString().toLowerCase() ?? '';
  
  return searchText.isNotEmpty &&
         (name.contains(searchText.toLowerCase()) || barcode == searchText);
}).toList();


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
            ),
          ),
        ],
      ),
    );
  }
}
