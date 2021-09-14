import 'dart:io';

import 'package:flutter/material.dart';
import 'package:new_price_list/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_string_converter/flutter_string_converter.dart';

import 'constance.dart';
import 'database_helper.dart';
import 'forms.dart';
import 'function.dart';

class ProductList extends StatefulWidget {
  final id;
  final name;

  const ProductList({Key? key, this.id, required this.name}) : super(key: key);

  @override
  _ProductListState createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  List productList = [];
  List catList = [];

  bool _isSearch = false;
  String searchText = '';
  String title = '';

  @override
  void initState() {
    super.initState();
    title = widget.name == 0 ? 'All Product' : widget.name;
    getData();
  }

  getData() async {
    productList = [];
    var pro = await DatabaseHelper.instance.selectAll(productTbl);
    var cat = await DatabaseHelper.instance.selectAll(categoryTbl);
    if (widget.name == 0) {
      for (var proList in pro) {
        productList.add(proList);
      }
    } else {
      for (var proList in pro) {
        if (proList['category_id'] == widget.id) {
          productList.add(proList);
        }
      }
    }
    productList.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
    catList = cat;
    setState(() {});
  }

  String catName(val) {
    String name = '';
    for (var cat in catList) {
      if (cat['id'] == val) {
        name = cat['name'];
      }
    }
    return name;
  }

  dialogShow(pro) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pro['img'] != '') ...[
              Center(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImgView(
                            img: File(pro['img'].toString()), tag: pro['name']),
                      ),
                    );
                  },
                  child: Container(
                    height: 150,
                    width: 150,
                    clipBehavior: Clip.antiAlias,
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(20)),
                    child: Hero(
                      tag: pro['name'],
                      child: Image.file(
                        File(pro['img'].toString()),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Center(
                child: Container(
                    height: 100,
                    width: 100,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all()),
                    child: Icon(Icons.camera_enhance_rounded)),
              ),
            ],
            SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Expanded(child: Text('Name')),
                Expanded(child: Text(': ${pro['name']}')),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('Cost Price')),
                Expanded(child: Text(': $kRupee ${pro['cp']}')),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('Sale Price')),
                Expanded(child: Text(': $kRupee ${pro['sp']}')),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('Size/Weight')),
                Expanded(child: Text(': ${pro['size']}')),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('Qty')),
                Expanded(child: Text(': ${pro['qty']}')),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('Created Date')),
                Expanded(child: Text(': ${pro['created_date'].toString().toDate(format: FormatDate.dmy)}')),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('Created Time')),
                Expanded(child: Text(': ${pro['created_date'].toString().toDate(format: FormatDate.time12WithSec)}')),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
              onPressed: () {
                Share.share(
                    "Name: ${pro['name']}\nCost Price: $kRupee ${pro['cp']}\nSale Price: $kRupee ${pro['sp']}\nSize/Weight: ${pro['size']}\nQty: ${pro['qty']}\nCreated Date: ${pro['created_date'].toString().toDate(format: FormatDate.dmy)}\nCreated Time: ${pro['created_date'].toString().toDate(format: FormatDate.time12WithSec)}");
              },
              icon: Icon(Icons.share)),
          IconButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Forms(
                      type: formType.pro,
                      row: pro,
                    ),
                  ),
                ).then((value) => getData());
              },
              icon: Icon(Icons.edit)),
          IconButton(
              onPressed: () async {
                await DatabaseHelper.instance
                    .deletePro(pro['id'])
                    .then((value) {
                  Navigator.pop(context);
                  getData();
                });
              },
              icon: Icon(Icons.delete)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !_isSearch,
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
                      suffixIcon: Icon(Icons.search),
                    ),
                  ),
                )
              : Text('${searchText == '' ? title : searchText}'),
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
            IconButton(
              onPressed: () async {
                if (productList.length == 0) {
                  Loading.error('Product of this list is empty');
                } else {
                  File? pdf = await createPdf(context, productList);
                  if (pdf != null) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                pdf.path.split('/').last,
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              IconButton(
                                onPressed: () async {
                                  await Share.shareFiles(
                                    [pdf.path],
                                  );
                                },
                                icon: Icon(Icons.share),
                                iconSize: 18,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                }
              },
              icon: Icon(Icons.picture_as_pdf),
            ),
          ]
        ],
      ),
      body: productList.length == 0
          ? Center(
              child: Text(
                'No Product in "$title".\nAdd Product by click on "+" in bottom right ',
                textAlign: TextAlign.center,
              ),
            )
          : ListView(
              children: [
                for (var pro in productList) ...[
                  if (searchText == '') ...[
                    if (widget.name == 0) ...[
                      ListTile(
                        onTap: () {
                          dialogShow(pro);
                        },
                        title: Text(pro['name']),
                        subtitle:
                            Text("Category : ${catName(pro['category_id'])}"),
                      ),
                      Divider(
                        height: 0,
                        color: Colors.black,
                      )
                    ] else ...[
                      ListTile(
                        onTap: () {
                          dialogShow(pro);
                        },
                        title: Text(pro['name']),
                      ),
                      Divider(
                        height: 0,
                        color: Colors.black,
                      )
                    ]
                  ] else ...[
                    if (pro['name']
                        .toString()
                        .toLowerCase()
                        .contains(searchText.toLowerCase())) ...[
                      if (widget.name == 0) ...[
                        ListTile(
                          onTap: () {
                            dialogShow(pro);
                          },
                          title: Text(pro['name']),
                          subtitle:
                              Text("Category : ${catName(pro['category_id'])}"),
                        ),
                        Divider(
                          height: 0,
                          color: Colors.black,
                        )
                      ] else ...[
                        ListTile(
                          onTap: () {
                            dialogShow(pro);
                          },
                          title: Text(pro['name']),
                        ),
                        Divider(
                          height: 0,
                          color: Colors.black,
                        )
                      ]
                    ]
                  ]
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Forms(type: formType.pro),
            ),
          ).then((value) => getData());
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
