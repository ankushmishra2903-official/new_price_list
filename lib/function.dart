import 'dart:io';

import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'constance.dart';
import 'database_helper.dart';
import 'package:path/path.dart';

class Loading {
  static loading(String text) => EasyLoading.show(
        status: text,
        maskType: EasyLoadingMaskType.black,
      );

  static success(String text) => EasyLoading.showSuccess(
        text,
        maskType: EasyLoadingMaskType.black,
      );

  static error(String text) => EasyLoading.showError(
        text,
        maskType: EasyLoadingMaskType.black,
      );

  static dismiss() => EasyLoading.dismiss();
}

Directory rootPath = Directory('/storage/emulated/0/');

_getPermission() async {
  var status = await Permission.storage.status;
  print(status);
  if (!status.isGranted) {
    var newly = await Permission.storage.request();
    return newly;
  } else
    return status;
}

selectDir(context) async {
  final SharedPreferences pref = await SharedPreferences.getInstance();

  String? path = await FilesystemPicker.open(
    title: 'Save to folder',
    context: context,
    rootDirectory: rootPath,
    fsType: FilesystemType.folder,
    pickText: 'Save file to this folder',
    folderIconColor: Colors.teal,
    requestPermission: () async => await Permission.storage.request().isGranted,
  );

  pref.setString('dir', path!);

  return path;
}

createPdf(context, list) async {
  Loading.loading("Loading...");
  final SharedPreferences pref = await SharedPreferences.getInstance();
  await _getPermission();
  final doc = pw.Document();
  Loading.dismiss();
  var targetPath = pref.getString('dir') ?? await selectDir(context);
  Loading.loading("Loading...");
  var catList = await DatabaseHelper.instance.selectAll(categoryTbl);
  
  String _catName(val) {
    String name = '';
    for(var cat in catList) {
      if(cat['id'] == val) {
        name = cat['name'];
      }
    }
    return name;
  }

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.portrait,
      build: (pw.Context context) {
        return pw.Table(
            border: pw.TableBorder.all(),
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              pw.TableRow(children: [
                pw.Padding(
                  padding: pw.EdgeInsets.symmetric(horizontal: 10),
                  child: pw.Text('Product Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: pw.EdgeInsets.symmetric(horizontal: 10),
                  child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: pw.EdgeInsets.symmetric(horizontal: 10),
                  child: pw.Text('S/Wt', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: pw.EdgeInsets.symmetric(horizontal: 10),
                  child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: pw.EdgeInsets.symmetric(horizontal: 10),
                  child: pw.Text('CP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: pw.EdgeInsets.symmetric(horizontal: 10),
                  child: pw.Text('SP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ]),
              for(var pro in list) ...[
                pw.TableRow(children: [
                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(horizontal: 10),
                    child: pw.Text(pro['name']),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(horizontal: 10),
                    child: pw.Text(_catName(pro['category_id'])),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(horizontal: 10),
                    child: pw.Text(pro['size']),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(horizontal: 10),
                    child: pw.Text(pro['qty']),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(horizontal: 10),
                    child: pw.Text(pro['cp']),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(horizontal: 10),
                    child: pw.Text(pro['sp']),
                  ),
                ]),
              ]
            ]);
      },
    ),
  );
  try {
    var date = DateTime.now();
    final file = File(
        "$targetPath/price_list${date.year}${date.month}${date.day}${date.hour}${date.minute}${date.second}.pdf");
    await file.writeAsBytes(await doc.save());
    Loading.dismiss();
    Loading.success("Successfully saved pdf");
    return file;
  } on Exception catch (_) {
    pref.remove('dir');
    Loading.dismiss();
    Loading.error("Not able to save please try again with another location like Download");
    return null;
  }
}

backUp(context) async {

  final SharedPreferences pref = await SharedPreferences.getInstance();
  var targetPath = pref.getString('dir') ?? await selectDir(context);

  print(targetPath);
  await _getPermission();

  Loading.loading("Loading...");

  var dbName = DatabaseHelper.dbName;
  Directory directory = await getApplicationDocumentsDirectory();
  String path = join(directory.path, dbName);

  Directory dbPath = Directory('$targetPath/Database');


  if(!await dbPath.exists()) {
    print('not exit creating');
    dbPath=await dbPath.create(recursive: true);
    print('done');
  }

  var dbFile = File(path);

  print(dbFile);
  print(await dbFile.exists());
  print(File("${dbPath.path}/$dbName"));

  var save = await dbFile.copy("${dbPath.path}/$dbName");

  Loading.dismiss();
  Loading.success("Successfully backup on ${save.path}");
}

restore(context) async {
  await _getPermission();
  Directory directory = await getApplicationDocumentsDirectory();
  String path = join(directory.path, DatabaseHelper.dbName.toString());

  var targetPath = await FilesystemPicker.open(
    context: context,
    rootDirectory: rootPath,
    fsType: FilesystemType.file,
    permissionText: 'make permissions',
    title: 'Select Database',
    fileTileSelectMode: FileTileSelectMode.wholeTile,
    folderIconColor: Colors.teal,
    requestPermission: () async => await Permission.storage.request().isGranted,
  );

  if(targetPath != null) {
    await File(targetPath).copy(path);
    await openDatabase(path);
    Loading.success("Successfully restored. ");
    Phoenix.rebirth(context);

  }


}