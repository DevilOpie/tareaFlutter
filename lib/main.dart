import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tfliszvzjuwxjnlqlrho.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmbGlzenZ6anV3eGpubHFscmhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDMwMjI1NTUsImV4cCI6MjAxODU5ODU1NX0.3I64cp8zjnLyN8sJOzSuqlXj3etjWbymsXDrtTx4ecA',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const FirstScreen(),
      routes: {
        '/game': (context) => const GameScreen(),
        '/puntuaciones': (context) => const PuntuacionesScreen(),
      },
    );
  }
}


class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
      ),
      body: Container(
        color: Colors.grey[200], 
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'EL JUEGUILLO',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20), // Espacio entre el texto y el botón
              // Botón para empezar 
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/game'); // Redirige a la pantalla de juego
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink, // Color de fondo del botón
                ),
                child: const Text(
                  'Empezar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int puntuacion = 0;
  List<String> images = [
    'assets/king.jpeg', 
    'assets/queen.jpeg',
    'assets/knight.jpeg',
    'assets/pawn.jpeg',
  ];

  List<String> selectedImages = [];

  @override
  void initState() {
    super.initState();
    selectedImages = List.from(images)..shuffle();
  }

  void checkAnswer(int index) {
    if (selectedImages[index] == images[index]) {
      setState(() {
        puntuacion += 2;
      });
    } else {
      setState(() {
        puntuacion -= 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Juego'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // Cuatro imágenes aleatorias
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              return GestureDetector(
                onTap: () => checkAnswer(index),
                child: Image.asset(
                  selectedImages[index],
                  width: 80,
                  height: 80,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          // Cuatro imágenes fijas abajo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              return Image.asset(
                images[index],
                width: 80,
                height: 80,
              );
            }),
          ),
          const SizedBox(height: 20),
          Text(
            'Puntuación: $puntuacion',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/registro');
            },
            child: const Text('Ir a Registro'),
          ),
        ],
      ),
    );
  }
}

class RegistroScreen extends StatelessWidget {
  final SupabaseClient supabase;
  final TextEditingController _nameController = TextEditingController();
  final int score;

  RegistroScreen(this.supabase, this.score);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _nameController,
              maxLength: 3,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Ingresa un nombre de 3 letras',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.length == 3) {
                  // Guardar el nombre y la puntuación en la base de datos
                  final response = await supabase.from('puntuacion').insert([
                    {'name': _nameController.text, 'score': score}
                  ]).execute();

                  if (response.error == null) {
                    Navigator.pushNamed(context, '/puntuaciones');
                  } else {
                    // Manejar el error al insertar en la base de datos
                    print('Error al guardar los datos: ${response.error}');
                  }
                } else {
                  // Mostrar un mensaje si el nombre no tiene 3 letras
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ingresa un nombre de 3 letras'),
                    ),
                  );
                }
              },
              child: Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

class PuntuacionesScreen extends StatefulWidget {
  const PuntuacionesScreen({Key? key}) : super(key: key);

  @override
  _PuntuacionesScreenState createState() => _PuntuacionesScreenState();
}

class _PuntuacionesScreenState extends State<PuntuacionesScreen> {
  List<Map<String, dynamic>> scores = [];

  @override
  void initState() {
    super.initState();
    fetchData(); // Llamada a la función para cargar los datos al iniciar la pantalla
  }

  Future<void> fetchData() async {
    final response = await Supabase.instance.client.from('puntuacion').select().order('score', ascending: false).execute();

    if (response.error == null) {
      setState(() {
        scores = response.data as List<Map<String, dynamic>>;
      });
    } else {
      // Manejar el error al obtener los datos de la base de datos
      print('Error al obtener datos: ${response.error}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Puntuaciones'),
      ),
      body: ListView.builder(
        itemCount: scores.length,
        itemBuilder: (context, index) {
          final scoreData = scores[index];
          final name = scoreData['name'];
          final score = scoreData['score'];

          return ListTile(
            title: Text('$name - Puntuación: $score'),
          );
        },
      ),
    );
  }
}