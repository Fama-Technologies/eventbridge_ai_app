import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomShape extends StatelessWidget {
  const CustomShape({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.rotate(
        angle: -30.475 * (3.1415926535 / 180), // degrees → radians
        child: SizedBox(
          width: 283.743,
          height: 268.141,
          child: SvgPicture.string(
            '''
<svg xmlns="http://www.w3.org/2000/svg" width="209" height="250" viewBox="0 0 209 250" fill="none">
  <path d="M182.377 -35.0589C221.799 -24.9563 258.028 -4.36658 282.35 28.2134C306.671 60.7933 319.26 105.261 302.636 134.299C286.012 163.336 240.35 176.841 200.828 199.191C161.232 221.812 127.852 253.007 102.046 248.937C76.4147 244.765 58.3578 205.327 38.5596 168.499C18.8604 131.84 -2.58016 97.7911 0.253627 62.8234C2.91352 27.9581 29.9226 -8.09667 64.8215 -26.3675C99.8194 -44.47 142.782 -45.0592 182.377 -35.0589Z" fill="#FF6738" fill-opacity="0.1"/>
</svg>
            ''',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
