import 'package:flutter/material.dart';
import 'package:cashier/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:cashier/view/payment/ReceiptPage.dart';

class PaymentPage extends StatefulWidget {
  final Map<String, int> selectedItems;
  final int totalItems;
  final double totalPrice;

  const PaymentPage({
    Key? key,
    required this.selectedItems,
    required this.totalItems,
    required this.totalPrice,
  }) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  String _paymentMethod = 'Cash';
  double _amountPaid = 0;

  Map<String, Map<String, dynamic>> _itemDetails = {};

  Future<void> _fetchItemDetails() async {
    for (String itemId in widget.selectedItems.keys) {
      final response = await Supabase.instance.client
          .from('tbl_barang')
          .select('nama_barang, harga_barang')
          .eq('id_barang', itemId)
          .single();
      
      if (response != null && response['nama_barang'] != null && response['harga_barang'] != null) {
        setState(() {
          _itemDetails[itemId] = {
            'name': response['nama_barang'],
            'price': response['harga_barang'],
          };
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchItemDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Payment', style: TextStyle(color: Colors.white),),
        backgroundColor: Warna,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected Items:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Container(
                height: 150, // Adjust this height as needed
                child: ListView.builder(
                  itemCount: widget.selectedItems.length,
                  itemBuilder: (context, index) {
                    String itemId = widget.selectedItems.keys.elementAt(index);
                    int quantity = widget.selectedItems[itemId]!;
                    Map<String, dynamic> itemDetail = _itemDetails[itemId] ?? {'name': 'Loading...', 'price': 0};
                    return ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(itemDetail['name']),
                          Text(
                            'Rp ${itemDetail['price'].toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: Text('x$quantity'),
                      dense: true,
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Total Items: ${widget.totalItems}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Total Price: Rp ${widget.totalPrice.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  labelStyle: TextStyle(color: Colors.grey),
                ),
                items: ['Cash', 'Credit Card', 'Debit Card']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _paymentMethod = newValue!;
                  });
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Amount Paid',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  labelStyle: TextStyle(color: Colors.grey),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the amount paid';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) < widget.totalPrice) {
                    return 'Amount paid must be at least the total price';
                  }
                  return null;
                },
                onSaved: (value) {
                  _amountPaid = double.parse(value!);
                },
              ),
              SizedBox(height: 35),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      child: Text('Cancel Payment', style: TextStyle(color: Warna)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      child: Text('Complete Payment', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Warna,
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      ),
                      onPressed: () {
                        // Add a slight delay before executing _submitPayment
                        Future.delayed(Duration(milliseconds: 2000), _submitPayment);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitPayment() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      try {
        // Get the current user's username
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          throw Exception('No user logged in');
        }
        final username = user.email ?? 'Unknown';

        // Calculate change
        double change = _amountPaid - widget.totalPrice;
        
        // Update stock for each item
        for (String itemId in widget.selectedItems.keys) {
          int quantityPurchased = widget.selectedItems[itemId]!;
          
          // Fetch current stock
          final response = await Supabase.instance.client
              .from('tbl_barang')
              .select('stock_barang')
              .eq('id_barang', itemId)
              .single();
          
          if (response == null || response['stock_barang'] == null) {
            throw Exception('Failed to fetch stock for item $itemId');
          }
          
          int currentStock = response['stock_barang'];
          int newStock = currentStock - quantityPurchased;
          
          if (newStock < 0) {
            throw Exception('Not enough stock for item $itemId');
          }
          
          // Update stock in database
          await Supabase.instance.client
              .from('tbl_barang')
              .update({'stock_barang': newStock})
              .eq('id_barang', itemId);
        }
        
        // Add record to tbl_history
        await Supabase.instance.client
            .from('tbl_history')
            .insert({
              'tanggal_transaksi': DateTime.now().toIso8601String(),
              'total_harga': widget.totalPrice,
              'items': jsonEncode(widget.selectedItems),
              'metode_pembayaran': _paymentMethod,
              'amount_paid': _amountPaid,
              'change': change,
              'email_user': username,
            });
        
        // Navigate to ReceiptPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiptPage(
              items: widget.selectedItems,
              totalPrice: widget.totalPrice,
              amountPaid: _amountPaid,
              change: change,
              paymentMethod: _paymentMethod,
              transactionDate: DateTime.now(),
              itemDetails: _itemDetails,
            ),
          ),
        );
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}