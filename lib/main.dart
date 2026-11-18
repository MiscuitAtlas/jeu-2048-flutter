import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'storage/game_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(Jeu2048App(storage: await GameStorage.open()));
}
