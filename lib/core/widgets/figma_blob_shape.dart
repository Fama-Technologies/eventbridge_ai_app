import 'package:flutter/material.dart';

class FigmaBlobShape extends StatelessWidget {
  const FigmaBlobShape({
    super.key,
    this.width = 160,
    this.height = 190,
    this.color = const Color(0xFFF4E8E5),
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              top: -25,
              right: -35,
              child: Container(
                width: width * 1.45,
                height: height * 1.25,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(width * 0.8),
                    topRight: Radius.circular(width * 0.8),
                    bottomLeft: Radius.circular(width * 0.45),
                    bottomRight: Radius.circular(width * 0.45),
                  ),
                ),
                transform: Matrix4.rotationZ(-0.52), // about -30deg
              ),
            ),
          ],
        ),
      ),
    );
  }
}
