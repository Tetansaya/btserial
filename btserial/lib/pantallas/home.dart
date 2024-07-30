import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _bluetooth = FlutterBluetoothSerial.instance;
  bool BTstate = false;
  bool BTconected = false;
  BluetoothConnection? connection;
  List<BluetoothDevice> devices = [];
  BluetoothDevice? device;
  String contenido = "";

  @override
  void initState() {
    super.initState();
    permisos();
    estadoBT();
  }

  void permisos() async {
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetooth.request();
    await Permission.location.request();
  }

  void estadoBT() {
    _bluetooth.state.then((value) {
      setState(() {
        BTstate = value.isEnabled;
      });
    });
    _bluetooth.onStateChanged().listen((event) {
      switch (event) {
        case BluetoothState.STATE_ON:
          BTstate = true;
          break;
        case BluetoothState.STATE_OFF:
          BTstate = false;
          break;
        default:
          break;
      }
      setState(() {});
    });
  }

  void encenderBT() async {
    await _bluetooth.requestEnable();
  }

  void apagarBT() async {
    await _bluetooth.requestDisable();
  }

  Widget switchBT() {
    return SwitchListTile(
        title: BTstate
            ? const Text('Bluetooth Encendido')
            : const Text('Bluetooth Apagado'),
        activeColor: BTstate ? Colors.cyanAccent : Colors.redAccent,
        tileColor: BTstate ? Colors.cyan : Colors.red,
        value: BTstate,
        onChanged: (bool value) {
          if (value) {
            encenderBT();
          } else {
            apagarBT();
          }
        },
        secondary: BTstate
            ? const Icon(Icons.bluetooth)
            : const Icon(Icons.bluetooth_disabled));
  }

  Widget indoDisp() {
    return ListTile(
      title: device == null ? Text("Sin Dispositivo") : Text("${device?.name}"),
      subtitle:
      device == null ? Text("Sin Dispositivo") : Text("${device?.address}"),
      trailing: BTconected
          ? IconButton(
          onPressed: () async {
            await connection?.finish();
            BTconected = false;
            devices = [];
            device = null;
            setState(() {});
          },
          icon: Icon(Icons.delivery_dining_sharp))
          : IconButton(
          onPressed: () {
            ListDisp();
          },
          icon: Icon(Icons.search_rounded)),
    );
  }

  void ListDisp() async {
    devices = await _bluetooth.getBondedDevices();
    setState(() {});
  }

  void recibirDatos() {
    connection?.input?.listen((event) {
      contenido += String.fromCharCodes(event);
      setState(() {});
    });
  }

  void conectarDispositivo(BluetoothDevice selectedDevice) async {
    connection = await BluetoothConnection.toAddress(selectedDevice.address);
    device = selectedDevice;
    BTconected = true;
    recibirDatos();
    setState(() {});
  }

  Widget lista() {
    if (BTconected) {
      return SingleChildScrollView(
        child: Text(
          contenido,
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 10.0,
          ),
        ),
      );
    } else {
      return devices.isEmpty
          ? Text("No hay dispositivos")
          : ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text("${devices[index].name}"),
            subtitle: Text("${devices[index].address}"),
            trailing: IconButton(
              icon: Icon(Icons.bluetooth_connected),
              onPressed: () => conectarDispositivo(devices[index]),
            ),
          );
        },
      );
    }
  }

  void enviarDatos(String msg) {
    if (connection!.isConnected) {
      connection?.output.add(ascii.encode('$msg\n'));
    }
  }

  Widget botonera() {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          CupertinoButton(
              child: const Icon(Icons.lightbulb),
              onPressed: () {
                enviarDatos("led_on");
              }),
          CupertinoButton(
              child: const Icon(Icons.lightbulb_outline),
              onPressed: () {
                enviarDatos("led_off");
              }),
          CupertinoButton(
              child: const Icon(Icons.waving_hand),
              onPressed: () {
                enviarDatos("hello");
              }),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Flutter <3 Bluetooth"),
      ),
      body: Column(
        children: <Widget>[
          switchBT(),
          const Divider(
            height: 5,
          ),
          indoDisp(),
          const Divider(
            height: 5,
          ),
          Expanded(child: lista()),
          const Divider(
            height: 5,
          ),
          botonera()
        ],
      ),
    );
  }
}
