import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<String, dynamic>? _product;
  bool _loading = true;
  String _selectedSize = '';
  String _selectedColor = '';
  int _quantity = 1;
  bool _addingToCart = false;

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    final res = await Supabase.instance.client
        .from('products')
        .select('*')
        .eq('id', widget.productId)
        .single();
    setState(() {
      _product = res;
      final sizes = List<String>.from(res['sizes'] ?? []);
      final colors = List<String>.from(res['colors'] ?? []);
      if (sizes.isNotEmpty) _selectedSize = sizes[0];
      if (colors.isNotEmpty) _selectedColor = colors[0];
      _loading = false;
    });
  }

  Future<void> _addToCart() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }
    if (_selectedSize.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a size')),
      );
      return;
    }
    setState(() => _addingToCart = true);
    await Supabase.instance.client.from('cart').upsert({
      'user_id': user.id,
      'product_id': _product!['id'],
      'quantity': _quantity,
      'size': _selectedSize,
      'color': _selectedColor,
    }, onConflict: 'user_id,product_id,size,color');

    setState(() => _addingToCart = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to cart!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE11D48))),
      );
    }

    final product = _product!;
    final price = product['price'];
    final originalPrice = product['original_price'];
    final hasDiscount = originalPrice != null && originalPrice > price;
    final discount = hasDiscount ? ((originalPrice - price) / originalPrice * 100).round() : 0;
    final sizes = List<String>.from(product['sizes'] ?? []);
    final colors = List<String>.from(product['colors'] ?? []);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(product['name']),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  color: const Color(0xFFF3F4F6),
                  child: const Center(child: Text('👗', style: TextStyle(fontSize: 100))),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 16, left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$discount% OFF', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  if (product['name_hindi'] != null)
                    Text(product['name_hindi'], style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 8),
                  if (product['rating'] != null && product['rating'] > 0)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text('${product['rating']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${product['review_count']} reviews', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('₹$price', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      if (hasDiscount) ...[
                        const SizedBox(width: 12),
                        Text('₹$originalPrice', style: const TextStyle(fontSize: 16, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                        const SizedBox(width: 8),
                        Text('$discount% off', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ),
                  const Text('Inclusive of all taxes', style: TextStyle(color: Colors.green, fontSize: 12)),
                  if (product['description'] != null) ...[
                    const SizedBox(height: 12),
                    Text(product['description'], style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                  if (sizes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Select Size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: sizes.map((size) => GestureDetector(
                        onTap: () => setState(() => _selectedSize = size),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _selectedSize == size ? const Color(0xFFE11D48) : Colors.grey.shade300,
                              width: _selectedSize == size ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: _selectedSize == size ? const Color(0xFFFFF1F2) : Colors.white,
                          ),
                          child: Text(
                            size,
                            style: TextStyle(
                              color: _selectedSize == size ? const Color(0xFFE11D48) : Colors.black,
                              fontWeight: _selectedSize == size ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                  if (colors.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Color: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(_selectedColor, style: const TextStyle(color: Color(0xFFE11D48), fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: colors.map((color) => GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _selectedColor == color ? const Color(0xFFE11D48) : Colors.grey.shade300,
                              width: _selectedColor == color ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            color: _selectedColor == color ? const Color(0xFFFFF1F2) : Colors.white,
                          ),
                          child: Text(
                            color,
                            style: TextStyle(
                              color: _selectedColor == color ? const Color(0xFFE11D48) : Colors.black,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Quantity: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () { if (_quantity > 1) setState(() => _quantity--); },
                              icon: const Icon(Icons.remove),
                              iconSize: 18,
                            ),
                            Text('$_quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              onPressed: () { if (_quantity < 10) setState(() => _quantity++); },
                              icon: const Icon(Icons.add),
                              iconSize: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Row(children: [Icon(Icons.local_shipping_outlined, size: 16, color: Colors.grey), SizedBox(width: 8), Text('Free delivery on orders above ₹599', style: TextStyle(fontSize: 13, color: Colors.grey))]),
                        SizedBox(height: 8),
                        Row(children: [Icon(Icons.replay_outlined, size: 16, color: Colors.grey), SizedBox(width: 8), Text('Easy 7 day returns', style: TextStyle(fontSize: 13, color: Colors.grey))]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _addingToCart ? null : _addToCart,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48)),
                child: _addingToCart
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _addingToCart ? null : () async { await _addToCart(); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFE11D48),
                  side: const BorderSide(color: Color(0xFFE11D48), width: 2),
                ),
                child: const Text('Buy Now', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}