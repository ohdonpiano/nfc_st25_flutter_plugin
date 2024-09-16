import 'package:flutter/services.dart';

Uint8List hexToUint8List(String hex) {
  if (hex.isEmpty) {
    return Uint8List(0);
  }
  if (hex.length % 2 != 0) {
    throw 'Odd number of hex digits';
  }
  var l = hex.length ~/ 2;
  var result = Uint8List(l);
  for (var i = 0; i < l; ++i) {
    var x = int.parse(hex.substring(i * 2, (2 * (i + 1))), radix: 16);
    if (x.isNaN) {
      throw 'Expected hex string';
    }
    result[i] = x;
  }
  return result;
}

String arrayToHex(Uint8List data, {String? spaceCharacter}) {
  var result = '';
  for (var i = 0; i < data.length; i++) {
    var x = data[i];
    var str = ('00${x.toRadixString(16)}');
    result += str.substring(str.length - 2, str.length);
    if (spaceCharacter != null && i < data.length - 1) result += spaceCharacter;
  }
  return result.toUpperCase();
}

class HexadecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final hexRegExp = RegExp(r'^[0-9A-Fa-f]*$');
    if (hexRegExp.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}

class IntegerTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final integerRegExp = RegExp(r'^[0-9]*$');
    if (integerRegExp.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}
