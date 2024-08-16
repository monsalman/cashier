import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:cashier/main.dart';
import 'package:cashier/widget/shimmer.dart';
import 'package:cashier/view/payment/DetailTransaksi.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _historyData = [];
  Map<String, String> _itemNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
  }

  Future<void> _fetchHistoryData() async {
    try {
      final response = await Supabase.instance.client
          .from('tbl_history')
          .select()
          .order('tanggal_transaksi', ascending: false);

      if (response != null) {
        _historyData = List<Map<String, dynamic>>.from(response);
        await _fetchItemNames();
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching history data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchItemNames() async {
    Set<String> itemIds = {};
    for (var transaction in _historyData) {
      Map<String, dynamic> items = jsonDecode(transaction['items']);
      itemIds.addAll(items.keys);
    }

    for (String itemId in itemIds) {
      try {
        final response = await Supabase.instance.client
            .from('tbl_barang')
            .select('nama_barang')
            .eq('id_barang', itemId)
            .single();
        
        if (response != null && response['nama_barang'] != null) {
          _itemNames[itemId] = response['nama_barang'];
        }
      } catch (e) {
        print('Error fetching item name for ID $itemId: $e');
      }
    }
  }

  Future<void> _showDeleteConfirmation(int transactionId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'Apakah Anda yakin ingin menghapus transaksi ini?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Batal'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[800],
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Hapus'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTransaction(transactionId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTransaction(int transactionId) async {
    try {
      await Supabase.instance.client
          .from('tbl_history')
          .delete()
          .eq('id', transactionId);

      setState(() {
        _historyData.removeWhere((transaction) => transaction['id'] == transactionId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaksi berhasil dihapus')),
      );
    } catch (e) {
      print('Error deleting transaction: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus transaksi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd-MM-yyyy HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: Text('History Transaksi'),
        backgroundColor: Warna, 
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Warna),
              ),
            )
          : ListView.builder(
              itemCount: _historyData.length,
              itemBuilder: (context, index) {
                final transaction = _historyData[index];
                final items = jsonDecode(transaction['items']);
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: Stack(
                    children: [
                      ListTile(
                        title: Text('Transaksi ${transaction['id']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('List Items:'),
                            ...items.entries.map((entry) => Text('  ${_itemNames[entry.key] ?? 'Unknown Item'}: ${entry.value}')),
                            Text('Total: Rp ${transaction['total_harga'].toStringAsFixed(2)}'),
                            Text('Bayar: Rp ${transaction['amount_paid'].toStringAsFixed(2)}'),
                            Text('Kembali: Rp ${transaction['change'].toStringAsFixed(2)}'),
                            Text('Metode Pembayaran: ${transaction['metode_pembayaran']}'),
                            Text('email: ${transaction['email_user'] ?? 'Unknown User'}'),
                            Text('Tanggal: ${dateFormatter.format(DateTime.parse(transaction['tanggal_transaksi']))}'),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailTransaksiPage(transaction: transaction),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                            ),
                            elevation: 3,
                            padding: EdgeInsets.all(8),
                          ),
                          onPressed: () => _showDeleteConfirmation(transaction['id']),
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