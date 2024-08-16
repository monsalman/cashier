import 'package:flutter/material.dart';
import 'package:cashier/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditUser extends StatefulWidget {
  final VoidCallback reload;
  final String id_user;

  const EditUser({Key? key, required this.id_user, required this.reload}) : super(key: key);

  @override
  State<EditUser> createState() => _EditUserState();
}

class _EditUserState extends State<EditUser> {
  final _key = GlobalKey<FormState>();
  late TextEditingController txtUsernameUser;
  late TextEditingController txtRolesUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    txtUsernameUser = TextEditingController();
    txtRolesUser = TextEditingController();
    loadDataUser();
  }

  Future<void> loadDataUser() async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('tbl_user')
          .select()
          .eq('id_user', int.tryParse(widget.id_user) ?? widget.id_user)
          .single();
      
      setState(() {
        txtUsernameUser.text = response['username_user'].toString();
        txtRolesUser.text = response['roles_user'].toString();
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal Load data User: ${e.toString()}')),
      );
      Navigator.pop(context);
    }
  }

  void updateUser() async {
    if (_key.currentState!.validate()) {
      try {
        final supabase = Supabase.instance.client;
        await supabase.from('tbl_user').update({
          'username_user': txtUsernameUser.text,
          'roles_user': txtRolesUser.text,
        }).eq('id_user', int.tryParse(widget.id_user) ?? widget.id_user);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User username and role have been updated')),
        );
        widget.reload();
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update user: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit User",
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
                  buildTextFormField(txtUsernameUser, 'Username'),
                  SizedBox(height: 20),
                  buildTextFormField(txtRolesUser, 'Role'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    child: Text('Update User', style: TextStyle(color: Colors.white)),
                    onPressed: updateUser,
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

  Widget buildTextFormField(TextEditingController controller, String label, {bool isPassword = false, bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (isEmail && !value.contains('@')) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }
}