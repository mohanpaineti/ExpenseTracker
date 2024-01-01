import 'package:expenses_tracker/utils.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'db.dart';
import 'loading.dart';

class CategoryExpensesScreen extends StatefulWidget {
  final String category;
  final int categoryId;

  const CategoryExpensesScreen(
      {Key? key, required this.category, required this.categoryId})
      : super(key: key);

  @override
  State<CategoryExpensesScreen> createState() => _CategoryExpensesScreenState();
}

class _CategoryExpensesScreenState extends State<CategoryExpensesScreen> {
  final Database db = DBProvider.instance.database;

  List<Map<String, dynamic>>? data;

  @override
  void initState() {
    super.initState();
    updateData();
  }

  Future<void> updateData() async {
    List<Map<String, dynamic>> list = await db
        .rawQuery(SQLStatements.getCategoryWiseExpenses, [widget.categoryId]);
    setState(() => data = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category} Expenses'),
      ),
      body: RefreshIndicator(
          onRefresh: updateData,
          child: data == null
              ? const Center(
                  child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ))
              : (data!.isEmpty
                  ? const Center(
                      child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('No Records Found.'),
                    ))
                  : ListView.builder(
                      itemCount: data!.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> datum = data![index];
                        DateTime? dateTime =
                            DateTime.tryParse(datum['timestamp']);
                        return Dismissible(
                          key: Key(datum.hashCode.toString()),
                          onDismissed: (direction) async {
                            LoadingDialog.show(context);
                            await updateData();
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
                            title: Text(
                              '₹ ${datum['amount'] ?? "N/A"}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 16),
                            ),
                            subtitle: Text(dateTime == null
                                ? 'N/A'
                                : formattedDateTime(dateTime)),
                          ),
                        );
                      }))),
    );
  }
}
