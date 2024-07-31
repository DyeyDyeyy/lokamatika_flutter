// import 'dart:async';
// import 'package:battery_plus/battery_plus.dart';

// class BatteryPecentage {
//   final Battery _battery = Battery();

//   BatteryState? _batteryState;
//   StreamSubscription<BatteryState>? _batteryStateSubscription;

//   void init() {
//     _battery.batteryState.then(_updateBatteryState);
//     _batteryStateSubscription =
//         _battery.onBatteryStateChanged.listen(_updateBatteryState);
//   }

//   void _updateBatteryState(BatteryState state) {
//     if (_batteryState == state) return;

//     _batteryState = state;
//   }

//   void dispose() {
//     if (_batteryStateSubscription != null) {
//       _batteryStateSubscription!.cancel();
//     }
//   }
// }
