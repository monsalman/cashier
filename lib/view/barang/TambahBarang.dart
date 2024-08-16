import 'package:flutter/material.dart';
import 'package:cashier/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TambahBarang extends StatefulWidget {
  final VoidCallback reload;

  const TambahBarang({Key? key, required this.reload}) : super(key: key);

  @override
  State<TambahBarang> createState() => _TambahBarangState();
}

class _TambahBarangState extends State<TambahBarang> {
  final _key = GlobalKey<FormState>();
  late TextEditingController txtNamaBarang, txtHargaBarang, txtStockBarang;

  @override
  void initState() {
    super.initState();
    txtNamaBarang = TextEditingController();
    txtHargaBarang = TextEditingController();
    txtStockBarang = TextEditingController();
  }

  void tambahBarang() async {
    if (_key.currentState!.validate()) {
      try {
        final supabase = Supabase.instance.client;
        await supabase.from('tbl_barang').insert({
          'nama_barang': txtNamaBarang.text,
          'harga_barang': double.parse(txtHargaBarang.text),
          'stock_barang': int.parse(txtStockBarang.text),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${txtNamaBarang.text} telah ditambahkan')),
        );
        widget.reload();
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan barang: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Tambah Barang",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Warna,
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _key,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: <Widget>[
            buildTextFormField(txtNamaBarang, 'Nama Barang'),
            buildTextFormField(txtStockBarang, 'Stock Barang', TextInputType.number),
            buildTextFormField(txtHargaBarang, 'Harga Barang', TextInputType.numberWithOptions(decimal: true)),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Tambah Barang', style: TextStyle(color: Colors.white)),
              onPressed: tambahBarang,
              style: ElevatedButton.styleFrom(
                backgroundColor: Warna,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextFormField(TextEditingController controller, String label, [TextInputType? keyboardType]) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Warna),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Warna),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Warna),
        ),
      ),
      cursorColor: Warna,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (keyboardType == TextInputType.number && int.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        if (keyboardType == TextInputType.numberWithOptions(decimal: true) && double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }
}