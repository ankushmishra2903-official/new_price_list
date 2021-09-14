import 'package:flutter/material.dart';
import 'package:new_price_list/function.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constance.dart';
import 'database_helper.dart';
import 'forms.dart';
import 'product_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> categoryList = [];

  bool _isSearch = false;
  String searchText = '';
  String location = '';

  @override
  void initState() {
    super.initState();
    getData();
  }

  getData() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    location = pref.getString('dir') ?? 'Click to select location';
    categoryList = [];
    List<Map<String, dynamic>> catList = [];
    var row = await DatabaseHelper.instance.selectAll(categoryTbl);
    for(var cat in row) {

      catList.add(cat);
    }
    catList.sort((a, b) {
      if(a['id'] == 0) {
        return 0;
      } else {
        return a['name'].toString().compareTo(b['name'].toString());
      }

    });
    categoryList = catList;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _isSearch
          ? null
          : Drawer(
              child: ListView(
                children: [
                  ListTile(
                    tileColor: Theme.of(context).primaryColor,
                    onTap: () async {
                      await selectDir(context);
                      getData();
                      Navigator.pop(context);
                    },
                    title: Text(
                      location,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Divider(
                    height: 0,
                    color: Colors.black,
                  ),
                  ListTile(
                    onTap: () {
                      Navigator.pop(context);
                      backUp(context);
                    },
                    leading: Icon(Icons.settings_backup_restore),
                    title: Text('Backup Data'),
                  ),
                  ListTile(
                    onTap: () async {
                      await restore(context);
                      setState(() {});
                      Navigator.pop(context);
                    },
                    leading: Icon(Icons.settings_backup_restore),
                    title: Text('Restore Data'),
                  ),
                ],
              ),
            ),
      appBar: AppBar(
        title: AnimatedContainer(
          duration: Duration(seconds: 1),
          child: _isSearch
              ? Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.white),
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: TextFormField(
                    autofocus: true,
                    initialValue: searchText,
                    onChanged: (value) {
                      setState(() {
                        searchText = value;
                      });
                    },
                    onFieldSubmitted: (value) {
                      setState(() {
                        _isSearch = false;
                      });
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search...',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () {},
                      ),
                    ),
                  ),
                )
              : Text('${searchText == '' ? 'Price List' : searchText}'),
        ),
        actions: [
          if (!_isSearch) ...[
            IconButton(
              onPressed: () {
                setState(() {
                  _isSearch = true;
                });
              },
              icon: Icon(Icons.search),
            ),
          ]
        ],
      ),
      body: ListView(
        shrinkWrap: true,
        children: [
          if (searchText == '') ...[
            ListTile(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductList(
                        name: 0,
                      ),
                    ));
              },
              title: Text('Show All'),
            ),
            Divider(
              height: 0,
              color: Colors.black,
            ),
            SizedBox(
              height: 20,
            ),
          ],
          for (var cat in categoryList) ...[
            if (searchText == '') ...[
              ListTile(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductList(
                          id: cat['id'],
                          name: cat['name'],
                        ),
                      ));
                },
                title: Text(cat['name']),
                trailing: cat['id'] == 0
                    ? null
                    : PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'Edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Forms(
                                  type: formType.cat,
                                  row: cat,
                                ),
                              ),
                            ).then((value) => getData());
                          } else if (value == 'Delete') {
                            await DatabaseHelper.instance
                                .deleteCat(cat['id'])
                                .then((value) => getData());
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return {'Edit', 'Delete'}.map((String choice) {
                            return PopupMenuItem<String>(
                              value: choice,
                              child: Row(
                                children: [
                                  if (choice == 'Edit') ...[
                                    Icon(Icons.edit),
                                  ] else ...[
                                    Icon(Icons.delete),
                                  ],
                                  SizedBox(
                                    width: 15,
                                  ),
                                  Text(choice),
                                ],
                              ),
                            );
                          }).toList();
                        },
                      ),
              ),
              Divider(
                height: 0,
                color: Colors.black,
              )
            ] else ...[
              if (cat['name']
                  .toLowerCase()
                  .contains(searchText.toLowerCase())) ...[
                ListTile(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductList(
                            id: cat['id'],
                            name: cat['name'],
                          ),
                        ));
                  },
                  title: Text(cat['name']),
                  trailing: cat['id'] == 0
                      ? null
                      : PopupMenuButton<String>(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext context) {
                            return {'Edit', 'Delete'}.map((String choice) {
                              return PopupMenuItem<String>(
                                value: choice,
                                child: Row(
                                  children: [
                                    if (choice == 'Edit') ...[
                                      Icon(Icons.edit),
                                    ] else ...[
                                      Icon(Icons.delete),
                                    ],
                                    SizedBox(
                                      width: 15,
                                    ),
                                    Text(choice),
                                  ],
                                ),
                              );
                            }).toList();
                          },
                        ),
                ),
                Divider(
                  height: 0,
                  color: Colors.black,
                )
              ]
            ],
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Forms(type: formType.cat),
            ),
          ).then((value) => getData());
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
