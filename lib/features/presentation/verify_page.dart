import 'package:flutter/material.dart';

class VerifyPage extends StatelessWidget {
  const VerifyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [




          Text('We Sent You A',
          style: TextStyle(
            color: Colors.white,
              fontSize: 40, fontWeight: FontWeight.bold),),

          SizedBox(height: 10,),

          Text('Verification Link',
          style: TextStyle(
            color: Colors.white,
            fontSize: 35, fontWeight: FontWeight.bold,
          ),),Text('Check your emails',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30, fontWeight: FontWeight.bold,
          ),),
        ]
      ),
    );
  }
}

