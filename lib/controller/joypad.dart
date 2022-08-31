import 'package:nes_emulator/util.dart';

import '../common.dart';
import 'controller.dart';

enum JoyPadKey {
  a,
  b,
  select,
  start,
  up,
  down,
  left,
  right,
}

class JoyPadController implements IStandardController {
  final FlagBits<JoyPadKey> _regKeyState = FlagBits(0);
  void press(JoyPadKey key) {
    print('press $key');
    _regKeyState[key] = true;
  }

  void release(JoyPadKey key) {
    print('release $key');
    _regKeyState[key] = false;
  }

  // 手柄是否处于选通状态
  bool _inStrobeState = false;

  U8 _keyState = 0;

  @override
  set strobe(U8 val) {
    bool strobeOld = _inStrobeState;
    _inStrobeState = val.getBit(0);
    if (strobeOld && (!_inStrobeState)) {
      for (final key in JoyPadKey.values) {
        if (_regKeyState[key]) {
          _keyState |= (1 << key.index);
        }
      }
    }
  }

  @override
  U8 get keyState {
    bool isKeyPressed;
    if (_inStrobeState) {
      isKeyPressed = _regKeyState[JoyPadKey.a];
    } else {
      isKeyPressed = _keyState.getBit(0);
      _keyState >>= 1;
    }
    return 0x40 | isKeyPressed.asInt();
  }
}
