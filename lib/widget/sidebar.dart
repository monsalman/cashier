import 'package:cashier/main.dart';
import 'package:cashier/view/AllData.dart';
import 'package:cashier/view/payment/History.dart';
import 'package:cashier/view/barang/DataBarang.dart';
import 'package:cashier/view/login.dart';
import 'package:cashier/view/user/register.dart';
import 'package:cashier/view/user/DataUser.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Sidebar extends StatefulWidget {
  @override
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String? userEmail;
  String? userRole;
  String? username;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.email != null) {
      setState(() {
        userEmail = user.email;
      });
      
      try {
        final response = await Supabase.instance.client
            .from('tbl_user')
            .select('roles_user, username_user')
            .eq('email_user', user.email!)
            .single();

        if (response != null) {
          setState(() {
            userRole = response['roles_user'];
            username = response['username_user'];
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
        // Handle the error appropriately
      }
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to logout. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.65,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Warna,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (username != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Text(
                          'Haii, ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            '$username',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (userRole == 'admin' || userRole == 'petugas')
            _buildMenuItem(Icons.inventory, 'Tambah Barang', () {
              Navigator.push(context,MaterialPageRoute(builder: (context) => DataBarang()),);
          }),
          if (userRole == 'admin')
            _buildMenuItem(Icons.person_add, 'Tambah User', () {
              Navigator.push(context,MaterialPageRoute(builder: (context) => RegisterPage()),);
          }),
          if (userRole == 'admin')
            _buildMenuItem(Icons.person, 'Account', () {
              Navigator.push(context,MaterialPageRoute(builder: (context) => Userdata()),);
          }),
          if (userRole == 'admin' || userRole == 'petugas' || userRole == 'user')
          _buildMenuItem(Icons.data_usage_sharp, 'Data', () {
            Navigator.push(context,MaterialPageRoute(builder: (context) => AllData()),);
          }),
          if (userRole == 'admin' || userRole == 'petugas' || userRole == 'user')
          _buildMenuItem(Icons.history, 'History', () {
            Navigator.push(context,MaterialPageRoute(builder: (context) => HistoryPage()),);
          }),
          _buildMenuItem(Icons.logout, 'Logout', _logout),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, size: 22),
      title: Text(
        title,
        style: TextStyle(fontSize: 14),
      ),
      onTap: onTap,
    );
  }
}