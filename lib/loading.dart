import 'package:flutter/material.dart';

class LoadingDialog extends StatelessWidget {
  static void show(BuildContext context,
          {Key? key, String? message, Color? color}) =>
      showDialog<void>(
        context: context,
        useRootNavigator: false,
        barrierDismissible: false,
        builder: (_) => LoadingDialog(
          key: key,
          message: message,
          color: color,
        ),
      ).then((_) => FocusScope.of(context).requestFocus(FocusNode()));

  static void hide(BuildContext context) {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  final String? message;
  final Color? color;

  const LoadingDialog({Key? key, this.message, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: color,
                    strokeWidth: 5,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Text(message ?? 'Please wait',
                      maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future confirmationDialog(
  context, {
  String? title,
  String content = 'Are you sure you want to proceed?',
  String yesText = 'OK',
  String noText = 'Cancel',
  Color yesColor = const Color(0xFF1A73E8),
  Function()? onYes,
  Function()? onNo,
}) {
  return showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: title == null ? null : Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () {
                  if (onNo != null) onNo();
                  Navigator.pop(context, false);
                },
                child: Text(noText),
              ),
              TextButton(
                style: TextButton.styleFrom(
                    backgroundColor: yesColor,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 14)),
                onPressed: () {
                  Navigator.pop(context, true);
                  if (onYes != null) onYes();
                },
                child: Text(
                  yesText,
                  style: const TextStyle(color: Color(0xFFFFFFFF)),
                ),
              ),
            ],
          ));
}
