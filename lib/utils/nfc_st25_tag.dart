// To parse this JSON data, do
//
//     final st25Tag = st25TagFromMap(jsonString);

import 'dart:convert';

class St25Tag {
  St25Tag({
    required this.name,
    required this.description,
    required this.uid,
    this.memorySize = 0,
    this.mailBox,
  });

  String name, description, uid;
  int memorySize;
  MailBox? mailBox;

  factory St25Tag.fromJson(String str) => St25Tag.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory St25Tag.fromMap(Map<dynamic, dynamic> json) => St25Tag(
        name: json["name"] ?? "",
        description: json["description"] ?? "",
        uid: json["uid"] ?? "",
        memorySize: json["memory_size"] == null ? null : json["memory_size"],
        mailBox:
            json["mail_box"] == null ? null : MailBox.fromMap(json["mail_box"]),
      );

  Map<String, dynamic> toMap() => {
        "name": name,
        "description": description,
        "uid": uid,
        "memory_size": memorySize,
        "mail_box": mailBox == null ? null : mailBox!.toMap(),
      };
}

class MailBox {
  MailBox({
    this.mailboxEnabled,
    this.msgPutByController,
    this.msgPutByNfc,
    this.msgMissByController,
    this.msgMissByNfc,
  });

  bool? mailboxEnabled;
  bool? msgPutByController;
  bool? msgPutByNfc;
  bool? msgMissByController;
  bool? msgMissByNfc;

  @override
  String toString() {
    return " mailboxEnabled: $mailboxEnabled\n msgPutByController: $msgPutByController\n msgPutByNfc: $msgPutByNfc\n msgMissByController: $msgMissByController\n msgMissByNfc:$msgMissByNfc \n ";
  }

  factory MailBox.fromJson(String str) => MailBox.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory MailBox.fromMap(Map<dynamic, dynamic> json) => MailBox(
        mailboxEnabled:
            json["mailbox_enabled"] == null ? null : json["mailbox_enabled"],
        msgPutByController: json["msg_put_by_controller"] == null
            ? null
            : json["msg_put_by_controller"],
        msgPutByNfc:
            json["msg_put_by_nfc"] == null ? null : json["msg_put_by_nfc"],
        msgMissByController: json["msg_miss_by_controller"] == null
            ? null
            : json["msg_miss_by_controller"],
        msgMissByNfc:
            json["msg_miss_by_nfc"] == null ? null : json["msg_miss_by_nfc"],
      );

  Map<String, dynamic> toMap() => {
        "mailbox_enabled": mailboxEnabled == null ? null : mailboxEnabled,
        "msg_put_by_controller":
            msgPutByController == null ? null : msgPutByController,
        "msg_put_by_nfc": msgPutByNfc == null ? null : msgPutByNfc,
        "msg_miss_by_controller":
            msgMissByController == null ? null : msgMissByController,
        "msg_miss_by_nfc": msgMissByNfc == null ? null : msgMissByNfc,
      };
}
