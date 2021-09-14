import 'dart:io';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'constance.dart';
import 'database_helper.dart';

enum formType { cat, pro }

class Forms extends StatefulWidget {
  final formType type;
  final row;

  const Forms({Key? key, required this.type, this.row}) : super(key: key);

  @override
  _FormsState createState() => _FormsState();
}

class _FormsState extends State<Forms> {
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  var catName;
  var proName, proCat, proSize, proCp, proSp, proQty, proImg;
  var cat;

  TextEditingController catNameController = TextEditingController();

  TextEditingController proNameController = TextEditingController(),
      proSizeController = TextEditingController(),
      proCpController = TextEditingController(),
      proSpController = TextEditingController(),
      proQtyController = TextEditingController();

  List<String> catList = [];
  List categoryList = [];

  @override
  void initState() {
    super.initState();
    if (widget.row != null) {
      if (widget.type == formType.cat) {
        catNameController.text = widget.row['name'];
      } else if (widget.type == formType.pro) {
        proCat = widget.row['category_id'];
        proImg = widget.row['img'] == '' ? null : widget.row['img'];
        proNameController.text = widget.row['name'] ?? '';
        proSizeController.text = widget.row['size'] ?? '';
        proQtyController.text = widget.row['qty'] ?? '';
        proCpController.text = widget.row['cp'] ?? '';
        proSpController.text = widget.row['sp'] ?? '';
      }
    }
    setState(() {});
    if (widget.type == formType.pro) {
      getData();
    }
  }

  getData() async {
    catList = [];
    categoryList = [];
    var row = await DatabaseHelper.instance.selectAll(categoryTbl);
    for (var cat in row) {
      catList.add(cat['name'].toString());
      categoryList.add(cat);
    }
    catList.sort((a, b) {
      if(a == 'Uncategorized') {
        return 0;
      } else {
        return a.compareTo(b);
      }
    });

    if (widget.row != null) {
      for (var category in categoryList) {
        if (category['id'] == proCat) {
          cat = category['name'];
        }
      }
    }
    setState(() {});
  }

  pickImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();

    var dirPath = await getApplicationSupportDirectory();


    var image = await _picker.pickImage(
      source: source,
      imageQuality: 50,
    );
    if (image != null) {
      var path = "${dirPath.path}/${image.name}";
      await image.saveTo(path);
      proImg = path;
      setState(() {});
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Add ' + (widget.type == formType.cat ? 'Category' : 'Product')),
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Center(
          child: Form(
            key: _key,
            child: ListView(
              shrinkWrap: true,
              children: [
                if (widget.type == formType.cat) ...[
                  TextFormField(
                    onSaved: (newValue) => catName = newValue,
                    textInputAction: TextInputAction.done,
                    controller: catNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Category Name',
                      hintText: 'Enter Category Name',
                    ),
                  )
                ] else ...[
                  Center(
                    child: InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          builder: (context) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  onTap: () async {
                                    await pickImage(ImageSource.gallery);
                                  },
                                  title: Text('From Gallery'),
                                  leading: Icon(Icons.photo_album_sharp),
                                ),
                                ListTile(
                                  onTap: () async {
                                    await pickImage(ImageSource.camera);
                                  },
                                  title: Text('From Camera'),
                                  leading: Icon(Icons.camera_alt),
                                ),
                                if(proImg != null) ...[
                                  ListTile(
                                    onTap: () async {
                                      proImg = null;
                                      setState(() {});
                                      Navigator.pop(context);
                                    },
                                    title: Text('Remove image'),
                                    leading: Icon(Icons.delete),
                                  ),
                                ]
                              ],
                            );
                          },
                        );
                      },
                      child: Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(20)),
                        clipBehavior: Clip.antiAlias,
                        child: proImg == null ? Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 60,
                        ) : Image.file(File(proImg.toString()), fit: BoxFit.fill,),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  DropdownSearch<String>(
                    mode: Mode.BOTTOM_SHEET,
                    showSelectedItem: true,
                    items: catList,
                    label: "Select Category",
                    hint: "Select Category",
                    selectedItem: cat,
                    searchBoxDecoration: InputDecoration(
                      hintText: 'Search...',
                      border: OutlineInputBorder(),
                    ),
                    showSearchBox: true,
                    validator: (value) {
                      if (value == null) {
                        return 'Select any category';
                      }
                    },
                    onChanged: (value) {
                      for (var cat in categoryList) {
                        if (cat['name'] == value) {
                          proCat = cat['id'];
                        }
                      }
                    },
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    onSaved: (newValue) => proName = newValue,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    controller: proNameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Product Name',
                      hintText: 'Enter Product Name',
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    onSaved: (newValue) => proSize = newValue,
                    textInputAction: TextInputAction.next,
                    controller: proSizeController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Size/Weight',
                      hintText: 'Enter Size/Weight',
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    onSaved: (newValue) => proQty = newValue,
                    textInputAction: TextInputAction.next,
                    controller: proQtyController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Quantity',
                      hintText: 'Enter Quantity',
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    onSaved: (newValue) => proCp = newValue,
                    textInputAction: TextInputAction.next,
                    controller: proCpController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Cost Price',
                      hintText: 'Enter Cost Price',
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    onSaved: (newValue) => proSp = newValue,
                    textInputAction: TextInputAction.next,
                    controller: proSpController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Sale Price',
                      hintText: 'Enter Sale Price',
                    ),
                  ),
                ],
                SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  onPressed: () async {
                    var date =
                        "${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}";
                    var form = _key.currentState;
                    if (form!.validate()) {
                      form.save();
                      Map<String, dynamic> data = {};
                      var table;
                      if (widget.type == formType.cat) {
                        table = categoryTbl;
                        data = {
                          Category.name: catName,
                          Category.createdDate: date,
                        };
                      } else {
                        table = productTbl;
                        data = {
                          Product.name: proName ?? '',
                          Product.category: proCat ?? 0,
                          Product.cp: proCp ?? '',
                          Product.sp: proSp ?? '',
                          Product.size: proSize ?? '',
                          Product.qty: proQty ?? '',
                          Product.img: proImg ?? '',
                          Product.createdDate: date,
                        };
                        print(data);
                      }
                      if (widget.row != null) {
                        if (widget.type == formType.cat) {
                          data = {
                            Category.id: widget.row['id'],
                            Category.name: catName,
                            Category.createdDate: widget.row['created_date'],
                          };
                        } else {
                          data = {
                            Product.id: widget.row['id'],
                            Product.name: proName ?? '',
                            Product.category: proCat ?? 0,
                            Product.cp: proCp ?? '',
                            Product.sp: proSp ?? '',
                            Product.size: proSize ?? '',
                            Product.qty: proQty ?? '',
                            Product.img: proImg ?? '',
                            Product.createdDate: widget.row['created_date'],
                          };
                        }
                      }
                      var row = widget.row == null
                          ? await DatabaseHelper.instance.insert(table, data)
                          : await DatabaseHelper.instance.update(table, data);
                      if (row != 0) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: Text(widget.row == null ? 'Submit' : 'Update'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
