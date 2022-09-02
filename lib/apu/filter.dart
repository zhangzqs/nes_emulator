import 'dart:math';

import 'package:nes_emulator/apu/apu.dart';

abstract class Filter {
  F32 step(F32 x);
}

// First order filters are defined by the following parameters.
// y[n] = B0*x[n] + B1*x[n-1] - A1*y[n-1]
class FirstOrderFilter implements Filter {
  F32 b0 = 0;
  F32 b1 = 0;
  F32 a1 = 0;

  FirstOrderFilter({
    required this.b0,
    required this.b1,
    required this.a1,
  });
  F32 prevX = 0;
  F32 prevY = 0;

  late FirstOrderFilter f = this;
  @override
  F32 step(F32 x) {
    final y = f.b0 * x + f.b1 * f.prevX - f.a1 * f.prevY;
    f.prevY = y;
    f.prevX = x;
    return y;
  }
}

Filter lowPassFilter(F32 sampleRate, F32 cutoffFreq) {
  final c = sampleRate / pi / cutoffFreq;
  final a0i = 1 / (1 + c);

  return FirstOrderFilter(
    b0: a0i,
    b1: a0i,
    a1: (1 - c) * a0i,
  );
}

Filter highPassFilter(F32 sampleRate, F32 cutoffFreq) {
  final c = sampleRate / pi / cutoffFreq;
  final a0i = 1 / (1 + c);
  return FirstOrderFilter(
    b0: c * a0i,
    b1: -c * a0i,
    a1: (1 - c) * a0i,
  );
}

class FilterChain implements Filter {
  final List<Filter> chain = [];
  @override
  F32 step(F32 x) {
    for (Filter filter in chain) {
      x = filter.step(x);
    }
    return x;
  }
}
