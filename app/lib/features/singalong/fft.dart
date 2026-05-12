import 'dart:math';

/// Radix-2 Cooley-Tukey FFT.
/// Input length must be a power of 2.
/// Returns complex frequency-domain representation.
List<Complex> fft(List<double> input) {
  final n = input.length;
  if (n == 0) return [];
  if (!_isPowerOf2(n)) {
    throw ArgumentError('FFT input length must be a power of 2, got $n');
  }

  // Bit-reversal permutation
  final output = List<Complex>.filled(n, Complex.zero);
  for (int i = 0; i < n; i++) {
    output[_bitReverse(i, n)] = Complex(input[i], 0);
  }

  // Butterfly operations
  int length = 2;
  while (length <= n) {
    final halfLen = length ~/ 2;
    final angle = -2 * pi / length;
    for (int i = 0; i < n; i += length) {
      for (int j = 0; j < halfLen; j++) {
        final w = Complex.fromPolar(1, angle * j);
        final even = output[i + j];
        final odd = output[i + j + halfLen] * w;
        output[i + j] = even + odd;
        output[i + j + halfLen] = even - odd;
      }
    }
    length *= 2;
  }

  return output;
}

/// Inverse FFT: recovers time-domain signal from frequency domain.
List<Complex> ifft(List<Complex> input) {
  final n = input.length;
  if (n == 0) return [];

  // Conjugate, FFT, conjugate, divide by N
  final conjugated = input.map((c) => Complex(c.real, -c.imaginary)).toList();

  // Do FFT on the conjugated complex values directly
  final result = _fftComplex(conjugated);
  return result
      .map((c) => Complex(c.real / n, -c.imaginary / n))
      .toList();
}

/// FFT on complex input (for IFFT internal use).
List<Complex> _fftComplex(List<Complex> input) {
  final n = input.length;
  if (n == 1) return [input[0]];
  if (!_isPowerOf2(n)) {
    throw ArgumentError('FFT input length must be a power of 2, got $n');
  }

  final output = List<Complex>.filled(n, Complex.zero);
  for (int i = 0; i < n; i++) {
    output[_bitReverse(i, n)] = input[i];
  }

  int length = 2;
  while (length <= n) {
    final halfLen = length ~/ 2;
    final angle = -2 * pi / length;
    for (int i = 0; i < n; i += length) {
      for (int j = 0; j < halfLen; j++) {
        final w = Complex.fromPolar(1, angle * j);
        final even = output[i + j];
        final odd = output[i + j + halfLen] * w;
        output[i + j] = even + odd;
        output[i + j + halfLen] = even - odd;
      }
    }
    length *= 2;
  }

  return output;
}

/// Generate a Hamming window of length [n].
List<double> hammingWindow(int n) {
  return List<double>.generate(n, (i) => 0.54 - 0.46 * cos(2 * pi * i / (n - 1)));
}

/// Frame a signal into overlapping windows.
/// Returns list of frames, each of length [frameSize].
/// Last frame is zero-padded if signal is shorter than frameSize.
List<List<double>> frameSignal(
  List<double> signal, {
  required int frameSize,
  required int hopSize,
}) {
  if (signal.isEmpty) return [];

  final frames = <List<double>>[];
  int start = 0;
  while (start < signal.length) {
    final frame = List<double>.filled(frameSize, 0.0);
    final end = (start + frameSize).clamp(0, signal.length);
    for (int i = start; i < end; i++) {
      frame[i - start] = signal[i];
    }
    frames.add(frame);
    start += hopSize;
    if (end >= signal.length) break;
  }
  return frames;
}

int _bitReverse(int x, int n) {
  int result = 0;
  int bits = _log2(n);
  for (int i = 0; i < bits; i++) {
    result = (result << 1) | (x & 1);
    x >>= 1;
  }
  return result;
}

int _log2(int n) {
  int result = 0;
  while (n > 1) {
    n >>= 1;
    result++;
  }
  return result;
}

bool _isPowerOf2(int n) => n > 0 && (n & (n - 1)) == 0;

/// Minimal Complex number class for FFT.
class Complex {
  final double real;
  final double imaginary;

  static const zero = Complex(0, 0);

  const Complex(this.real, this.imaginary);

  factory Complex.fromPolar(double r, double theta) =>
      Complex(r * cos(theta), r * sin(theta));

  double get abs => sqrt(real * real + imaginary * imaginary);

  Complex operator +(Complex other) =>
      Complex(real + other.real, imaginary + other.imaginary);

  Complex operator -(Complex other) =>
      Complex(real - other.real, imaginary - other.imaginary);

  Complex operator *(Complex other) => Complex(
        real * other.real - imaginary * other.imaginary,
        real * other.imaginary + imaginary * other.real,
      );

  @override
  String toString() => 'Complex($real, $imaginary)';
}
