import 'package:cashier/main.dart';
import 'package:cashier/view/HomePage.dart';
import 'package:cashier/view/user/EditUser.dart';
import 'package:cashier/widget/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Userdata extends StatefulWidget {
  @override
  State<Userdata> createState() => _UserdataState();
}

class _UserdataState extends State<Userdata> {
  final List<Map<String, dynamic>> list = [];
  final GlobalKey<RefreshIndicatorState> _refresh =
      GlobalKey<RefreshIndicatorState>();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _lihatData();

    final user = Supabase.instance.client.auth.currentUser; // Mendapatkan pengguna saat ini
    if (user != null) {
      print("Berhasil masuk userdata: ${user.email}"); // Menambahkan print untuk email pengguna
    }
  }

  Future<void> _lihatData() async {
    setState(() {
      loading = true;
    });
    
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('tbl_user')
          .select('id_user, username_user, email_user, roles_user, password_user');

      print('Data from Supabase: $response'); // Log data

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Warna,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => 
          Navigator.push(context,MaterialPageRoute(builder: (context) => HomePage()),
          )
        ),
        title: Text(
          "Data Role",
          style: TextStyle(color: Colors.white, fontSize: 20.0),
        ),
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
                              x['username_user']?.toString() ?? 'Username tidak tersedia',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: ${x['id_user'] ?? 'N/A'}'),
                                Text('Email: ${x['email_user'] ?? 'N/A'}'),
                                Text('Role: ${x['roles_user'] ?? 'N/A'}'),
                              ],
                            ),
                            trailing: IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditUser(
                                      id_user: x['id_user'].toString(),
                                      reload: () {
                                        setState(() {
                                          _lihatData();
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(Icons.edit, color: Colors.grey),
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