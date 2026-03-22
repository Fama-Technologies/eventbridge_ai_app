import 'package:flutter/material.dart';

Widget buildGoogleSignInButton({VoidCallback? onPressed}) {
  return OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/icons/google.png', height: 24),
        const SizedBox(width: 12),
        const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
