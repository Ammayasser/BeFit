import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:befit/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:befit/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:befit/features/auth/presentation/providers/auth_provider.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  bool onboardingSeen = false;
  
  @override
  Future<void> markOnboardingSeen() async {
    onboardingSeen = true;
  }

  @override
  bool get isAuthenticated => false;

  @override
  bool get hasSeenOnboarding => false;

  @override
  Future<void> login(String email, String password) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> register(Map<String, dynamic> setupData) async {}
  
  @override
  Future<void> checkAuthStatus() async {}

  @override
  void clearError() {}

  @override
  String? get errorMessage => null;

  @override
  void forceNavigationUpdate() {}

  @override
  void registerLogoutCallback(Future<void> Function() callback) {}

  @override
  AuthStatus get status => AuthStatus.unauthenticated;

  @override
  String? get userEmail => null;

  @override
  String? get userId => null;

  @override
  String? get userName => null;
}

void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
  });

  Widget createOnboardingScreen() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
      ],
      child: const MaterialApp(
        home: OnboardingScreen(),
      ),
    );
  }

  testWidgets('Onboarding screen displays correctly and can be swiped', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createOnboardingScreen());
    await tester.pumpAndSettle();

    // Initial page
    expect(find.textContaining('TRACK YOUR'), findsOneWidget);
    
    final continueBtn = find.text('Continue');
    await tester.ensureVisible(continueBtn);
    expect(continueBtn, findsOneWidget);

    // Swipe to second page
    await tester.fling(find.byType(PageView), const Offset(-800, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.textContaining('SMASH YOUR'), findsOneWidget);

    // Swipe to third page
    await tester.fling(find.byType(PageView), const Offset(-800, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.textContaining('YOUR AI'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('Next button advances the page', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createOnboardingScreen());
    await tester.pumpAndSettle();

    // Click next
    final continueBtn = find.text('Continue');
    await tester.ensureVisible(continueBtn);
    await tester.tap(continueBtn);
    await tester.pumpAndSettle();
    expect(find.textContaining('SMASH YOUR'), findsOneWidget);
  });
}
