part of bit_array;

/// Bit array to store bits.
class BitArray extends BitSet {
  Uint32List _data;
  int _length;

  BitArray._(this._data) : _length = _data.length << 5;

  /// Creates a bit array with maximum [length] items.
  ///
  /// [length] will be rounded up to match the 32-bit boundary.
  factory BitArray(int length) =>
      BitArray._(Uint32List(_bufferLength32(length)));

  /// Creates a bit array using a byte buffer.
  factory BitArray.fromByteBuffer(ByteBuffer buffer) {
    final data = buffer.asUint32List();
    return BitArray._(data);
  }

  /// Creates a bit array using a generic bit set.
  factory BitArray.fromBitSet(BitSet set, {int length}) {
    length ??= set.length;
    final setDataLength = _bufferLength32(set.length);
    final data = Uint32List(_bufferLength32(length));
    data.setRange(0, setDataLength, set.asUint32Iterable());
    return BitArray._(data);
  }

  /// The value of the bit with the specified [index].
  @override
  bool operator [](int index) {
    return (_data[index >> 5] & _bitMask[index & 0x1f]) != 0;
  }

  /// Sets the bit specified by the [index] to the [value].
  void operator []=(int index, bool value) {
    if (value) {
      setBit(index);
    } else {
      clearBit(index);
    }
  }

  /// The number of bit in this [BitArray].
  ///
  /// [length] will be rounded up to match the 32-bit boundary.
  ///
  /// The valid index values for the array are `0` through `length - 1`.
  @override
  int get length => _length;
  set length(int value) {
    if (_length == value) {
      return;
    }
    final data = Uint32List(_bufferLength32(value));
    data.setRange(0, math.min(data.length, _data.length), _data);
    _data = data;
    _length = _data.length << 5;
  }

  /// The number of bits set to true.
  @override
  int get cardinality => _data.buffer
      .asUint8List()
      .fold(0, (sum, value) => sum + _cardinalityBitCounts[value]);

  /// Whether the [BitArray] is empty == has only zero values.
  bool get isEmpty {
    return _data.every((i) => i == 0);
  }

  /// Whether the [BitArray] is not empty == has set values.
  bool get isNotEmpty {
    return _data.any((i) => i != 0);
  }

  /// Sets the bit specified by the [index] to false.
  void clearBit(int index) {
    _data[index >> 5] &= _clearMask[index & 0x1f];
  }

  /// Sets the bits specified by the [indexes] to false.
  void clearBits(Iterable<int> indexes) {
    indexes.forEach(clearBit);
  }

  /// Sets all of the bits in the current [BitArray] to false.
  void clearAll() {
    for (int i = 0; i < _data.length; i++) {
      _data[i] = 0;
    }
  }

  /// Sets the bit specified by the [index] to true.
  void setBit(int index) {
    _data[index >> 5] |= _bitMask[index & 0x1f];
  }

  /// Sets the bits specified by the [indexes] to true.
  void setBits(Iterable<int> indexes) {
    indexes.forEach(setBit);
  }

  /// Sets all the bit values in the current [BitArray] to true.
  void setAll() {
    for (int i = 0; i < _data.length; i++) {
      _data[i] = -1;
    }
  }

  /// Inverts the bit specified by the [index].
  void invertBit(int index) {
    this[index] = !this[index];
  }

  /// Inverts the bits specified by the [indexes].
  void invertBits(Iterable<int> indexes) {
    indexes.forEach(invertBit);
  }

  /// Inverts all the bit values in the current [BitArray].
  void invertAll() {
    for (int i = 0; i < _data.length; i++) {
      _data[i] = ~(_data[i]);
    }
  }

  /// Update the current [BitArray] using a logical AND operation with the
  /// corresponding elements in the specified [set].
  /// Excess size of the [set] is ignored.
  void and(BitSet set) {
    final iter = set.asUint32Iterable().iterator;
    int i = 0;
    for (; i < _data.length && iter.moveNext(); i++) {
      _data[i] &= iter.current;
    }
    for (; i < _data.length; i++) {
      _data[i] = 0;
    }
  }

  /// Update the current [BitArray] using a logical AND NOT operation with the
  /// corresponding elements in the specified [set].
  /// Excess size of the [set] is ignored.
  void andNot(BitSet set) {
    final iter = set.asUint32Iterable().iterator;
    for (int i = 0; i < _data.length && iter.moveNext(); i++) {
      _data[i] &= ~iter.current;
    }
  }

