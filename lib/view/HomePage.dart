import 'package:cashier/main.dart';
import 'package:cashier/view/payment/Payment.dart';
import 'package:cashier/widget/shimmer.dart';
import 'package:cashier/widget/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, dynamic>> list = [];
  List<Map<String, dynamic>> filteredList = [];
  bool loading = true;
  String searchQuery = '';
  String? userEmail;
  int totalItems = 0;
  double totalPrice = 0;
  bool showDetails = false;
  Map<String, dynamic>? selectedItem;
  Map<String, int> selectedItems = {};
  Map<String, int> originalStock = {};

  @override
  void initState() {
    super.initState();
    _lihatData().then((_) {
      _updateTotals();
      _saveOriginalStock();
    });
    _getUserEmail();
  }

  void _saveOriginalStock() {
    for (var item in list) {
      originalStock[item['id_barang'].toString()] = item['stock_barang'];
    }
  }

  Future<void> _lihatData() async {
    setState(() {
      loading = true;
    });
    
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('tbl_barang')
          .select('id_barang, nama_barang, stock_barang, harga_barang')
          .order('nama_barang', ascending: true);

      setState(() {
        list.clear();
        list.addAll(response);
        loading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        loading = false;
      });
    }
  }

  void _filterList(String query) {
    setState(() {
      searchQuery = query;
      filteredList = list.where((item) =>
        item['nama_barang'].toString().toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  Future<void> _getUserEmail() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email;
      });
      print('Logged in user email: ${user.email}');
    }
  }

  void _updateTotals() {
    setState(() {
      totalItems = selectedItems.values.fold(0, (sum, count) => sum + count);
      totalPrice = selectedItems.entries.fold(0, (sum, entry) {
        var item = list.firstWhere((i) => i['id_barang'].toString() == entry.key);
        return sum + (item['harga_barang'] ?? 0) * entry.value;
      });
    });
  }

  void _selectItem(Map<String, dynamic> item) {
    setState(() {
      String itemId = item['id_barang'].toString();
      if (item['stock_barang'] > 0) {
        if (selectedItems.containsKey(itemId)) {
          selectedItems[itemId] = selectedItems[itemId]! + 1;
        } else {
          selectedItems[itemId] = 1;
        }
        item['stock_barang']--;
        _updateTotals();
      }
    });
  }

  void _itemsDetail() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items Detail',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: selectedItems.length,
                      itemBuilder: (context, index) {
                        String itemId = selectedItems.keys.elementAt(index);
                        int count = selectedItems[itemId]!;
                        Map<String, dynamic> item = list.firstWhere((i) => i['id_barang'].toString() == itemId);
                        return ListTile(
                          title: Text(item['nama_barang']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Price: Rp ${item['harga_barang']}'),
                              Text('Stock: ${item['stock_barang']}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: () {
                                  setModalState(() {
                                    if (count > 1) {
                                      selectedItems[itemId] = count - 1;
                                      item['stock_barang']++;
                                    } else {
                                      selectedItems.remove(itemId);
                                      item['stock_barang']++;
                                    }
                                    _updateTotals();
                                  });
                                },
                              ),
                              Text('$count'),
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () {
                                  setModalState(() {
                                    if (item['stock_barang'] > 0) {
                                      selectedItems[itemId] = count + 1;
                                      item['stock_barang']--;
                                      _updateTotals();
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Divider(),
                  Text(
                    'Total Items: $totalItems',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Total Price: Rp ${totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        child: Text('Cancel', style: TextStyle(color: Warna)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {}); // Refresh the main screen
                        },
                      ),
                      ElevatedButton(
                        child: Text('Bayar', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Warna,
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the bottom sheet
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentPage(
                                selectedItems: selectedItems,
                                totalItems: totalItems,
                                totalPrice: totalPrice,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20), // Add some space at the bottom
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Builder(
              builder: (BuildContext context) {
                return Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.menu, color: Colors.grey),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                );
              },
            ),
            SizedBox(width: 15),
            Expanded(
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: TextField(
                    cursorColor: Warna,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    ),
                    onChanged: _filterList,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: Sidebar(),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _lihatData();
                _updateTotals();
                _saveOriginalStock();
              },
              color: Warna,
              backgroundColor: Colors.white,
              child: loading
                  ? Shimmerr()
                  : ListView.builder(
                      itemCount: searchQuery.isEmpty ? list.length : filteredList.length,
                      itemBuilder: (context, i) {
                        final x = searchQuery.isEmpty ? list[i] : filteredList[i];
                        final bool isSearched = searchQuery.isNotEmpty;
                        return Container(
                          margin: EdgeInsets.only(top: 10, left: 20, right: 20),
                          child: GestureDetector(
                            onTap: () => _selectItem(x),
                            child: Card(
                              color: isSearched ? Warna : Colors.white,
                              child: ListTile(
                                title: Text(
                                  x['nama_barang']?.toString() ?? 'Nama tidak tersedia',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSearched ? Colors.white : Colors.black,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ID: ${x['id_barang'] ?? 'N/A'}',
                                      style: TextStyle(color: isSearched ? Colors.white : Colors.black),
                                    ),
                                    Text(
                                      'Stock: ${x['stock_barang'] ?? 'N/A'}',
                                      style: TextStyle(color: isSearched ? Colors.white : Colors.black),
                                    ),
                                    Text(
                                      'Harga: ${x['harga_barang'] ?? 'N/A'}',
                                      style: TextStyle(color: isSearched ? Colors.white : Colors.black),
                                    ),
                                  ],
                                ),
                                trailing: selectedItems[x['id_barang'].toString()] != null &&
                                          selectedItems[x['id_barang'].toString()]! > 0
                                    ? Text(
                                        'Selected: ${selectedItems[x['id_barang'].toString()]}',
                                        style: TextStyle(
                                          color: isSearched ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          GestureDetector(
            onTap: selectedItems.isNotEmpty ? _itemsDetail : null,
            child: Card(
              margin: EdgeInsets.all(16),
              color: selectedItems.isNotEmpty ? Warna : Warna,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                        Text('Total Items: $totalItems', style: TextStyle(color: Colors.white)),
                        Text('Harga: Rp ${totalPrice.toStringAsFixed(2)}', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    if (selectedItems.isNotEmpty)
                      Icon(Icons.arrow_forward_ios, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}