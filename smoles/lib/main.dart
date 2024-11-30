import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dart:convert'; // For utf8
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart'; // For CSV parsing
import 'package:collection/collection.dart';

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
        title: 'Namer App',
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
  var current = WordPair.random();

    // ↓ Add this.
  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

    // ↓ Add the code below.
  var favorites = <WordPair>[];

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
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

    int numCols = 19;

  // Convert to NxM list using slices extension
    final list2d = rows[0].slices(numCols);
    print(list2d);

    print(list2d.length);
    //print(list2d[0].length);

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

    // Notify listeners (if necessary)
    notifyListeners();

    // Return a record containing the extracted data
    return (timestamps: timestamps, feet: feet, values: values);
  }


  void plotAnalysis(String path) async {
    // Use the function to parse the file and get the data
    ({List<int> timestamps, List<String> feet, List<List<int>> values}) data = await parseCsvFile(path);

    // Access the fields
    //print("Timestamps : ");print(data.timestamps);
    //print("Length of timestamps: ${data.timestamps.length}");
    //print("Feet : "); print(data.feet);
    //print("Values: ${data.values}");
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
        page = Page2();
      case 2: 
        page = Placeholder();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
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
                    icon: Icon(Icons.home),
                    label: Text('Page 1'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite),
                    label: Text('Page 2'),
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



class Analysis extends StatelessWidget {



  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair),
          SizedBox(height: 10),
          ElevatedButton(
                onPressed: () {
                  appState.plotAnalysis("data/240704_1214_standing_old-board.csv");
                },
                child: Text('Analyse'),
              ),
        ],
      ),
    );
  }
}

class Page2 extends StatelessWidget {
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
