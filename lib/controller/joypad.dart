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

  U8 _strobe = 0;
  U8 _index = 0;

  @override
  set regStrobe(U8 val) {
    _strobe = val;
    if (_strobe & 1 == 1) {
      _index = 0;
    }
  }

  @override
  U8 get regKeyState {
    U8 value = 0;
    if (_index < 8 && _regKeyState[JoyPadKey.values[_index]]) {
      value = 1;
    }
    _index++;
    if (_strobe & 1 == 1) {
      _index = 0;
    }
    return value;
  }
}
