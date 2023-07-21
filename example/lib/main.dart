import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:local_network/connected_device.dart';
import 'package:local_network/discovered_device.dart';
import 'package:local_network/local_network.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final LocalNetwork localNetwork = LocalNetwork();

  @override
  void initState() {
    super.initState();

    const Uuid uuid = Uuid();

    localNetwork.initialize(
      uuid: uuid.v4(),
    );

    localNetwork.registerSocketEventInstanceBuilder(CustomSocketEvent.fromJson);
  }

  void _incrementCounter() {
    //
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Discovery"),
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildTitle("Discovered Devices:"),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  sliver: StreamBuilder(
                    initialData: localNetwork.discoveredDevices,
                    stream: localNetwork.discoveredDevicesStream,
                    builder: (context, snapshot) {
                      return _buildDiscoveredDevices(snapshot.requireData);
                    },
                  ),
                ),
                _buildTitle("Connected Devices:"),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  sliver: StreamBuilder(
                    initialData: localNetwork.connectedDevices,
                    stream: localNetwork.connectedDevicesStream,
                    builder: (context, snapshot) {
                      return _buildConnectedDevices(snapshot.requireData);
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTitle(String title) {
    return SliverList.list(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoveredDevices(List<DiscoveredDevice> list) {
    return SliverList.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final device = list[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: _buildDiscoveredDeviceContainer(device),
        );
      },
    );
  }

  Widget _buildConnectedDevices(List<ConnectedDevice> list) {
    return SliverList.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final device = list[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text("${device.address}:${device.port}"),
                Row(
                  children: [
                    _buildEventButton("Disconnect", () {
                      localNetwork.disconnect(device);
                    }),
                    _buildEventButton("Send", () async {
                      // device.send("Azusa");
                      // device.send(const TestSocketEvent(
                      //   id: 23,
                      //   message: "Azusa",
                      // ));
                      await device.send(const CustomSocketEvent(
                        id: 23,
                        message: "Nananana",
                      ));
                      await device.send(const CustomSocketEvent(
                        id: 23,
                        message: "Nananana",
                      ));
                    }),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiscoveredDeviceContainer(DiscoveredDevice device) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            "${device.address} (${device.serviceName})",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text("Host: ${device.host}"),
          Text("UUID: ${device.uuid}"),
          // Text("Port: ${device.socketPort}"),
          Row(
            children: [
              _buildEventButton("Connect", () {
                localNetwork.connect(device);
              }),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEventButton(String title, VoidCallback onPressed) {
    return Expanded(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomSocketEvent extends SocketEvent {
  const CustomSocketEvent({
    required this.id,
    required this.message,
  });

  CustomSocketEvent.fromJson(Map<String, dynamic> json)
      : this(id: json["id"], message: json["message"]);

  final int id;
  final String message;

  @override
  Map<String, dynamic> toJson() {
    return {"id": id, "message": message};
  }
}
