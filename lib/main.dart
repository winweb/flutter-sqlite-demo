import 'package:flutter/material.dart';
import 'package:flutter_sqlite_demo/models/todo-item.dart';
import 'package:flutter_sqlite_demo/services/db.dart';

void main() async {

	WidgetsFlutterBinding.ensureInitialized();

	await DB.init();
	runApp(MyApp());
}

class MyApp extends StatelessWidget {

	@override
	Widget build(BuildContext context) {

		return MaterialApp(
			title: 'Flutter Demo',
			theme: ThemeData(primarySwatch: Colors.indigo ),
			home: MyHomePage(title: 'Flutter SQLite Demo App'),
		);
	}
}

class MyHomePage extends StatefulWidget {

	MyHomePage({Key key, this.title}) : super(key: key);

	final String title;

	@override
	_MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
	
	String _task;

	List<TodoItem> _tasks = [];

	TextStyle _style = TextStyle(color: Colors.white, fontSize: 24);

	List<Widget> get _items => _tasks.map((item) => format(item)).toList();

	Widget format(TodoItem item) {

		return Dismissible(
			key: Key(item.id.toString()),
			child: Padding(
				padding: EdgeInsets.fromLTRB(12, 6, 12, 4),
				child: TextButton(
					child: Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: <Widget>[
							Text(item.task, style: _style),
							IconButton(
								icon: Icon(item.complete == true ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: Colors.white),
								tooltip: 'check',
								onPressed: () {
									_toggle(item);
								},
							),
						]
					),
					onPressed: () => _edit(context, item),
				)
			),
			onDismissed: (DismissDirection direction) => _delete(item),
		);
	}

	void _toggle(TodoItem item) async {

		item.complete = !item.complete;
		dynamic result = await DB.update(TodoItem.table, item);
		print(result);
		refresh();
	}

	void _delete(TodoItem item) async {
		
		DB.delete(TodoItem.table, item);
		refresh();
	}

	void _save() async {

		Navigator.of(context).pop();
		TodoItem item = TodoItem(
			task: _task,
			complete: false
		);

		await DB.insert(TodoItem.table, item);
		setState(() => _task = '' );
		refresh();
	}

	void _create(BuildContext context) {

		showDialog(
			context: context,
			builder: (BuildContext context) {
				return AlertDialog(
					title: Text("Create New Task"),
					actions: <Widget>[
						TextButton(
							child: Text('Cancel'),
							onPressed: () => Navigator.of(context).pop()
						),
						TextButton(
							child: Text('Save'),
							onPressed: () => _save()
						)						
					],
					content: TextField(
						autofocus: true,
						decoration: InputDecoration(labelText: 'Task Name', hintText: 'e.g. pick up bread'),
						onChanged: (value) { _task = value; },
					),
				);
			}
		);
	}

	void _update(TodoItem item) async {

		Navigator.of(context).pop();

		await DB.update(TodoItem.table, item);
		refresh();
	}

	void _edit(BuildContext context, TodoItem item) {

		showDialog(
				context: context,
				builder: (BuildContext context) {
					return AlertDialog(
						title: Text("Edit Task"),
						actions: <Widget>[
							TextButton(
									child: Text('Cancel'),
									onPressed: () => Navigator.of(context).pop()
							),
							TextButton(
									child: Text('Update'),
									onPressed: () => _update(item)
							)
						],
						content: TextField(
							autofocus: true,
							decoration: InputDecoration(labelText: 'Task Name', hintText: 'e.g. pick up bread'),
							onChanged: (value) { item.task = value; },
						),
					);
				}
		);
	}

	@override
	void initState() {

		refresh();
		super.initState();
	}

	void refresh() async {

		List<Map<String, dynamic>> _results = await DB.query(TodoItem.table);
		_tasks = _results.map((item) => TodoItem.fromMap(item)).toList();
		setState(() { });
	}

	@override
	Widget build(BuildContext context) {

		return Scaffold(
			backgroundColor: Colors.black,
			appBar: AppBar( title: Text(widget.title) ),
			body: Center(
				child: ListView( children: _items )
			),
			floatingActionButton: Column(
				mainAxisAlignment: MainAxisAlignment.end,
				children: [
					FloatingActionButton(
						onPressed: () { _create(context); },
						tooltip: 'New TODO',
						child: Icon(Icons.library_add),
						heroTag: null
					),
					SizedBox(
						height: 5,
					),
					FloatingActionButton(
						onPressed: () {
							Navigator.push(
								context,
								MaterialPageRoute(
									builder: (context) => SecondRoute(_tasks.where((map)=>map.complete == true).toList())
								),
							);
						},
						tooltip: 'Get TODO checked',
						child: Icon(Icons.library_books),
						heroTag: null
					)
				]
			)
		);
	}

	void _showDialog(BuildContext context) {
		showDialog(
			context: context,
			builder: (BuildContext context) {
				return AlertDialog(
					title: new Text("Alert!!"),
					content: new Text("You are awesome!"),
					actions: <Widget>[
						new TextButton(
							child: new Text("OK"),
							onPressed: () {
								Navigator.of(context).pop();
							},
						),
					],
				);
			},
		);
	}
}

class SecondRoute extends StatelessWidget {

	List<TodoItem> _results;

	SecondRoute(this._results);

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: Text("TODO Checked List"),
			),
			body:
				Column(
				mainAxisAlignment: MainAxisAlignment.spaceBetween,
				children: <Widget>[
					new Expanded (
						child: new ListView.builder(
							scrollDirection: Axis.vertical,
							shrinkWrap: true,
							itemCount: _results.length,
							itemBuilder: (BuildContext ctxt, int index) {
								return new Text(_results[index].task, style: TextStyle(color: Colors.red, fontSize: 24));
							}
						)
					),
					SizedBox(
						height: 30,
					),
					ElevatedButton(
						onPressed: () {
							Navigator.pop(context);
						},
						child: Text('Go back!'),
					)
				],
			)
		);
	}
}