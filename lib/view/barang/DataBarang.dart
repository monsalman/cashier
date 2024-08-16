import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cashier/main.dart';
import 'package:cashier/view/HomePage.dart';
import 'package:cashier/view/barang/EditBarang.dart';
import 'package:cashier/view/barang/TambahBarang.dart';
import 'package:cashier/widget/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DataBarang extends StatefulWidget {
  @override
  State<DataBarang> createState() => _DataBarangState();
}

class _DataBarangState extends State<DataBarang> {
  final List<Map<String, dynamic>> list = [];
  final GlobalKey<RefreshIndicatorState> _refresh =
      GlobalKey<RefreshIndicatorState>();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _lihatData();
  }

  Future<void> _lihatData() async {
    setState(() {
      loading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('tbl_barang')
          .select('id_barang, nama_barang, stock_barang, harga_barang');

      print('Data from Supabase: $response'); // Log data

      setState(() {
        list.clear();
        list.addAll(response);
        loading = false;
      });

      print('List after update: $list'); // Log updated list
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        loading = false;
      });
    }
  }

  void dialogHapus(String id_barang, String nama_barang) {
    showDialog<void>(
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
                'Apakah yakin ingin menghapus',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '$nama_barang?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Tidak'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[800],
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Ya'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                deleteBarang(id_barang, nama_barang);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteBarang(String id_barang, String nama_barang) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('tbl_barang')
          .delete()
          .eq('id_barang', int.tryParse(id_barang) ?? id_barang);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$nama_barang telah terhapus')),
      );

      // Reload the data after deletion
      setState(() {
        _lihatData();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal menghapus $nama_barang: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Warna,
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                )),
        title: Text(
          "Data Barang",
          style: TextStyle(color: Colors.white, fontSize: 20.0),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: ((context) => TambahBarang(reload: _lihatData))));
        },
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
        backgroundColor: Warna,
      ),
      body: RefreshIndicator(
        key: _refresh,
        onRefresh: _lihatData,
        color: Warna,
        backgroundColor: Colors.white,
        child: loading
            ? Shimmerr()
            : list.isEmpty
                ? Center(child: Text('Tidak ada data'))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final x = list[i];
                      return Container(
                        margin: EdgeInsets.only(top: 10, left: 20, right: 20),
                        child: Card(
                          color: Color.fromARGB(255, 255, 255, 255),
                          child: ListTile(
                            title: Text(
                              x['nama_barang']?.toString() ??
                                  'Nama tidak tersedia',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: ${x['id_barang'] ?? 'N/A'}'),
                                Text('Stock: ${x['stock_barang'] ?? 'N/A'}'),
                                Text('Harga: Rp.${x['harga_barang'] ?? 'N/A'}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditBarang(
                                          id_barang: x['id_barang'].toString(),
                                          reload: () {
                                            setState(() {
                                              _lihatData();
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.edit),
                                ),
                                IconButton(
                                  onPressed: () {
                                    dialogHapus(
                                        x['id_barang']?.toString() ?? '',
                                        x['nama_barang'] ?? 'Barang');
                                  },
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18.0),
                                    ),
                                    elevation: 3,
                                    padding: EdgeInsets.all(8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
