import 'package:flutter/material.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/pages/dog_detail_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.builders,
    this.initialIndex = 0,
  });

  final List<WidgetBuilder> builders;
  final int initialIndex;

  static _AppShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<_AppShellState>();

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const int dogsTabIndex = 3;

  late int _index;
  final Map<int, Widget> _cache = {};
  late final List<GlobalKey<NavigatorState>> _navKeys;

  @override
  void initState() {
    super.initState();
    assert(
      widget.builders.length > dogsTabIndex,
      'AppShell requires at least ${dogsTabIndex + 1} tabs to use the dogs tab',
    );
    _index = widget.initialIndex;
    _navKeys = List.generate(
      widget.builders.length,
      (_) => GlobalKey<NavigatorState>(),
    );
  }

  Future<bool> _onWillPop() async {
    final nav = _navKeys[_index].currentState;
    if (nav != null && await nav.maybePop()) {
      return false;
    }
    if (_index != 0) {
      setState(() => _index = 0);
      return false;
    }
    return true;
  }

  void _onSelectTab(int idx) {
    _switchTab(idx);
  }

  void _switchTab(int idx) {
    if (idx == _index) {
      _navKeys[idx].currentState?.popUntil((route) => route.isFirst);
      return;
    }

    _navKeys[idx].currentState?.popUntil((route) => route.isFirst);
    setState(() => _index = idx);
  }

  Widget _buildTab(int i) {
    return _cache.putIfAbsent(
      i,
      () => Navigator(
        key: _navKeys[i],
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => widget.builders[i](context),
          );
        },
      ),
    );
  }

  void openDogDetails(Dog dog) {
    _switchTab(dogsTabIndex);

    void pushDog() {
      final nav = _navKeys[dogsTabIndex].currentState;
      if (nav == null) {
        debugPrint('[UI][APP_SHELL] dogs navigator not ready yet');
        return;
      }
      nav.push(
        MaterialPageRoute(
          builder: (_) => DogDetailPage(dog: dog),
        ),
      );
    }

    // Hvis navigatoren ikke er klar akkurat nå (typisk rett etter tab-switch),
    // prøv igjen på neste frame.
    if (_navKeys[dogsTabIndex].currentState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => pushDog());
      return;
    }

    pushDog();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    debugPrint('[UI][APP_SHELL] build tab=$_index');

    final labels = [
      l10n.home,
      l10n.sessions,
      l10n.statistics,
      l10n.dogs,
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: _buildTab(_index),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _onSelectTab,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home),
              label: labels[0],
            ),
            NavigationDestination(
              icon: const Icon(Icons.track_changes),
              label: labels[1],
            ),
            NavigationDestination(
              icon: const Icon(Icons.show_chart),
              label: labels[2],
            ),
            NavigationDestination(
              icon: const Icon(Icons.pets),
              label: labels[3],
            ),
          ],
        ),
      ),
    );
  }
}
