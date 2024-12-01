import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dart:convert'; // For utf8
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

  // put some states change there
  void toggleCurrentPlot(int value) {
    currentPlot = value;
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
        page = Placeholder();
      case 2: 
        page = Placeholder();
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
                    icon: Icon(Icons.favorite),
                    label: Text('Page 3'),
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
                appState.currentPlot = value.toInt();
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

/* class Page2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.favorites.length} favorites:'),
        ),
        for (var pair in appState.favorites)
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text(pair.asLowerCase),
          ),
      ],
    );
  }
} */








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

  // Convert to NxM list using slices extension
    int slices = 19;
    final list2d = rows[0].slices(slices).toList();


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
