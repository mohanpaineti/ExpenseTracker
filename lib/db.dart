import 'package:expenses_tracker/utils.dart';
import 'package:sqflite/sqflite.dart';

class DBProvider {
  static late final DBProvider _instance;

  static DBProvider get instance => _instance;

  static late final Database _database;

  Database get database => _database;

  static Future<void> initialise() async {
    _instance = DBProvider();
    _database = await openDatabase('expenses.db', version: 1, onOpen: (db) {},
        onCreate: (Database db, int version) async {
      await db.execute(SQLStatements.createCategoryTable);
      await db.rawInsert(SQLStatements.insertDefaultCategories);
      await db.execute(SQLStatements.createExpenseTable);
    });
  }
}
