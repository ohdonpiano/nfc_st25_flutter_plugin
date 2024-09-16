import 'dart:async';
import 'package:flutter/services.dart';
import 'package:nfc_st25/utils/nfc_st25_tag.dart';
import 'utils/exceptions.dart';

class NfcSt25 {
  static const MethodChannel _channel = const MethodChannel('nfc_st25');

  static const EventChannel _eventChannel = const EventChannel("nfc_st25/tags");

  static Stream<dynamic>? _tagStream;

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<bool> get nfcAvailability async {
    final bool availability = await _channel
        .invokeMethod('checkNfcAvailability')
        .catchError((e) => throw (_mapException(e)));
    return availability;
  }

  static Future<Uint8List> get readMailbox async {
    final Uint8List msg = await _channel
        .invokeMethod('readMailbox')
        .catchError((e) => throw (_mapException(e)));
    return msg;
  }

  static Future<Uint8List> readBlock(int address) async {
    final Uint8List ris = await _channel
        .invokeMethod('readBlock', address)
        .catchError((e) => throw (_mapException(e)));
    return ris;
  }

  static Future<Uint8List> readBlocks(int address, int numBlocks) async {
    final Uint8List ris = await _channel.invokeMethod('readBlocks', {
      "address": address,
      "blocks": numBlocks
    }).catchError((e) => throw (_mapException(e)));
    return ris;
  }

  static Future<void> presentPassword(
      int passwordNumber, List<int> password) async {
    await _channel.invokeMethod('presentPassword', {
      "passwordNumber": passwordNumber,
      "password": password
    }).catchError((e) => throw (_mapException(e)));
  }

  static Future<void> writePassword(
      int passwordNumber, List<int> password) async {
    await _channel.invokeMethod('writePassword', {
      "passwordNumber": passwordNumber,
      "password": password
    }).catchError((e) => throw (_mapException(e)));
  }

  static Future<String> resetMailBox() async {
    final String ris = await _channel
        .invokeMethod('resetMailbox')
        .catchError((e) => throw (_mapException(e)));
    return ris;
  }

  static Future<MailBox> getMailBoxInfo() async {
    Map<dynamic, dynamic> map = await _channel
        .invokeMethod('getMailboxInfo')
        .catchError((e) => throw (_mapException(e)));
    return MailBox.fromMap(map);
  }

  static Future<String> writeMailBoxByte(Uint8List msg) async {
    final String ris = await _channel
        .invokeMethod('writeMailbox', msg)
        .catchError((e) => throw (_mapException(e)));
    return ris;
  }

  static Future<String> writeNDEFString(String msg) async {
    final String ris = await _channel
        .invokeMethod('writeNDEF', msg)
        .catchError((e) => throw (_mapException(e)));
    return ris;
  }

  static Future<String> readNDEF() async {
    final String ris = await _channel
        .invokeMethod('readNDEF')
        .catchError((e) => throw (_mapException(e)));
    return ris;
  }

  static void _createTagStream() {
    _tagStream = _eventChannel
        .receiveBroadcastStream()
        .map<St25Tag>((event) => St25Tag.fromMap(event));
  }

  static Stream<St25Tag> startReading() {
    if (_tagStream == null) {
      _createTagStream();
    }
    // Create a StreamController to wrap the tag stream. Any errors will be
    // converted to their matching exception classes. The controller stream will
    // be closed if the errors are fatal.
    StreamController<St25Tag> controller = StreamController();
    final stream = _tagStream!;
    // Listen for tag reads.
    final subscription = stream.listen(
      (tag) => controller.add(tag),
      onError: (error) {
        /* error = _mapException(error);
        if (!throwOnUserCancel && error is NFCUserCanceledSessionException) {
          return;
        }*/

        error = _mapException(error);
        controller.addError(error);

        //controller.close();
      },
      onDone: () {
        _tagStream = null;
        controller.close();
      },
      // cancelOnError: false
      // cancelOnError cannot be used as the stream would cancel BEFORE the error
      // was sent to the controller stream
    );

    controller.onCancel = () {
      subscription.cancel();
    };

    try {
      _channel.invokeMethod("startReading");
    } catch (error) {
      print("error on reading " + error.toString());
      throw error;
    }
    return controller.stream;
  }
}

Exception _mapException(dynamic error) {
  if (error is PlatformException) {
    switch (error.code) {
      case "TAG_NOT_IN_THE_FIELD":
        error = NfcTagNotInTheFieldException(error.message ?? "");
        break;
      case "UNABLE_TO_READ_MAILBOX":
        error = NfcUnableReadMailBoxException(error.message ?? "");
        break;
      case "UNABLE_TO_GET_INFO":
        error = NfcUnableGetInfoException(error.message ?? "");
        break;
      case "ACTION_FAILED":
        error = NfcActionFailedException(error.message ?? "");
        break;
      default:
        error = NfcGeneralException(error.message ?? "");
    }
  }
  return error;
}
