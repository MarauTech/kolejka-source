import 'package:integration_test/integration_test.dart';
import '../test/connection_interactions_test.dart' as interactions;
import '../test/connection_board_test.dart' as results;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  interactions.main();
  results.main();
}
