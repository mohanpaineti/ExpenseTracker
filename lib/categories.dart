import 'package:expenses_tracker/category_expenses.dart';
import 'package:expenses_tracker/utils.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'db.dart';
import 'loading.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final Database db = DBProvider.instance.database;

  final GlobalKey<FormFieldState> fieldKey = GlobalKey();

  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    updateCategories();
  }

  Future<void> updateCategories() async {
    List<Map<String, dynamic>> result =
        await db.rawQuery(SQLStatements.getCategoriesOrdered);
    setState(() => categories = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
      ),
      body: RefreshIndicator(
        onRefresh: updateCategories,
        child: categories.isEmpty
            ? const Center(child: Text('No Categories Found.'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> entry = categories[index];
                  return Dismissible(
                      key: Key(entry['id'].toString()),
                      confirmDismiss: (direction) async {
                        return await confirmationDialog(context,
                            title: 'Remove Category',
                            content:
                                'Are you sure you want to remove "${entry['name']}" category? \nNote: Corresponding expense records will be moved to "General" category.',
                            yesColor: Colors.red);
                      },
                      onDismissed: (direction) async {
                        LoadingDialog.show(context);
                        await db.rawUpdate(SQLStatements.updateExpensesCategory, [entry['id']]);
                        await db.rawDelete(
                            SQLStatements.deleteCategory, [entry['id']]);
                        await updateCategories();
                        if (!mounted) return;
                        LoadingDialog.hide(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Category removed!')));
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
                      direction: entry['id'] == 0
                          ? DismissDirection.none
                          : DismissDirection.endToStart,
                      child: InkWell(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CategoryExpensesScreen(
                                    category: entry['name'],
                                    categoryId: entry['id']))),
                        child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 2),
                            title: Text(entry['name'])),
                      ));
                }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (dContext) => AlertDialog(
                    title: const Text('Add Category'),
                    content: TextFormField(
                      key: fieldKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (String? value) {
                        if (value == null || value.trim() == '') {
                          return 'Cannot be empty!';
                        }
                        value = value.trim().toLowerCase();
                        for (Map<String, dynamic> e in categories) {
                          if (value == e['name'].toLowerCase()) {
                            return 'Category already exists!';
                          }
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        label: Text('Name'),
                        prefixIcon: Icon(Icons.category),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dContext, false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 5),
                      TextButton(
                        style: TextButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 14)),
                        onPressed: () async {
                          FormFieldState? state = fieldKey.currentState;
                          if (state == null || !state.validate()) {
                            return;
                          }
                          LoadingDialog.show(dContext);
                          await db.rawInsert(
                              SQLStatements.insertCategory, [state.value]);
                          await updateCategories();
                          if (!mounted) return;
                          LoadingDialog.hide(dContext);
                          Navigator.pop(dContext, true);
                        },
                        child: const Text(
                          'OK',
                          style: TextStyle(color: Color(0xFFFFFFFF)),
                        ),
                      ),
                      const SizedBox(width: 2),
                    ],
                  ));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
