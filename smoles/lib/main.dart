import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart'; // For CSV parsing
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Smoles',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  int currentPlot = 0;
  bool isRecording = false;
  bool isDarkMode = false;
  bool isClockLaunched = false;

  // put some states change there
  void toggleCurrentPlot(int value) {
    currentPlot = value;
    notifyListeners();
  }

  void toggleRecording() {
    isRecording = !isRecording;
    isClockLaunched = !isClockLaunched;
    notifyListeners();
  }

  void toggleDarkMode() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = Analysis();
      case 1:
        page = Recording();
      case 2: 
        page = Settings();
      default:
        throw UnimplementedError('No widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,  // ← Here.
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.scatter_plot_sharp),
                    label: Text('Analyse'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.record_voice_over),
                    label: Text('Recording'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings),
                    label: Text('Settings'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class IntegerSlider extends StatefulWidget {
  @override
  IntegerSliderState createState() => IntegerSliderState();
}

class IntegerSliderState extends State<IntegerSlider> {
  // Initial value for the slider
  double _currentValue = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Slider widget for choosing integer values
          Slider(
            value: _currentValue,
            min: 0,
            max: 16,
            divisions: 100,  // Makes the slider snap to integer values
            label: _currentValue.round().toString(),
            onChanged: (value) {
              setState(() {
                _currentValue = value;
              });
            },
          ),
          Text(
            'Selected value: ${_currentValue.round()}',
            style: TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }
}

class Analysis extends StatefulWidget {
  @override
  AnalysisState createState() => AnalysisState();
}

class AnalysisState extends State<Analysis> {
  List<int> timestamps = [];
  List<String> feet = [];
  List<List<int>> values =  [];

  bool _isLoading = true;


  // Your async function
  Future<void> fetchData() async {
    var data = await parseCsvFile("data/240704_1214_standing_old-board.csv");
    setState(() {
      timestamps = data.timestamps;
      feet   = data.feet;
      values = data.values;

      _isLoading = false;
    });
  }

    @override
  void initState() {
    super.initState();
    fetchData(); // Start fetching data when the widget is initialized
  }

  Widget chooseWidget(int index) {
    if (_isLoading) {
      return CircularProgressIndicator();
    }
    else {
      var x = timestamps;
      var y = values[index];
      //var x = [1,2,3,4];
      //var y = [5,6,7,8];
      return SizedBox(
        width: double.infinity,
        height: 300,
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                isCurved: true, // Smooth curve
                spots: List.generate(
                  x.length,
                  (index) => FlSpot(x[index].toDouble(), y[index].toDouble()),
                ),
                color: Colors.blue, // Line color
                barWidth: 3,          // Line thickness
                dotData: FlDotData(show: true), // Show points on the line
              ),
            ],
            gridData: FlGridData(show: true), // Optional grid
            borderData: FlBorderData(show: true), // Optional border
          ),
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          chooseWidget(appState.currentPlot),

          Slider(
            value: appState.currentPlot.toDouble(),
            min: 0,
            max: 16,
            divisions: 100,  // Makes the slider snap to integer values
            label: appState.currentPlot.round().toString(),
            onChanged: (value) {
              setState(() {
                appState.currentPlot = value.clamp(0, 15).toInt(); // Clamp prevents crash through overflow
              });
            },
          ),


          ElevatedButton(
            onPressed: () {
              //({List<int> timestamps, List<String> feet, List<List<int>> values}) data = await appState.parseCsvFile("data/240704_1214_standing_old-board.csv");
            },
            child: Text('Load Data'),
          ),
        ],
      ),
    );
  }
}

