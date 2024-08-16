import 'package:cashier/view/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:cashier/main.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class ReceiptPage extends StatelessWidget {
  final Map<String, int> items;
  final double totalPrice;
  final double amountPaid;
  final double change;
  final String paymentMethod;
  final DateTime transactionDate;
  final Map<String, Map<String, dynamic>> itemDetails;

  ReceiptPage({
    required this.items,
    required this.totalPrice,
    required this.amountPaid,
    required this.change,
    required this.paymentMethod,
    required this.transactionDate,
    required this.itemDetails,
  });

  final ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd-MM-yyyy');
    final timeFormatter = DateFormat('HH:mm:ss');
    final currencyFormatter = NumberFormat("#,##0.00", "id_ID");

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Receipt', style: TextStyle(color: Colors.white)),
        backgroundColor: Warna,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Screenshot(
                controller: screenshotController,
                child: Container(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Receipt', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(height: 20),
                      Text('Items:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ...items.entries.map((entry) {
                        String itemName = itemDetails[entry.key]?['name'] ?? 'Unknown Item';
                        double itemPrice = itemDetails[entry.key]?['price'] ?? 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$itemName x${entry.value}'),
                              Text('Rp ${currencyFormatter.format(itemPrice * entry.value)}'),
                            ],
                          ),
                        );
                      }).toList(),
                      SizedBox(height: 10),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Rp ${currencyFormatter.format(totalPrice)}', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Bayar:'),
                          Text('Rp ${currencyFormatter.format(amountPaid)}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Kembali:'),
                          Text('Rp ${currencyFormatter.format(change)}'),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text('Metode Pembayaran: $paymentMethod'),
                      Text('Tanggal: ${dateFormatter.format(transactionDate)} ${timeFormatter.format(transactionDate)}'),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => HomePage()),
                  (Route<dynamic> route) => false,
                );
              },
              child: Text(
                'Back to Homepage',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Warna),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            print("Starting screenshot capture...");
            final image = await screenshotController.capture();
            print("Screenshot captured: ${image != null}");

            if (image != null) {
              // Save as file first
              final directory = await getApplicationDocumentsDirectory();
              final imagePath = '${directory.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.png';
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
        },
        child: Icon(Icons.camera_alt, color: Colors.white),
        backgroundColor: Warna,
      ),
    );
  }
}