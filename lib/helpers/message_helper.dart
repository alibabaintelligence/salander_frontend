import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeadingIcons {
  static const good = Icon(
    CupertinoIcons.checkmark_alt_circle_fill,
    color: Colors.greenAccent,
    size: 30,
  );

  static const bad = Icon(
    CupertinoIcons.clear_circled_solid,
    color: Colors.redAccent,
    size: 30,
  );
}

class MessageHelper {
  static void showCustomSnackBar({
    required BuildContext context,
    required String message,
    required Icon leading,
  }) {
    final customSnackBar = SnackBar(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: (leading.color ?? Colors.black).withOpacity(0.6),
          width: 2.5,
        ),
      ),
      elevation: 0.0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.grey.shade800,
      padding: const EdgeInsets.all(8.0),
      width: 350.0,
      content: Row(
        children: [
          const SizedBox(width: 5.0),
          leading,
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.sora(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 13.0,
              ),
              maxLines: 5,
            ),
          ),
        ],
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(customSnackBar);
  }
}
