import 'package:flutter/material.dart';

class SingalongScreen extends StatelessWidget {
  final String songId;
  const SingalongScreen({super.key, required this.songId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sing Along')),
      body: Center(child: Text('Sing along: $songId')),
    );
  }
}
