import 'package:flutter/material.dart';
import 'package:editiz/screens/creations_screen.dart';
import 'package:editiz/screens/home_screen.dart';
import 'package:editiz/screens/settings_screen.dart';

// Class: main bottom navigation shell using NavigationBar and IndexedStack.
class MainScreen extends StatefulWidget {
  // Static field: allows child screens (e.g., ExportSheet) to switch tab programmatically.
  static final ValueNotifier<int> tab = ValueNotifier<int>(0);

  // Constructor: const key constructor.
  const MainScreen({super.key});

  // Override: creates State object.
  @override
  State<MainScreen> createState() => _MainScreenState();
}

// Class: state tracking tab selection and syncing with tab notifier.
class _MainScreenState extends State<MainScreen> {
  // Field: active tab index.
  int _currentIndex = 0;

  // Field: persistent screens list inside IndexedStack.
  static const List<Widget> _tabs = [
    HomeScreen(),
    CreationsScreen(),
    SettingsScreen(),
  ];

  // Override: attaches tab listener.
  @override
  void initState() {
    super.initState();
    _currentIndex = MainScreen.tab.value;
    MainScreen.tab.addListener(_onTabNotifierChanged);
  }

  // Override: detaches tab listener.
  @override
  void dispose() {
    MainScreen.tab.removeListener(_onTabNotifierChanged);
    super.dispose();
  }

  // Method: updates local state when tab notifier changes externally.
  void _onTabNotifierChanged() {
    if (_currentIndex != MainScreen.tab.value) {
      setState(() {
        _currentIndex = MainScreen.tab.value;
      });
    }
  }

  // Method: updates selected tab on user navigation bar tap.
  void _onDestinationSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    MainScreen.tab.value = index;
  }

  // Override: builds the persistent scaffold with NavigationBar and IndexedStack.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            selectedIcon: Icon(Icons.video_library_rounded),
            label: 'Creations',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
