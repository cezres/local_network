import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart';

class DiscoveredDevice extends Equatable {
  const DiscoveredDevice({
    required this.serviceName,
    required this.host,
    required this.port,
    required this.address,
    required this.uuid,
    required this.socketPort,
  });

  final String serviceName;

  final String host;

  final int port;

  final String address;

  // txt
  final String uuid;
  final int socketPort;

  static DiscoveredDevice? fromService(Service service) {
    final serviceName = service.name;
    final host = service.host;
    final port = service.port;
    final address = service.addresses
        ?.firstWhere((element) =>
            !element.isLinkLocal && !element.isLoopback && !element.isMulticast)
        .address;
    if (serviceName == null ||
        host == null ||
        port == null ||
        address == null) {
      return null;
    }

    // txt
    final spBytes = service.txt?['sp'];
    final uuidBytes = service.txt?["uuid"];
    if (spBytes == null || uuidBytes == null) {
      return null;
    }

    final uuid = String.fromCharCodes(uuidBytes);
    final socketPort = int.parse(String.fromCharCodes(spBytes));

    return DiscoveredDevice(
      serviceName: serviceName,
      host: host,
      port: port,
      address: address,
      uuid: uuid,
      socketPort: socketPort,
    );
  }

  @override
  List<Object?> get props => [
        serviceName,
        port,
        address,
        uuid,
        socketPort,
      ];

  static Map<String, Uint8List?>? buildTxt(
      {required String uuid, required int socketPort}) {
    return {
      "uuid": Uint8List.fromList(uuid.codeUnits),
      "sp": Uint8List.fromList(socketPort.toString().codeUnits),
    };
  }
}
