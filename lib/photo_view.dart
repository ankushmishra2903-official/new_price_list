import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImgView extends StatelessWidget {
  final File img;
  final String tag;
  const ImgView({Key? key, required this.img, required this.tag}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        child: PhotoView(
          heroAttributes: PhotoViewHeroAttributes(tag: tag),
          imageProvider: FileImage(img),
        )
    );
  }
}
