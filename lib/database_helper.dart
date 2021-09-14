import 'dart:io';

import 'package:new_price_list/constance.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final dbName = 'price_list.db';
  static final dbVersion = 1;

  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) return _database;

    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path, dbName);
    return await openDatabase(
      path,
      version: dbVersion,
      onOpen: (db) {},
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE category_tbl (
          id INTEGER PRIMARY KEY,
          name TEXT,
          created_date NUMERIC )
        ''');
        await db.execute('''
          CREATE TABLE product_tbl (
          id INTEGER PRIMARY KEY,
          category_id INTEGER,
          name TEXT,
          size TEXT,
          qty TEXT,
          cp TEXT,
          sp TEXT,
          img TEXT,
          created_date NUMERIC )
        ''');

        await db.insert(
          categoryTbl, {Category.id : '0', Category.name : 'Uncategorized'}
        );
        },
    );
  }


  //Inserting into tables
  Future<int> insert(String table, Map<String, dynamic> row) async {
    Database? db = await instance.database;
    return await db!.insert(table, row);
  }

  // queries for tables
  Future<List<Map<String, dynamic>>> selectAll(String table) async {
    Database? db = await instance.database;
    return await db!.query(table);
  }

  //Updating table
  Future<int> update(String table, Map<String, dynamic> row) async {
    Database? db = await instance.database;
    int id = row['id'];
    return await db!.update(table, row, where: 'id = ?', whereArgs: [id]);
  }

  //Delete table
  Future<int> deleteProAll(catId) async {
    Database? db = await instance.database;
    return await db!.delete(productTbl, where: '${Product.category} = ?', whereArgs: [catId]);
  }
  deleteCatAll() async {
    Database? db = await instance.database;
    await db!.delete(categoryTbl, where: '${Category.id} != ?', whereArgs: [0]);
    await db.delete(productTbl);
  }

  deleteCat(catId) async {
    Database? db = await instance.database;
    await db!.delete(categoryTbl, where: '${Category.id} = ?', whereArgs: [catId]);
    await db.delete(productTbl, where: '${Product.category} = ?', whereArgs: [catId]);
  }

  deletePro(proId) async {
    Database? db = await instance.database;
    await db!.delete(productTbl, where: '${Product.id} = ?', whereArgs: [proId]);
  }

}
