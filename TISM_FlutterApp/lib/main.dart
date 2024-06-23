import 'dart:async';
import 'package:flutter/material.dart';
import 'package:appiot/src/db/db.dart';
import 'package:appiot/src/models/sensor.dart';
import 'package:appiot/src/models/actuator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appiot/src/api/firebaseapi.dart';
import 'src/screens/login_screen.dart'; // Altere o caminho conforme necessário
import 'src/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Certifique-se de que o Flutter foi inicializado

  try {
    Db.database = await Db.connect(); // Conecta ao banco de dados
  } catch (e) {
    print("Erro ao conectar ao banco de dados: $e");
  }

  // Inicia a tarefa em background para buscar dados da API e inserir no banco de dados a cada 5 segundos
  Timer.periodic(Duration(seconds: 60), (timer) async {
    await fetchAndStoreSensorData();
    await fetchAndStoreActuatorData();
  });

  // Verifica se o usuário está autenticado
  try {
    final prefs = await SharedPreferences.getInstance();
    final String? username = prefs.getString('username');
    final String? password = prefs.getString('password');

    final initialRoute = (username != null && password != null) ? '/home' : '/login';
    runApp(MyApp(initialRoute: initialRoute));
  } catch (e) {
    print("Erro ao obter SharedPreferences: $e");
    runApp(MyApp(initialRoute: '/login'));
  }
}

Future<void> fetchAndStoreSensorData() async {
  final Firebaseapi _firebaseapi = Firebaseapi();

  try {
    final sensorInfoList = await _firebaseapi.fetchSensorInfo();
    final sensorDataMap = await _firebaseapi.fetchLastSensorsDataValueMap();

    for (var info in sensorInfoList) {
      final sensorData = sensorDataMap[info.id];

      var sensorOut = sensorData != null
          ? Sensor(
              id: info.id,
              timestamp: sensorData.timestamp,
              description: info.description,
              outputPin1: info.outputPin1,
              outputPin2: info.outputPin2,
              analogValue: sensorData.analogValue,
              digitalValue: sensorData.digitalValue,
              unit: sensorData.unit,
            )
          : Sensor(
              id: info.id,
              description: info.description,
              outputPin1: info.outputPin1,
              outputPin2: info.outputPin2,
            );

      await Db.insertSensor(Db.database!, sensorOut);
      print("Inseriu sensor no bancoO");
    }
  } catch (e) {
    print('Failed to fetch sensor data: $e');
  }
}

Future<void> fetchAndStoreActuatorData() async {
  final Firebaseapi _firebaseapi = Firebaseapi();

  try {
    final actuatorInfoList = await _firebaseapi.fetchActuatorInfo();
    final actuatorDataMap = await _firebaseapi.fetchLastActuatorsDataValueMap();

    for (var info in actuatorInfoList) {
      final actuatorData = actuatorDataMap[info.id];

      var actuatorOut = actuatorData != null
          ? Actuator(
              id: info.id,
              timestamp: actuatorData.timestamp,
              description: info.description,
              outputPin: info.outputPin,
              outputPWM: actuatorData.outputPWM,
              unit: actuatorData.unit,
            )
          : Actuator(
              id: info.id,
              description: info.description,
              outputPin: info.outputPin,
            );

      await Db.insertActuator(Db.database!, actuatorOut);
      print("Inseriu atuador no banco");
    }
  } catch (e) {
    print('Failed to fetch actuator data: $e');
  }
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({required this.initialRoute, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
