import 'package:first_protection/constants/messages.dart';
import 'package:first_protection/widgets/bottom_navigation_menu.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  

  final int _currentIndex = 2; 
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/history');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFD32C2C),
        title: Text(Messages.appName, style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/select');
          },
        ),
        actions: [
          IconButton(icon: Icon(Icons.notifications, color: Colors.white), onPressed: () {}),
          IconButton(icon: Icon(Icons.menu, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Messages.userName,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        Text(
                          Messages.userEmail,
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            SizedBox(height: 10),
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(Messages.enableNotifications, style: TextStyle(color: Colors.black87)),
                      value: true, 
                      onChanged: (value) {
                      },
                      activeColor: Colors.red,
                    ),
                    SwitchListTile(
                      title: Text(Messages.importantAlerts, style: TextStyle(color: Colors.black87)),
                      value: false, 
                      onChanged: (value) {
                      },
                      activeColor: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            SizedBox(height: 10),
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(Messages.changeDeviceName, style: TextStyle(color: Colors.black87)),
                      trailing: Icon(Icons.arrow_forward_ios, color: Colors.red),
                      onTap: () {
                      },
                    ),
                    Divider(color: Colors.grey),
                    ListTile(
                      title: Text(Messages.securityMode, style: TextStyle(color: Colors.black87)),
                      trailing: Icon(Icons.arrow_forward_ios, color: Colors.red),
                      onTap: () {
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            SizedBox(height: 10),
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(Messages.theme, style: TextStyle(color: Colors.black87)),
                      trailing: Icon(Icons.arrow_forward_ios, color: Colors.red),
                      onTap: () {
                      },
                    ),
                    Divider(color: Colors.grey),
                    ListTile(
                      title: Text(Messages.language, style: TextStyle(color: Colors.black87)),
                      trailing: Icon(Icons.arrow_forward_ios, color: Colors.red),
                      onTap: () {
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            SizedBox(height: 10),
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(Messages.logout, style: TextStyle(color: Colors.red)),
                      trailing: Icon(Icons.logout, color: Colors.red),
                      onTap: () {
                      },
                    ),
                    Divider(color: Colors.grey),
                    ListTile(
                      title: Text(Messages.deleteAccount, style: TextStyle(color: Colors.red)),
                      trailing: Icon(Icons.delete, color: Colors.red),
                      onTap: () {
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }
}