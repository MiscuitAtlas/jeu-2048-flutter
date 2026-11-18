import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_2048/app.dart';
import 'package:jeu_2048/storage/game_storage.dart';
import 'package:jeu_2048/ui/widgets/board_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GameStorage> storage() async {
  SharedPreferences.setMockInitialValues({});
  return GameStorage(await SharedPreferences.getInstance());
}

/// Valeur affichée sous un libellé (Score, Record, Coups).
String stat(WidgetTester tester, String label) {
  final box = find.bySemanticsLabel(RegExp('^$label : '));
  final semantics = tester.getSemantics(box);
  return semantics.label.split(' : ').last;
}

/// Joue des flèches jusqu'à ce qu'un coup soit accepté.
Future<void> playOneMove(WidgetTester tester) async {
  for (final key in [
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowDown,
  ]) {
    await tester.sendKeyEvent(key);
    await tester.pumpAndSettle();
    if (stat(tester, 'Coups') != '0') return;
  }
}

void main() {
  testWidgets('l\'écran d\'accueil laisse place au jeu', (tester) async {
    await tester.pumpWidget(Jeu2048App(storage: await storage()));
    expect(find.text('Jeu 2048'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Nouvelle partie'), findsOneWidget);
  });

  testWidgets('un appui passe l\'écran d\'accueil', (tester) async {
    await tester.pumpWidget(Jeu2048App(storage: await storage(), splashDuration: const Duration(seconds: 30)));
    await tester.tap(find.text('Jeu 2048'));
    await tester.pumpAndSettle();
    expect(find.text('Nouvelle partie'), findsOneWidget);
  });

  testWidgets('les flèches du clavier jouent un coup, que l\'on peut annuler', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(Jeu2048App(storage: await storage(), splashDuration: Duration.zero));
    await tester.pumpAndSettle();
    expect(stat(tester, 'Coups'), '0');
    final undo = find.widgetWithText(OutlinedButton, 'Annuler');
    expect(tester.widget<OutlinedButton>(undo).onPressed, isNull);

    await playOneMove(tester);
    expect(stat(tester, 'Coups'), '1');
    expect(tester.widget<OutlinedButton>(undo).onPressed, isNotNull);

    await tester.tap(undo);
    await tester.pumpAndSettle();
    expect(stat(tester, 'Coups'), '0');
    handle.dispose();
  });

  testWidgets('un glissement sur la grille joue un coup', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(Jeu2048App(storage: await storage(), splashDuration: Duration.zero));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('Grille 4 par 4')), findsOneWidget);
    final grid = find.byType(BoardView);
    for (final offset in const [Offset(-200, 0), Offset(0, -200), Offset(200, 0), Offset(0, 200)]) {
      await tester.drag(grid, offset);
      await tester.pumpAndSettle();
      if (stat(tester, 'Coups') != '0') break;
    }
    expect(stat(tester, 'Coups'), '1');
    handle.dispose();
  });

  testWidgets('recommencer une partie commencée demande confirmation', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(Jeu2048App(storage: await storage(), splashDuration: Duration.zero));
    await tester.pumpAndSettle();
    await playOneMove(tester);

    await tester.tap(find.text('Nouvelle partie'));
    await tester.pumpAndSettle();
    expect(find.text('Recommencer ?'), findsOneWidget);
    await tester.tap(find.text('Continuer la partie'));
    await tester.pumpAndSettle();
    expect(stat(tester, 'Coups'), '1');

    await tester.tap(find.text('Nouvelle partie'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Recommencer'));
    await tester.pumpAndSettle();
    expect(stat(tester, 'Coups'), '0');
    handle.dispose();
  });

  testWidgets('les réglages changent la grille et sont conservés', (tester) async {
    final store = await storage();
    await tester.pumpWidget(Jeu2048App(storage: store, splashDuration: Duration.zero));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Réglages'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 × 5'));
    await tester.tap(find.text('512'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appliquer et rejouer'));
    await tester.pumpAndSettle();

    expect(find.text('5 × 5'), findsOneWidget);
    expect(find.text('Objectif 512'), findsOneWidget);
    expect(store.loadSettings().size, 5);
    expect(store.loadSettings().goal, 512);
  });

  testWidgets('les règles et les records s\'ouvrent depuis la barre', (tester) async {
    await tester.pumpWidget(Jeu2048App(storage: await storage(), splashDuration: Duration.zero));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Règles du jeu'));
    await tester.pumpAndSettle();
    expect(find.text('Règles du jeu'), findsWidgets);
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Records'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Aucun record'), findsOneWidget);
  });

  for (final (width, height, scale) in [
    (390.0, 844.0, 1.0),
    (390.0, 844.0, 1.6),
    (320.0, 568.0, 1.3),
    (844.0, 390.0, 1.0),
  ]) {
    testWidgets('s\'affiche sans débordement en ${width.toInt()} × ${height.toInt()}, texte × $scale', (tester) async {
      tester.view.physicalSize = Size(width, height) * 2;
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(Jeu2048App(storage: await storage(), splashDuration: Duration.zero));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(BoardView), findsOneWidget);
    });
  }
}
