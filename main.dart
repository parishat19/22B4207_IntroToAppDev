import 'package:flutter/material.dart';

void main() => runApp(BudgetTrackerApp());

class BudgetTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget Tracker',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Category> categories = [];
  double totalExpenses = 0.0;
  bool showDropdown = false;
  Category? selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Budget Tracker')),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Hello!',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.normal),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                showDropdown = !showDropdown;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Expense Total: \$${totalExpenses.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (showDropdown)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButton<Category>(
                isExpanded: true,
                value: selectedCategory,
                onChanged: (Category? newValue) {
                  setState(() {
                    selectedCategory = newValue;
                    showDropdown = false;
                    if (newValue != null) {
                      _navigateToExpensePage(newValue);
                    }
                  });
                },
                items: categories
                    .map<DropdownMenuItem<Category>>((Category category) {
                  return DropdownMenuItem<Category>(
                    value: category,
                    child: Text(category.name),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCategoryDialog(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _navigateToExpensePage(Category category) async {
    final updatedCategory = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpensePage(
            category: category, onExpenseAdded: _updateCategoryTotal),
      ),
    );
    if (updatedCategory != null) {
      setState(() {
        final index = categories
            .indexWhere((element) => element.name == updatedCategory.name);
        if (index != -1) {
          categories[index] = updatedCategory;
        }
      });
      _updateExpenseTotal();
    }
  }

  void _updateExpenseTotal() {
    double total = 0.0;
    for (final category in categories) {
      total += category.totalExpenses;
    }
    setState(() {
      totalExpenses = total;
    });
  }

  void _updateCategoryTotal(Category category) {
    double total = 0.0;
    for (final expense in category.expenses) {
      total += expense.amount;
    }
    setState(() {
      category.totalExpenses = total;
    });
    _updateExpenseTotal();
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddCategoryDialog(
          onCategoryAdded: (Category category) {
            setState(() {
              categories.add(category);
            });
          },
        );
      },
    );
  }

  void _showDeleteCategoryConfirmationDialog(
      BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Category'),
          content: Text('Are you sure you want to delete this category?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  totalExpenses -= category.totalExpenses;
                  categories.remove(category);
                });
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class ExpensePage extends StatefulWidget {
  final Category category;
  final Function(Category) onExpenseAdded;

  const ExpensePage(
      {Key? key, required this.category, required this.onExpenseAdded})
      : super(key: key);

  @override
  _ExpensePageState createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expenses for ${widget.category.name}'),
      ),
      body: ListView.builder(
        itemCount: widget.category.expenses.length,
        itemBuilder: (context, index) {
          final expense = widget.category.expenses[index];
          return ListTile(
            title: Text('Amount: \$${expense.amount.toStringAsFixed(2)}'),
            subtitle: Text('Description: ${expense.description}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddExpenseDialog(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddExpenseDialog(
          onExpenseAdded: (Expense expense) {
            setState(() {
              widget.category.expenses.add(expense);
            });
            widget.onExpenseAdded(widget.category);
          },
        );
      },
    );
  }
}

class Category {
  String name;
  double totalExpenses;
  List<Expense> expenses;

  Category({required this.name, required this.expenses}) : totalExpenses = 0.0;
}

class Expense {
  final double amount;
  final String description;

  Expense({required this.amount, required this.description});
}

class AddCategoryDialog extends StatefulWidget {
  final void Function(Category) onCategoryAdded;

  const AddCategoryDialog({Key? key, required this.onCategoryAdded})
      : super(key: key);

  @override
  _AddCategoryDialogState createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Category'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Category Name'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = nameController.text;

            if (name.isNotEmpty) {
              final category = Category(name: name, expenses: []);
              widget.onCategoryAdded(category);
            }

            Navigator.of(context).pop();
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}

class AddExpenseDialog extends StatefulWidget {
  final void Function(Expense) onExpenseAdded;

  const AddExpenseDialog({Key? key, required this.onExpenseAdded})
      : super(key: key);

  @override
  _AddExpenseDialogState createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  TextEditingController amountController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Expense'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final amount = double.tryParse(amountController.text) ?? 0.0;
            final description = descriptionController.text;

            if (amount > 0 && description.isNotEmpty) {
              final expense = Expense(amount: amount, description: description);
              widget.onExpenseAdded(expense);
            }

            Navigator.of(context).pop();
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
