import 'package:integration_test/integration_test.dart';

// Run the same passenger scenarios on an Android Flutter engine as in unit CI.
// Fixtures deliberately avoid spending the public feed's hourly request quota.
import '../test/train_details_crash_test.dart' as details;
import '../test/disruption_pagination_test.dart' as disruptions;
import '../test/disruption_timestamp_test.dart' as timestamps;
import '../test/passenger_screens_test.dart' as screens;
import '../test/station_board_test.dart' as board;
import '../test/connection_interactions_test.dart' as connections;
import '../test/qa_ui_regression_test.dart' as fixes;
import '../test/api_resilience_test.dart' as network;
import '../test/station_picker_lifecycle_test.dart' as picker;
import '../test/connections_next_day_test.dart' as next_days;
import '../test/route_axis_test.dart' as axis;
import '../test/disruption_description_ui_test.dart' as descriptions;
import '../test/appearance_and_memory_test.dart' as appearance;
import '../test/favorite_navigation_test.dart' as favorites;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  details.main();
  disruptions.main();
  timestamps.main();
  screens.main();
  board.main();
  connections.main();
  fixes.main();
  network.main();
  picker.main();
  next_days.main();
  axis.main();
  descriptions.main();
  appearance.main();
  favorites.main();
}