class Recording extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            appState.isRecording ? "Recording in progress" : "Recording stopped",
            style: TextStyle(
              fontSize: 24.0,               
              fontWeight: FontWeight.bold  
            )
          ),

          StreamBuilder<int>(
            stream: Stream.periodic(Duration(milliseconds: 10), (count) => count),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active && appState.isClockLaunched) {
                int count = snapshot.data ?? 0;
                int minutes = count ~/60000;
                int seconds      = (count ~/ 100)%60; // Divide by 100 to get minutes
                int centiseconds = (count)%100;  // Divide by 10 to get seconds
                   // Get the last digit for centiseconds

                return Text(
                  '$minutes:${seconds.toString().padLeft(2, '0')}.${centiseconds.toString().padLeft(2, '0')}', // Format as mm:ss.cc
                  style: TextStyle(fontSize: 50),
                );
              }
              return Text(
                "0:00.00",
                style: TextStyle(fontSize: 50)
              );
            },
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: Icon(appState.isRecording ? Icons.play_arrow : Icons.pause),
                  iconSize: 64.0,
                  color: Colors.brown,
                  onPressed: () {
                    appState.toggleRecording();
                  },
                ),
              ),
    
            ],
          ),
        ],
      )
    );

  }
}

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Dark Mode'),
            trailing: Switch(
              value: appState.isDarkMode,
              onChanged: (bool value) {
                appState.toggleDarkMode();
              },
            ),
          ),
          ListTile(
            title: Text('Language'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              // Handle navigation to language settings
            },
          ),
          ListTile(
            title: Text('Many things to be added ...'),
            trailing: Icon(Icons.backpack)
          ),

        ]
      )
    );

  }
}








class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),

        // ↓ Make the following change.
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",
        ),
      ),
    );
  }
}



List<List<int>> transpose(List<List<int>> matrix) {
  if (matrix.isEmpty) return [];

  int rows = matrix.length;
  int cols = matrix[0].length;

  // Create an empty matrix with dimensions flipped
  List<List<int>> transposed = List.generate(cols, (_) => List.filled(rows, 0));

  for (int i = 0; i < rows; i++) {
    for (int j = 0; j < cols; j++) {
      transposed[j][i] = matrix[i][j];
    }
  }

  return transposed;
}


  Future<({
    List<int> timestamps,
    List<String> feet,
    List<List<int>> values,
  })> parseCsvFile(String filePath) async {
    // Load the CSV file from assets
    final String csvData = await rootBundle.loadString(filePath);

    // Parse the CSV
    List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);

    print(rows);

  // Convert to NxM list using slices extension
    int slices = 18;
    final list2d = rows[0].slices(slices).toList();
    print(list2d);


    // Initialize arrays
    List<int> timestamps = [];
    List<String> feet = [];
    List<List<int>> values = [];

    // Extract data from rows
    for (var row in list2d) {
      timestamps.add(row[0] as int); 
      feet.add(row[1] as String); 
      // The remaining columns (from index 2 onward) are the values

      List<int> valueRow = [];
      for (int i = 2; i < row.length; i++) {
        // Try to parse the string to an integer
        int? value = int.tryParse(row[i].toString()); 
        
        // If the value is successfully parsed, add it to the list
        if (value != null) {
          valueRow.add(value);
        } else {
          // Handle invalid integer (e.g., if you want to add a default value, or handle the error)
          valueRow.add(0); // Example: Add a default value of 0 for non-integer values
        }
        values.add(valueRow); // Add the value row to the values list
      } 
    }
    List<List<int>> valuesTransposed = transpose(values).toList();

    // Substract the min value to the timestamps
    int minValue = timestamps.reduce(min);
    timestamps = timestamps.map((number) => number - minValue).toList();

    // Return a record containing the extracted data
    return (timestamps: timestamps, feet: feet, values: valuesTransposed);
  }


  void plotAnalysis(String path) async {
    // Use the function to parse the file and get the data
    ({List<int> timestamps, List<String> feet, List<List<int>> values}) data = await parseCsvFile(path);

    // Access the fields
    print("Values: ${data.values}");
    print("Timestamps : ");print(data.timestamps);
    print("Feet : "); print(data.feet);
  }
