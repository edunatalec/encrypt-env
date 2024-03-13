import 'dart:math';
import 'dart:typed_data';

const int _maxSize = 4096;
const int _minSize = 128;

int get keyBytesSize =>
    _minSize +
    Random(DateTime.now().millisecondsSinceEpoch).nextInt(_maxSize - _minSize);

Uint8List randomBytes(int length) {
  final Random random = Random.secure();
  final Uint8List ret = Uint8List(length);

  for (int i = 0; i < length; i++) {
    ret[i] = random.nextInt(256);
  }

  return ret;
}

String listToHex(List<int> list) {
  return list
      .map((e) {
        return '0x'
            '${int.parse(e.toString().padLeft(2, '0')).toRadixString(16)}';
      })
      .toList()
      .join(', ');
}

String stringToHex(String value, Uint8List salt) {
  return listToHex(_encode(value, String.fromCharCodes(salt)));
}

List<int> _encode(String string, String cipher) {
  return Iterable<int>.generate(string.length).toList().map((int e) {
    return string[e].codeUnits.first ^
        cipher[e % cipher.length].codeUnits.first;
  }).toList();
}
