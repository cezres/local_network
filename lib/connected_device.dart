import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

// SocketEvent _decodeSocketEvent(Map<String, dynamic> json) {
//   final type = json["type"];
//   if (type != null) {
//     throw "type is null";
//   }
//   final instanceBuilder = _socketEventInstanceBuilders[type];
//   if (instanceBuilder == null) {
//     throw "instanceBuilder is null";
//   }
//   final event = instanceBuilder(json["data"]);
//   debugPrint("event: $event");
//   return event;
// }

// ignore: must_be_immutable
class ConnectedDevice extends Equatable {
  ConnectedDevice({required this.socket})
      : address = socket.remoteAddress.address,
        port = socket.remotePort;

  final Socket socket;

  final String address;

  final int port;

  bool _closed = false;

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;

    try {
      await socket.close();
    } catch (e) {
      debugPrint("$e");
    }
  }

  Future<void> send(SocketEvent object) async {
    await socket.flush();
    socket.add(object._toBytes());
    return socket.flush();
  }

  @override
  List<Object?> get props => [
        socket.remoteAddress.address,
        socket.remotePort,
        socket.address.address,
        socket.port,
      ];
}

abstract class SocketEvent {
  const SocketEvent();

  const SocketEvent.xA(Map<String, dynamic> map);

  Map<String, dynamic> toJson();

  List<int> _toBytes() {
    final map = {
      "type": "$runtimeType",
      "data": toJson(),
    };
    final string = json.encode(map);
    return string.codeUnits;
  }
}

class TestSocketEvent extends SocketEvent {
  const TestSocketEvent({
    required this.id,
    required this.message,
  });

  TestSocketEvent.fromJson(Map<String, dynamic> json)
      : this(id: json["id"], message: json["message"]);

  final int id;
  final String message;

  @override
  Map<String, dynamic> toJson() {
    return {"id": id, "message": message};
  }
}
