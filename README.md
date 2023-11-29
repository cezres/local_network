<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features

在本地网络中发现其它相同服务的设备。

## Getting started

```
local_network:
    git:
        url: https://github.com/cezres/local_network.git
        ref: main
```

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
/// Initialize
final LocalNetwork localNetwork = LocalNetwork();
localNetwork.initialize(uuid: uuid.v4());

/// Listen
localNetwork.discoveredDevicesStream.listen((event) {
    for (var element in event) {
        debugPrint("Discovered Device: ${element.uuid} ${element.address}:${element.port}");
    }
});
localNetwork.connectedDevicesStream.listen((event) {
    for (var element in event) {
        debugPrint("Connected Device: ${element.address}:${element.port}");
    }
});

/// Connect Device
localNetwork.connect(discoveredDevice);

/// Disconnect Device
localNetwork.disconnect(connectedDevice);

/// Send Data
connectedDevice.send(event);
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
