import 'package:integration_test/integration_test.dart';
import '../test/favorite_navigation_test.dart' as regression;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  regression.main();
}
