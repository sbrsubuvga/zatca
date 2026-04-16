import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/invoice/invoice_bloc.dart';
import 'bloc/onboarding/onboarding_bloc.dart';
import 'bloc/onboarding/onboarding_event.dart';
import 'bloc/onboarding/onboarding_state.dart';
import 'data/storage.dart';
import 'screens/invoice_form_screen.dart';
import 'screens/onboarding_screen.dart';
import 'ui/breakpoints.dart';

void main() {
  runApp(const ZatcaExampleApp());
}

class ZatcaExampleApp extends StatelessWidget {
  const ZatcaExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = OnboardingStorage();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => OnboardingBloc(storage: storage)
            ..add(const OnboardingLoadRequested()),
        ),
        BlocProvider(
          create: (context) => InvoiceBloc(
            onboardingBloc: context.read<OnboardingBloc>(),
            storage: storage,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'ZATCA E-Invoicing',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        home: const HomeShell(),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0A7B6B),
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant, width: 0.6),
        ),
        color: scheme.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        isDense: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: scheme.outlineVariant, width: 0.6),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _destinations = const [
    _NavDest(
      icon: Icons.app_registration_outlined,
      activeIcon: Icons.app_registration,
      label: 'Onboarding',
    ),
    _NavDest(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'Create Invoice',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final useRail = Breakpoints.useTwoColumn(context);
        return Scaffold(
          appBar: _AppHeader(state: state, showOnMobile: !useRail),
          body: useRail ? _railLayout(state) : _bottomNavLayout(state),
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: [
                    for (final d in _destinations)
                      NavigationDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.activeIcon),
                        label: d.label,
                      ),
                  ],
                ),
        );
      },
    );
  }

  Widget _railLayout(OnboardingState state) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: theme.dividerColor)),
          ),
          child: NavigationRail(
            extended: Breakpoints.isExpanded(context),
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: Breakpoints.isExpanded(context)
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _AppMark(compact: !Breakpoints.isExpanded(context)),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.activeIcon),
                  label: Text(d.label),
                ),
            ],
          ),
        ),
        Expanded(child: _currentPane()),
      ],
    );
  }

  Widget _bottomNavLayout(OnboardingState state) => _currentPane();

  Widget _currentPane() => switch (_index) {
    0 => const OnboardingScreen(),
    _ => const InvoiceFormScreen(),
  };
}

class _NavDest {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavDest({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _AppMark extends StatelessWidget {
  final bool compact;
  const _AppMark({required this.compact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mark = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.bolt, color: Colors.white),
    );
    if (compact) return mark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          mark,
          const SizedBox(height: 8),
          Text(
            'ZATCA',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'E-Invoicing demo',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final OnboardingState state;
  final bool showOnMobile;
  const _AppHeader({required this.state, required this.showOnMobile});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final envColor = switch (state.environment.value) {
      'production' => Colors.red,
      'simulation' => Colors.orange,
      _ => theme.colorScheme.primary,
    };
    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          if (showOnMobile) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiary,
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.bolt, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
          ],
          const Text(
            'ZATCA E-Invoicing',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: envColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: envColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: envColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  state.environment.value.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: envColor,
                    letterSpacing: 0.5,
                  ),
                ),
                if (state.isReadyToInvoice) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.verified, size: 14, color: envColor),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
