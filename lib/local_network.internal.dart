part of 'local_network.dart';

const _kServiceName = '_LN_';
const _kServiceType = '_http._tcp';
const _kServicePort = 46821;
const _kSocketServerPort = 46822;

Map<String, SocketEventInstanceBuilder> _socketEventInstanceBuilders = {
  (TestSocketEvent).toString(): TestSocketEvent.fromJson,
};

class _LocalNetworkInternal extends LocalNetwork {
  _LocalNetworkInternal() : super._() {
    //
  }

  final Map<Type, List<SocketEventCallback>> _listeners = {};
  String _uuid = "";
  DiscoveredDevice? currentDevice;

  @override
  Future<void> initialize({required String uuid}) async {
    _uuid = uuid;
    if (Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows) {
      startDiscovery();
      register(uuid);
    }
    startSocketServer();
  }

  @override
  void registerSocketEventInstanceBuilder<T extends SocketEvent>(
      SocketEventInstanceBuilder<T> builder) {
    _socketEventInstanceBuilders[T.toString()] = builder;
  }

  @override
  void addListener<T extends SocketEvent>(SocketEventCallback<T> listener) {
    _listeners[T] = [listener as SocketEventCallback];
    if (_listeners.containsKey(T)) {
      if (!_listeners[T]!.contains(listener)) {
        _listeners[T]!.add(listener);
      }
    } else {
      _listeners[T] = [listener];
    }
  }

  @override
  void removeListener<T extends SocketEvent>(SocketEventCallback<T> listener) {
    if (_listeners.containsKey(T)) {
      _listeners[T]!.remove(listener);
    }
  }

  @override
  Future<void> connect(DiscoveredDevice device) async {
    final socket = await Socket.connect(device.address, device.socketPort);
    debugPrint(
        "Socket Client ${socket.remoteAddress.address}:${socket.remotePort} - connected");
    _addConnectedDevice(socket);
  }

  @override
  Future<void> disconnect(ConnectedDevice device) async {
    _removeConnectedDevice(device);
    try {
      await device.close();
    } catch (e) {
      debugPrint("$e");
    }
  }

  final _discoveredDevices = <DiscoveredDevice>[];

  final _discoveredDevicesStreamController =
      StreamController<List<DiscoveredDevice>>.broadcast();

  @override
  List<DiscoveredDevice> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);

  @override
  Stream<List<DiscoveredDevice>> get discoveredDevicesStream =>
      _discoveredDevicesStreamController.stream;

  nsd.Discovery? _discovery;
  nsd.Registration? _registration;

  Future<void> startDiscovery() async {
    assert(_discovery == null);

    try {
      _discovery = await nsd.startDiscovery(
        _kServiceType,
        ipLookupType: nsd.IpLookupType.v4,
      );
      debugPrint("discovery: $_discovery");
      _discovery!.addServiceListener((service, status) {
        final device = DiscoveredDevice.fromService(service);
        if (device == null) {
          debugPrint("device is null: $service");
          return;
        }

        if (device.uuid == _uuid) {
          if (status == nsd.ServiceStatus.found) {
            currentDevice = device;
          } else {
            currentDevice = null;
          }
        } else {
          if (status == nsd.ServiceStatus.found) {
            _discoveredDevices.add(device);
          } else {
            _discoveredDevices.remove(device);
          }
          _discoveredDevicesStreamController.add(_discoveredDevices);
        }
      });

      _discovery!.addListener(() {
        debugPrint("discovery: ${_discovery!.services}");
      });
    } catch (e) {
      debugPrint("$e");
      rethrow;
    }
  }

  Future<void> stopDiscovery() async {
    assert(_discovery != null);

    try {
      await nsd.stopDiscovery(_discovery!);
    } catch (e) {
      debugPrint("$e");
    }
    _discovery = null;
  }

  Future<void> register(String uuid) async {
    assert(_registration == null);

    try {
      _registration = await nsd.register(nsd.Service(
        name: _kServiceName,
        type: _kServiceType,
        port: _kServicePort,
        txt: DiscoveredDevice.buildTxt(
          uuid: uuid,
          socketPort: _kSocketServerPort,
        ),
      ));
      debugPrint("registration: $_registration");
    } catch (e) {
      debugPrint("$e");
      rethrow;
    }
  }

  Future<void> unregister() async {
    assert(_registration != null);

    try {
      await nsd.unregister(_registration!);
    } catch (e) {
      debugPrint("$e");
    }
    _registration = null;
  }

  ///
  ///
  ///

  final List<ConnectedDevice> _connectedDevices = [];
  final _connectedDevicesStreamController =
      StreamController<List<ConnectedDevice>>.broadcast();

  @override
  List<ConnectedDevice> get connectedDevices =>
      List.unmodifiable(_connectedDevices);
  @override
  Stream<List<ConnectedDevice>> get connectedDevicesStream =>
      _connectedDevicesStreamController.stream;

  ServerSocket? _serverSocket;
  StreamSubscription<Socket>? _serverSocketSubscription;

  Future<void> startSocketServer() async {
    assert(_serverSocket == null);

    try {
      _serverSocket = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        _kSocketServerPort,
      );
      debugPrint(
          "Socket Server: ${_serverSocket!.address.address}:${_serverSocket!.port}");

      _serverSocketSubscription = _serverSocket!.listen(
        (socket) {
          debugPrint(
              "Socket Server onData: ${socket.remoteAddress.address}:${socket.remotePort}");
          _addConnectedDevice(socket);
        },
        onDone: () {
          debugPrint("Socket Server onDone");
        },
        onError: (e) {
          debugPrint("Socket Server onError: $e");
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint("$e");
      rethrow;
    }
  }

  Future<void> stopSocketServer() async {
    /// Close server socket
    _serverSocketSubscription?.cancel();
    try {
      await _serverSocket?.close();
    } catch (e) {
      debugPrint("$e");
    }
    _serverSocket = null;

    /// Close all connected devices
    for (var element in _connectedDevices) {
      try {
        await element.socket.close();
      } catch (e) {
        debugPrint("$e");
      }
    }
    _connectedDevices.clear();
  }

  void _addConnectedDevice(Socket socket) {
    final device = ConnectedDevice(socket: socket);
    socket.listen(
      (event) {
        _socketEventHnadler(event, device);
      },
      onDone: () {
        debugPrint(
            "Socket Client onData onDone: ${socket.remoteAddress.address}:${socket.remotePort}");
        _removeConnectedDevice(device);
      },
      onError: (e) {
        debugPrint(
            "Socket Client onData onError: ${device.address}:${device.port} - $e");
        _removeConnectedDevice(device);
      },
      cancelOnError: true,
    );
    _connectedDevices.add(ConnectedDevice(socket: socket));
    _connectedDevicesStreamController.add(_connectedDevices);
  }

  void _removeConnectedDevice(ConnectedDevice device) {
    _connectedDevices.remove(device);
    _connectedDevicesStreamController.add(_connectedDevices);
  }

  void _socketEventHnadler(Uint8List event, ConnectedDevice device) {
    try {
      String string = String.fromCharCodes(event);
      debugPrint(
          "Socket Client  onData: ${device.address}:${device.port} - $string");

      final json = convert.json.decode(string);
      final type = json["type"] as String;
      final instanceBuilder = _socketEventInstanceBuilders[type];
      if (instanceBuilder == null) {
        throw "instanceBuilder is null";
      }
      final socketEvent = instanceBuilder(json["data"]);
      debugPrint("socketEvent: $socketEvent");
    } catch (e) {
      debugPrint("$e");
    }
  }
}
