import 'package:flutter/material.dart';
import 'package:cashier/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditBarang extends StatefulWidget {
  final VoidCallback reload;
  final String id_barang;

  const EditBarang({Key? key, required this.id_barang, required this.reload}) : super(key: key);

  @override
  State<EditBarang> createState() => _EditBarangState();
}

class _EditBarangState extends State<EditBarang> {
  final _key = GlobalKey<FormState>();
  late TextEditingController txtNamaBarang, txtHargaBarang, txtStockBarang;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    txtNamaBarang = TextEditingController();
    txtHargaBarang = TextEditingController();
    txtStockBarang = TextEditingController();
    loadBarangData();
  }

  Future<void> loadBarangData() async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('tbl_barang')
          .select()
          .eq('id_barang', int.tryParse(widget.id_barang) ?? widget.id_barang)
          .single();
      
      setState(() {
        txtNamaBarang.text = response['nama_barang'];
        txtHargaBarang.text = response['harga_barang'].toString();
        txtStockBarang.text = response['stock_barang'].toString();
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load barang data: ${e.toString()}')),
      );
      Navigator.pop(context);
    }
  }

  void updateBarang() async {
    if (_key.currentState!.validate()) {
      try {
        final supabase = Supabase.instance.client;
        await supabase.from('tbl_barang').update({
          'nama_barang': txtNamaBarang.text,
          'harga_barang': double.parse(txtHargaBarang.text),
          'stock_barang': int.parse(txtStockBarang.text),
        }).eq('id_barang', int.tryParse(widget.id_barang) ?? widget.id_barang);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${txtNamaBarang.text} telah diupdate')),
        );
        widget.reload();
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update barang: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Barang",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Warna,
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Warna))
          : Form(
              key: _key,
              child: ListView(
                padding: EdgeInsets.all(16.0),
                children: <Widget>[
                  buildTextFormField(txtNamaBarang, 'Nama Barang'),
                  buildTextFormField(txtStockBarang, 'Stock Barang', TextInputType.number),
                  buildTextFormField(txtHargaBarang, 'Harga Barang', TextInputType.numberWithOptions(decimal: true)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    child: Text('Update Barang', style: TextStyle(color: Colors.white)),
                    onPressed: updateBarang,
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