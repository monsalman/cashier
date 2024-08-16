import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class Shimmerr extends StatelessWidget {
  final int itemCount;

  const Shimmerr({Key? key, this.itemCount = 10}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: EdgeInsets.only(top: 10, left: 20, right: 20),
            child: Card(
              child: ListTile(
                title: Container(
                  width: double.infinity,
                  height: 18,
                  color: Colors.white,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 12,
                      color: Colors.white,
                      margin: EdgeInsets.only(top: 5),
                    ),
                    Container(
                      width: double.infinity,
                      height: 12,
                      color: Colors.white,
                      margin: EdgeInsets.only(top: 5),
                    ),
                    Container(
                      width: double.infinity,
                      height: 12,
                      color: Colors.white,
                      margin: EdgeInsets.only(top: 5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}