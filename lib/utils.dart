class SQLStatements {
  static const String createCategoryTable = """
    CREATE TABLE Category (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT
    )
    """,
      insertDefaultCategories = """
      INSERT INTO Category(id, name) 
      VALUES (0, 'General'), (1, 'Food'), (2, 'Health'), (3, 'Education'), (4, 'Entertainment')
  """,
      createExpenseTable = """     
    CREATE TABLE Expense (
      sid INTEGER PRIMARY KEY AUTOINCREMENT,
      amount REAL,
      category INTEGER DEFAULT 0 REFERENCES Category(id) ON DELETE NO ACTION,
      timestamp TEXT
    )
    """,
      getCategories = "SELECT id, name FROM Category",
      getCategoriesOrdered = "SELECT id, name FROM Category ORDER BY name",
      insertExpense =
          "INSERT INTO Expense(amount, category, timestamp) VALUES (?, ?, ?)",
      deleteExpense = "DELETE FROM Expense WHERE sid=?",
      getCategoryWiseExpenses = """
  SELECT sid, amount, timestamp 
  FROM Expense WHERE category=? 
  ORDER BY datetime(timestamp) DESC
  """,
      getFilteredExpenses = """
    SELECT * 
    FROM
      Expense e
        JOIN
      Category c
        ON e.category=c.id
    WHERE datetime(timestamp) BETWEEN datetime(?) AND datetime(?)
    ORDER BY datetime(timestamp) DESC
    """,
      getFilteredExpensesGrouped = """
    SELECT SUM(amount) as total, name
    FROM 
      Expense e 
        JOIN 
      Category c
        ON e.category=c.id
    WHERE datetime(timestamp) BETWEEN datetime(?) AND datetime(?)
    GROUP BY category
    """,
      truncateExpenses = "DELETE FROM Expense",
      truncateCategories = "DELETE FROM Category",
      insertCategory = "INSERT INTO Category(name) VALUES (?)",
      deleteCategory = "DELETE FROM Category WHERE id=?",
      updateExpensesCategory = "UPDATE Expense SET category=0 WHERE category=?";
}

String formattedDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String formattedDateTime(DateTime dateTime) =>
    '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, "0")} ${dateTime.day}/${dateTime.month}/${dateTime.year}';
