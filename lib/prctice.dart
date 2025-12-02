import 'package:flutter/material.dart';

class practice extends StatefulWidget {
  const practice({super.key});

  @override
  State<practice> createState() => _practiceState();
}

class _practiceState extends State<practice> {
  double _size = 0;
  @override
  void initState() {
    _size = 200;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => full()),
          ),
          child: Hero(
            tag: "animate",
            child: AnimatedContainer(
              height: _size,
              width: _size,
              color: Colors.red,
              duration: Duration(seconds: 50),
            ),
          ),
        ),
      ),
    );
  }
}

class full extends StatefulWidget {
  const full({super.key});

  @override
  State<full> createState() => _fullState();
}

class _fullState extends State<full> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Hero(
              tag: "animate",
              child: Container(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
