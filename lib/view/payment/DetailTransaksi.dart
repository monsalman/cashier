import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:cashier/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DetailTransaksiPage extends StatefulWidget {
  final Map<String, dynamic> transaction;

  DetailTransaksiPage({Key? key, required this.transaction}) : super(key: key);

  @override
  _DetailTransaksiPageState createState() => _DetailTransaksiPageState();
}

class _DetailTransaksiPageState extends State<DetailTransaksiPage> {
  final ScreenshotController screenshotController = ScreenshotController();
  Map<String, String> _itemNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItemNames();
  }

  Future<void> _loadItemNames() async {
    try {
      final response = await Supabase.instance.client
          .from('tbl_barang')
          .select('id_barang, nama_barang');

      if (response != null) {
        setState(() {
          _itemNames = {
            for (var item in response)
              item['id_barang'].toString(): item['nama_barang']
          };
          _isLoading = false;
        });
      } else {
        print('Error loading item names: No data received');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Exception when loading item names: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _captureAndSaveReceipt(BuildContext context) async {
    try {
      print("Starting screenshot capture...");
      final image = await screenshotController.capture();
      print("Screenshot captured: ${image != null}");

      if (image != null) {
        // Save as file first
        final directory = await getApplicationDocumentsDirectory();
        final imagePath =
            '${directory.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.png';
        File(imagePath).writeAsBytesSync(image);
        print("Image saved to: $imagePath");

        // Now try to save to gallery
        final result = await ImageGallerySaver.saveFile(imagePath);
        print("Gallery save result: $result");

        if (result['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Receipt saved to $result')),
          );
        } else {
          throw Exception('Failed to save image to gallery');
        }
      } else {
        throw Exception('Failed to capture screenshot');
      }
    } catch (e) {
      print("Error: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save receipt: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = jsonDecode(widget.transaction['items']);
    final formatter = NumberFormat("#,##0.00", "id_ID");
    final dateTimeFormatter = DateFormat('dd-MM-yyyy HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Transaksi'),
        backgroundColor: Warna,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Warna),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Screenshot(
                  controller: screenshotController,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transaksi ${widget.transaction['id']}',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 16),
                        Text('Items:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        ...items.entries.map((entry) => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    '${_itemNames[entry.key] ?? 'Unknown Item'} x${entry.value}'),
                                Text(
                                    'Rp ${formatter.format(double.parse(entry.value.toString()) * 3000)}'),
                              ],
                            )),
                        SizedBox(height: 20),
                        Divider(
                            thickness: 1,
                            color: Colors
                                .grey), // Added Divider// Added small spacing
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                                'Rp ${formatter.format(double.parse(widget.transaction['total_harga'].toString()))}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Bayar:'),
                            Text(
                                'Rp ${formatter.format(double.parse(widget.transaction['amount_paid'].toString()))}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Kembali:'),
                            Text(
                                'Rp ${formatter.format(double.parse(widget.transaction['change'].toString()))}'),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                            'Metode Pembayaran: ${widget.transaction['metode_pembayaran']}'),
                        Row(
                          children: [
                            Text('Tanggal: '),
                            Text(dateTimeFormatter.format(DateTime.parse(
                                widget.transaction['tanggal_transaksi']))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _captureAndSaveReceipt(context),
        child: Icon(Icons.save),
        backgroundColor: Warna,
      ),
    );
  }
}
