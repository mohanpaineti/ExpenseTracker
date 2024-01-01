import 'package:expenses_tracker/categories.dart';
import 'package:expenses_tracker/db.dart';
import 'package:expenses_tracker/loading.dart';
import 'package:expenses_tracker/new_expense.dart';
import 'package:expenses_tracker/utils.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBProvider.initialise();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
          // useMaterial3: true,
          primarySwatch: Colors.green,
          inputDecorationTheme:
              const InputDecorationTheme(border: OutlineInputBorder())),
      home: const MyHomePage(title: 'Expense Tracker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Database db = DBProvider.instance.database;

  int mode = 0;
  Map<String, double>? stats;
  List<Map<String, dynamic>> data = [];
  Map<int, String> categories = {};
  bool showStatsInPercent = false;
  DateTimeRange? dateRange;
  TextEditingController rangeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    updateStats();
  }

  Future<void> updateStats() async {
    setTimeRange();
    List<String> args = [
      dateRange!.start.toIso8601String(),
      dateRange!.end.toIso8601String()
    ];
    List<Map<String, dynamic>> result =
        await db.rawQuery(SQLStatements.getFilteredExpenses, args);
    List<Map<String, dynamic>> results2 =
        await db.rawQuery(SQLStatements.getFilteredExpensesGrouped, args);
    Map<String, double> stats = {};
    for (Map<String, dynamic> entry in results2) {
      stats[entry['name']] = entry['total'];
    }
    List<Map<String, dynamic>> results3 =
        await db.rawQuery(SQLStatements.getCategories);
    Map<int, String> categories = {};
    for (Map<String, dynamic> entry in results3) {
      categories[entry['id']] = entry['name'];
    }
    setState(() {
      this.stats = stats;
      this.categories = categories;
      data = result;
    });
  }

  setTimeRange() {
    DateTime todayDate = DateTime.now();
    DateTime edge = DateTime(todayDate.year, todayDate.month, todayDate.day);
    DateTime endEdge =
        DateTime(todayDate.year, todayDate.month, todayDate.day, 23, 59, 59);
    DateTimeRange? range;
    switch (mode) {
      case 0:
        range = DateTimeRange(start: edge, end: endEdge);
        break;
      case 1:
        range = DateTimeRange(
            start: edge.subtract(const Duration(days: 1)),
            end: edge.subtract(const Duration(seconds: 1)));
        break;
      case 2:
        range = DateTimeRange(
            start: edge.subtract(const Duration(days: 7)), end: endEdge);
        break;
      case 3:
        range = DateTimeRange(
            start: edge.subtract(const Duration(days: 30)), end: endEdge);
    }
    setState(() => dateRange = range??dateRange);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) async {
              switch (value) {
                case 'Manage Categories':
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const ManageCategoriesScreen()));
                  updateStats();
                  break;
                case 'Reset Data':
                  confirmationDialog(context,
                      title: 'Reset Data',
                      content:
                          'Are you sure you want to reset complete store data? This action cannot be undone.',
                      yesText: 'Yes, I\'m sure',
                      yesColor: Colors.red, onYes: () async {
                    LoadingDialog.show(context);
                    await db.execute(SQLStatements.truncateExpenses);
                    await db.execute(SQLStatements.truncateCategories);
                    await db.rawInsert(SQLStatements.insertDefaultCategories);
                    await updateStats();
                    if (!mounted) return;
                    LoadingDialog.hide(context);
                  });
              }
            },
            itemBuilder: (BuildContext context) {
              return ['Manage Categories', 'Reset Data'].map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: updateStats,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: <Widget>[
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                        value: mode,
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Today')),
                          DropdownMenuItem(value: 1, child: Text('Yesterday')),
                          DropdownMenuItem(value: 2, child: Text('7-days')),
                          DropdownMenuItem(value: 3, child: Text('30-days')),
                          DropdownMenuItem(value: 4, child: Text('Custom')),
                        ],
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.filter_alt),
                            labelText: 'Filter'),
                        onChanged: (int? value) {
                          value ??= 0;
                          setState(() => mode = value!);
                          if (value != 4) updateStats();
                        }),
                    const SizedBox(height: 24),
                    TextField(
                      readOnly: true,
                      controller: TextEditingController(text: (() {
                        if (dateRange == null) return '';
                        String sd = formattedDate(dateRange!.start),
                            ed = formattedDate(dateRange!.end);
                        if (sd == ed) return sd;
                        return '$sd - $ed';
                      })()),
                      decoration: const InputDecoration(
                          labelText: 'Range',
                          prefixIcon: Icon(Icons.date_range)),
                      onTap: () async {
                        DateTimeRange? range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (range == null) return;
                        setState(() => dateRange = DateTimeRange(
                            start: range.start,
                            end: range.end
                                .add(const Duration(days: 1))
                                .subtract(const Duration(seconds: 1))));
                        if (mode != 4) setState(() => mode = 4);
                        updateStats();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 12,
                thickness: 1,
              ),
              if (stats != null && stats!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(children: [
                    Center(
                      child: PieChart(
                        dataMap: stats!,
                        animationDuration: const Duration(milliseconds: 800),
                        chartLegendSpacing: 32,
                        // chartRadius: 12,
                        chartRadius: MediaQuery.of(context).size.width / 2,
                        initialAngleInDegree: 0,
                        chartType: ChartType.disc,
                        // centerText: "HYBRID",
                        legendOptions: const LegendOptions(
                          showLegendsInRow: false,
                          legendPosition: LegendPosition.right,
                          showLegends: true,
                          legendTextStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        chartValuesOptions: ChartValuesOptions(
                          showChartValuesInPercentage: showStatsInPercent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total'),
                            const SizedBox(height: 5),
                            Text(
                              '₹ ${stats!.values.toList().reduce((a, b) => a + b)}',
                              style: const TextStyle(fontSize: 28),
                            )
                          ],
                        ),
                        IconButton(
                            tooltip: showStatsInPercent
                                ? 'Show in value'
                                : 'Show in percent',
                            onPressed: () => setState(
                                () => showStatsInPercent = !showStatsInPercent),
                            icon: Icon(showStatsInPercent
                                ? Icons.numbers
                                : Icons.percent)),
                      ],
                    )
                  ]),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                ),
              ],
              data.isEmpty
                  ? const Center(
                      child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('No Records Found.'),
                    ))
                  : ListView.builder(
                      primary: false,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.length,
                      itemBuilder: (BuildContext context, int index) {
                        Map<String, dynamic> datum = data[index];
                        DateTime? dateTime =
                            DateTime.tryParse(datum['timestamp']);
                        return Dismissible(
                          key: Key(datum.hashCode.toString()),
                          onDismissed: (direction) async {
                            LoadingDialog.show(context);
                            Map<String, dynamic> datum = data[index];
                            await db.rawDelete(
                                SQLStatements.deleteExpense, [datum['sid']]);
                            // setState(()=>data.removeAt(index));
                            await updateStats();
                            if (!mounted) return;
                            LoadingDialog.hide(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Record removed!')));
                          },
                          background: Container(
                            color: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'REMOVE',
                                    style: TextStyle(
                                        color: Colors.red.shade50,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.delete,
                                    color: Colors.red.shade50,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          direction: DismissDirection.endToStart,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 2),
                            title: Text(categories[datum['category']] ?? 'N/A'),
                            subtitle: Text(dateTime == null
                                ? 'N/A'
                                : formattedDateTime(dateTime)),
                            trailing: Text(
                              '₹ ${datum['amount'] ?? "N/A"}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 16),
                            ),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 84),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var value = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const NewExpenseScreen()));
          if (value == true) {
            await updateStats();
          }
        },
        tooltip: 'Add Expense',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
