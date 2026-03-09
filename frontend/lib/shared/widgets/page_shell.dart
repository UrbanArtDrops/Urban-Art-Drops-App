import "package:flutter/material.dart";

class PageShell extends StatelessWidget {
  const PageShell({
    required this.title,
    required this.body,
    this.actions = const <Widget>[],
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: body,
    );
  }
}
