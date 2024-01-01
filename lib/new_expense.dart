import 'package:expenses_tracker/db.dart';
import 'package:expenses_tracker/loading.dart';
import 'package:expenses_tracker/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

class NewExpenseScreen extends StatefulWidget {
  const NewExpenseScreen({Key? key}) : super(key: key);

  @override
  State<NewExpenseScreen> createState() => _NewExpenseScreenState();
}

class _NewExpenseScreenState extends State<NewExpenseScreen> {
  final Database db = DBProvider.instance.database;

  List<Map<String, dynamic>> categories = [];
  int? selectedCategory;
  double amount = 0;
  DateTime timestamp = DateTime.now();
  final GlobalKey<FormState> formKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    setCategories();
  }

  Future<void> setCategories() async {
    Database db = DBProvider.instance.database;
    List<Map<String, dynamic>> list =
        await db.rawQuery(SQLStatements.getCategoriesOrdered);
    setState(() {
      categories = list;
      selectedCategory = list[0]['id'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 28),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
                onChanged: (String? value) =>
                    setState(() => amount = double.tryParse(value ?? '0') ?? 0),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (String? value) {
                  if (value == null) {
                    return 'Field cannot be empty.';
                  }
                  double? v = double.tryParse(value);
                  if (v == null || v <= 0) {
                    return 'Expense has to be valid.';
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    label: Text(
                      'Amount',
                      style: TextStyle(fontSize: 16),
                    ),
                    prefixIcon: Icon(Icons.currency_rupee)),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                      labelText: 'Category', prefixIcon: Icon(Icons.category)),
                  value: selectedCategory,
                  items: categories
                      .map((e) => DropdownMenuItem<int>(
                            value: e['id'],
                            child: Text(e['name']),
                          ))
                      .toList(),
                  onChanged: (c) => setState(() => selectedCategory = c)),
              const SizedBox(height: 24),
              TextField(
                controller:
                    TextEditingController(text: formattedDateTime(timestamp)),
                readOnly: true,
                decoration: const InputDecoration(
                    labelText: 'Timestamp', prefixIcon: Icon(Icons.date_range)),
                onTap: () async {
                  DateTime now = DateTime.now();
                  DateTime? date = await showDatePicker(
                      context: context,
                      initialDate: now,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100));
                  if (date == null) return;
                  TimeOfDay? time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(now));
                  if (time == null) return;
                  DateTime dateTime = DateTime(
                      date.year, date.month, date.day, time.hour, time.minute);

                  setState(() {
                    timestamp = dateTime;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (formKey.currentState?.validate() ?? false) {
            LoadingDialog.show(context);
            await db.rawInsert(SQLStatements.insertExpense,
                [amount, selectedCategory, timestamp.toIso8601String()]);
            if (!mounted) return;
            LoadingDialog.hide(context);
            Navigator.pop(context, true);
          }
        },
        tooltip: 'Submit',
        child: const Icon(Icons.check_sharp),
      ),
    );
  }
}
