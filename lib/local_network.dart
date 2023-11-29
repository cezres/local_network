library local_network;

import 'dart:async';
import 'dart:io';
import 'dart:convert' as convert;

import 'package:flutter/foundation.dart';
import 'package:local_network/connected_device.dart';
import 'package:local_network/discovered_device.dart';
import 'package:nsd/nsd.dart' as nsd;

part 'local_network.internal.dart';

typedef SocketEventInstanceBuilder<T> = T Function(Map<String, dynamic> json);

typedef SocketEventCallback<T extends SocketEvent> = void Function(
    T event, ConnectedDevice device);

abstract class LocalNetwork {
  static final LocalNetwork _shared = _LocalNetworkInternal();
  factory LocalNetwork() => _shared;
  LocalNetwork._();

  List<DiscoveredDevice> get discoveredDevices;
  Stream<List<DiscoveredDevice>> get discoveredDevicesStream;

  List<ConnectedDevice> get connectedDevices;
  Stream<List<ConnectedDevice>> get connectedDevicesStream;

  Future<void> initialize({required String uuid});

  Future<void> connect(DiscoveredDevice device);

  Future<void> disconnect(ConnectedDevice device);

  void registerSocketEventInstanceBuilder<T extends SocketEvent>(
      SocketEventInstanceBuilder<T> builder);

  void addListener<T extends SocketEvent>(SocketEventCallback<T> listener);

  void removeListener<T extends SocketEvent>(SocketEventCallback<T> listener);
}
