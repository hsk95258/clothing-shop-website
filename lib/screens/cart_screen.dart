import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> _cartItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  Future<void> _fetchCart() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) { setState(() => _loading = false); return; }
    final res = await Supabase.instance.client
        .from('cart')
        .select('id, quantity, size, color, products(id, name, price, images)')
        .eq('user_id', user.id);
    setState(() { _cartItems = res; _loading = false; });
  }

  Future<void> _removeItem(String cartId) async {
    await Supabase.instance.client.from('cart').delete().eq('id', cartId);
    setState(() => _cartItems.removeWhere((i) => i['id'] == cartId));
  }

  double get _subtotal => _cartItems.fold(0, (sum, item) => sum + (item['products']['price'] * item['quantity']));
  double get _delivery => _subtotal >= 599 ? 0 : 49;
  double get _total => _subtotal + _delivery;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('My Cart (${_cartItems.length})'),
        backgroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE11D48)))
          : _cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🛒', style: TextStyle(fontSize: 60)),
                      const SizedBox(height: 16),
                      const Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Add some products to get started', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(child: Text('👗', style: TextStyle(fontSize: 30))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['products']['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text('${item['size']} • ${item['color']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(height: 4),
                                      Text('₹${item['products']['price']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text('₹${item['products']['price'] * item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () => _removeItem(item['id']),
                                      child: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -2))],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                              Text('₹${_subtotal.toStringAsFixed(0)}'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Delivery', style: TextStyle(color: Colors.grey)),
                              Text(_delivery == 0 ? 'FREE' : '₹${_delivery.toStringAsFixed(0)}',
                                style: TextStyle(color: _delivery == 0 ? Colors.green : Colors.black)),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('₹${_total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {},
                              child: Text('Proceed to Checkout — ₹${_total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}