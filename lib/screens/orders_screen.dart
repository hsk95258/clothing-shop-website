import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) { setState(() => _loading = false); return; }
    final res = await Supabase.instance.client
        .from('orders')
        .select('id, order_number, final_amount, order_status, created_at, order_items(product_name, quantity, price)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    setState(() { _orders = res; _loading = false; });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed': return Colors.blue;
      case 'shipped': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(title: const Text('My Orders'), backgroundColor: Colors.white),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE11D48)))
          : _orders.isEmpty
              ? const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('📦', style: TextStyle(fontSize: 60)),
                    SizedBox(height: 16),
                    Text('No orders yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('#${order['order_number']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(
                                      DateTime.parse(order['created_at']).toLocal().toString().substring(0, 10),
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('₹${order['final_amount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _statusColor(order['order_status']).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        order['order_status'],
                                        style: TextStyle(
                                          color: _statusColor(order['order_status']),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: (order['order_items'] as List).map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${item['product_name']} × ${item['quantity']}',
                                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                    Text('₹${item['price'] * item['quantity']}',
                                      style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              )).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}