  /// Update the current [BitArray] using a logical OR operation with the
  /// corresponding elements in the specified [set].
  /// Excess size of the [set] is ignored.
  void or(BitSet set) {
    final iter = set.asUint32Iterable().iterator;
    for (int i = 0; i < _data.length && iter.moveNext(); i++) {
      _data[i] |= iter.current;
    }
  }

  /// Update the current [BitArray] using a logical XOR operation with the
  /// corresponding elements in the specified [set].
  /// Excess size of the [set] is ignored.
  void xor(BitSet set) {
    final iter = set.asUint32Iterable().iterator;
    for (int i = 0; i < _data.length && iter.moveNext(); i++) {
      _data[i] = _data[i] ^ iter.current;
    }
  }

  /// Creates a copy of the current [BitArray].
  @override
  BitArray clone() {
    final newData = Uint32List(_data.length);
    newData.setRange(0, _data.length, _data);
    return BitArray._(newData);
  }

  /// Creates a [BitArray] using a logical AND operation with the
  /// corresponding elements in the specified [set].
  /// Excess size of the [set] is ignored.
  BitArray operator &(BitSet set) => clone()..and(set);

  /// Creates a [BitArray] using a logical AND NOT operation with the
  /// corresponding elements in the specified [set].
  /// Excess size of the [set] is ignored.
  BitArray operator %(BitSet set) => clone()..andNot(set);

  /// Creates a [BitArray] using a logical OR operation with the
  /// corresponding elements in the specified [set].
  /// Excess size of the [set] is ignored.
  BitArray operator |(BitSet set) => clone()..or(set);

  /// Creates a [BitArray] using a logical XOR operation with the
  /// corresponding elements in the specified [set].
  /// Excess size of the [set] is ignored.
  BitArray operator ^(BitSet set) => clone()..xor(set);

  /// Creates a string of 0s and 1s of the content of the array.
  String toBinaryString() {
    final sb = StringBuffer();
    for (int i = 0; i < length; i++) {
      sb.write(this[i] ? '1' : '0');
    }
    return sb.toString();
  }

  /// The backing, mutable byte buffer of the [BitArray].
  /// Use with caution.
  ByteBuffer get byteBuffer => _data.buffer;

  /// Returns an iterable wrapper of the bit array that iterates over the index
  /// numbers and returns the 32-bit int blocks.
  @override
  Iterable<int> asUint32Iterable() => _data;

  /// Returns an iterable wrapper of the bit array that iterates over the index
  /// numbers that match [value] (by default the bits that are set).
  @override
  Iterable<int> asIntIterable([bool value = true]) {
    return _IntIterable(this, value);
  }
}

final _bitMask = List<int>.generate(32, (i) => 1 << i);
final _clearMask = List<int>.generate(32, (i) => ~(1 << i));
final _cardinalityBitCounts = List<int>.generate(256, _cardinalityOfByte);

int _cardinalityOfByte(int value) {
  int result = 0;
  while (value > 0) {
    if (value & 0x01 != 0) {
      result++;
    }
    value = value >> 1;
  }
  return result;
}

class _IntIterable extends IterableBase<int> {
  final BitArray _array;
  final bool _value;
  _IntIterable(this._array, this._value);

  @override
  Iterator<int> get iterator =>
      _IntIterator(_array._data, _array.length, _value);
}

class _IntIterator implements Iterator<int> {
  final Uint32List _buffer;
  final int _length;
  final bool _matchValue;
  final int _skipMatch;
  final int _cursorMax = (1 << 31);
  int _current = -1;
  int _cursor = 0;
  int _cursorByte = 0;
  int _cursorMask = 1;

  _IntIterator(this._buffer, this._length, this._matchValue)
      : _skipMatch = _matchValue ? 0x00 : 0xffffffff;

  @override
  int get current => _current;

  @override
  bool moveNext() {
    while (_cursor < _length) {
      final value = _buffer[_cursorByte];
      if (_cursorMask == 1 && value == _skipMatch) {
        _cursorByte++;
        _cursor += 32;
        continue;
      }
      final isSet = (value & _cursorMask) != 0;
      if (isSet == _matchValue) {
        _current = _cursor;
        _increment();
        return true;
      }
      _increment();
    }
    return false;
  }

  void _increment() {
    if (_cursorMask == _cursorMax) {
      _cursorMask = 1;
      _cursorByte++;
    } else {
      _cursorMask <<= 1;
    }
    _cursor++;
  }
}

int _bufferLength32(int length) {
  final hasExtra = (length & 0x1f) != 0;
  return (length >> 5) + (hasExtra ? 1 : 0);
}
