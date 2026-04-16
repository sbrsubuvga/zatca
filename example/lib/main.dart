import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/invoice/invoice_bloc.dart';
import 'bloc/onboarding/onboarding_bloc.dart';
import 'bloc/onboarding/onboarding_event.dart';
import 'bloc/onboarding/onboarding_state.dart';
import 'data/storage.dart';
import 'screens/invoice_form_screen.dart';
import 'screens/onboarding_screen.dart';

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
          create: (_) =>
              OnboardingBloc(storage: storage)
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
        title: 'ZATCA Example',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const HomeShell(),
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final ready = state.isReadyToInvoice;
        return Scaffold(
          appBar: AppBar(
            title: const Text('ZATCA E-Invoicing'),
            actions: [
              if (ready)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Chip(
                    avatar: Icon(
                      Icons.verified,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                    label: Text(state.environment.value.toUpperCase()),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          body: IndexedStack(
            index: _index,
            children: const [
              OnboardingScreen(),
              InvoiceFormScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.app_registration),
                label: 'Onboarding',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.receipt_long,
                  color: ready ? null : Theme.of(context).disabledColor,
                ),
                label: 'Create Invoice',
              ),
            ],
          ),
        );
      },
    );
  }
}
