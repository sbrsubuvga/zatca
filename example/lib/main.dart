import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/invoice/invoice_bloc.dart';
import 'bloc/onboarding/onboarding_bloc.dart';
import 'bloc/onboarding/onboarding_event.dart';
import 'bloc/onboarding/onboarding_state.dart';
import 'data/storage.dart';
import 'screens/home_screen.dart';
import 'screens/invoice_form_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/phase1_screen.dart';
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
          create:
              (_) =>
                  OnboardingBloc(storage: storage)
                    ..add(const OnboardingLoadRequested()),
        ),
        BlocProvider(
          create:
              (context) => InvoiceBloc(
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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

/// Top-level navigation sections. Order matches the drawer order.
enum _Section {
  home,
  phase1Qr,
  phase2Onboarding,
  phase2Invoice;

  /// Whether this section belongs to Phase-2 (drives env-badge visibility,
  /// step subtitles, and gating).
  bool get isPhase2 =>
      this == _Section.phase2Onboarding || this == _Section.phase2Invoice;

  /// Whether this section is gated by completing Phase-2 onboarding.
  bool get requiresOnboarding => this == _Section.phase2Invoice;
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  _Section _section = _Section.home;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _navigateTo(_Section s) {
    setState(() => _section = s);
    // If we're on a small screen the modal drawer is open — close it.
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, onboarding) {
        final isWide = Breakpoints.useTwoColumn(context);
        final drawer = _AppDrawer(
          active: _section,
          onboardingReady: onboarding.isReadyToInvoice,
          hasComplianceCert: onboarding.hasComplianceCertificate,
          onSelected: _navigateTo,
        );

        final body = _Body(
          section: _section,
          onTryPhase1: () => _navigateTo(_Section.phase1Qr),
          onTryPhase2: () => _navigateTo(_Section.phase2Onboarding),
        );

        return Scaffold(
          key: _scaffoldKey,
          appBar: _AppHeader(
            section: _section,
            onboardingState: onboarding,
            showMenuButton: !isWide,
          ),
          drawer: isWide ? null : drawer,
          body:
              isWide
                  ? Row(
                    children: [
                      SizedBox(width: 280, child: drawer),
                      const VerticalDivider(width: 1),
                      Expanded(child: body),
                    ],
                  )
                  : body,
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final _Section section;
  final VoidCallback onTryPhase1;
  final VoidCallback onTryPhase2;

  const _Body({
    required this.section,
    required this.onTryPhase1,
    required this.onTryPhase2,
  });

  @override
  Widget build(BuildContext context) {
    // IndexedStack preserves state per screen as the user switches sections.
    final index = _Section.values.indexOf(section);
    return IndexedStack(
      index: index,
      sizing: StackFit.expand,
      children: [
        HomeScreen(onTryPhase1: onTryPhase1, onTryPhase2: onTryPhase2),
        const Phase1Screen(),
        const OnboardingScreen(),
        const _GatedInvoiceScreen(),
      ],
    );
  }
}

/// Wraps the invoice screen with a "complete onboarding first" placeholder
/// for users who navigate here before they've onboarded.
class _GatedInvoiceScreen extends StatelessWidget {
  const _GatedInvoiceScreen();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        if (state.isReadyToInvoice) return const InvoiceFormScreen();
        final theme = Theme.of(context);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(Gaps.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: Gaps.md),
                  Text(
                    'Complete onboarding first',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Gaps.sm),
                  Text(
                    'Phase-2 invoices need a compliance certificate. '
                    'Open "Onboarding" in the side menu and run through '
                    'the steps to unlock invoice creation.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final _Section active;
  final bool onboardingReady;
  final bool hasComplianceCert;
  final ValueChanged<_Section> onSelected;

  const _AppDrawer({
    required this.active,
    required this.onboardingReady,
    required this.hasComplianceCert,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phase2InvoiceLocked = !onboardingReady;

    return Drawer(
      width: 280,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: Gaps.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gaps.md),
              child: _Brand(theme: theme),
            ),
            const SizedBox(height: Gaps.md),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: Gaps.sm),
                children: [
                  _DrawerItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Home',
                    selected: active == _Section.home,
                    onTap: () => onSelected(_Section.home),
                  ),
                  _SectionHeader(label: 'PHASE-1 (Generation)', theme: theme),
                  _DrawerItem(
                    icon: Icons.qr_code_2_outlined,
                    activeIcon: Icons.qr_code_2,
                    label: 'QR Generator',
                    selected: active == _Section.phase1Qr,
                    onTap: () => onSelected(_Section.phase1Qr),
                  ),
                  _SectionHeader(label: 'PHASE-2 (Integration)', theme: theme),
                  _DrawerItem(
                    icon: Icons.app_registration_outlined,
                    activeIcon: Icons.app_registration,
                    label: '1. Onboarding',
                    selected: active == _Section.phase2Onboarding,
                    trailing:
                        hasComplianceCert
                            ? Icon(
                              Icons.check_circle,
                              size: 18,
                              color: theme.colorScheme.primary,
                            )
                            : null,
                    onTap: () => onSelected(_Section.phase2Onboarding),
                  ),
                  _DrawerItem(
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long,
                    label: '2. Create Invoice',
                    selected: active == _Section.phase2Invoice,
                    trailing:
                        phase2InvoiceLocked
                            ? Icon(
                              Icons.lock_outline,
                              size: 18,
                              color: theme.colorScheme.outline,
                            )
                            : null,
                    subtitle:
                        phase2InvoiceLocked
                            ? 'Complete onboarding first'
                            : null,
                    onTap: () => onSelected(_Section.phase2Invoice),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(Gaps.md),
              child: Text(
                'zatca · 0.8.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  final ThemeData theme;
  const _Brand({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.bolt, color: Colors.white, size: 20),
        ),
        const SizedBox(width: Gaps.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ZATCA',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'E-Invoicing demo',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final ThemeData theme;
  const _SectionHeader({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gaps.md, Gaps.md, Gaps.md, Gaps.xs),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? subtitle;
  final bool selected;
  final Widget? trailing;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg =
        selected ? theme.colorScheme.secondaryContainer : Colors.transparent;
    final fg =
        selected
            ? theme.colorScheme.onSecondaryContainer
            : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gaps.sm, vertical: 1),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Gaps.sm,
              vertical: 10,
            ),
            child: Row(
              children: [
                Icon(selected ? activeIcon : icon, size: 20, color: fg),
                const SizedBox(width: Gaps.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: fg,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final _Section section;
  final OnboardingState onboardingState;
  final bool showMenuButton;

  const _AppHeader({
    required this.section,
    required this.onboardingState,
    required this.showMenuButton,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (title, subtitle) = switch (section) {
      _Section.home => ('Home', 'Choose your phase'),
      _Section.phase1Qr => ('QR Generator', 'Phase-1 · Generation'),
      _Section.phase2Onboarding => ('Onboarding', 'Phase-2 · Step 1 of 2'),
      _Section.phase2Invoice => ('Create Invoice', 'Phase-2 · Step 2 of 2'),
    };

    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: showMenuButton,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        if (section.isPhase2) _EnvBadge(env: onboardingState),
        const SizedBox(width: 12),
      ],
    );
  }
}

class _EnvBadge extends StatelessWidget {
  final OnboardingState env;
  const _EnvBadge({required this.env});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final envColor = switch (env.environment.value) {
      'production' => Colors.red,
      'simulation' => Colors.orange,
      _ => theme.colorScheme.primary,
    };
    return Container(
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
            decoration: BoxDecoration(color: envColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            env.environment.value.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: envColor,
              letterSpacing: 0.5,
            ),
          ),
          if (env.isReadyToInvoice) ...[
            const SizedBox(width: 6),
            Icon(Icons.verified, size: 14, color: envColor),
          ],
        ],
      ),
    );
  }
}
