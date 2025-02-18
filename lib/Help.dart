import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text("Yardım", style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Sıkça Sorulan Sorular", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ExpansionTile(
              title: Text("Scoliosis Brace nedir?"),
              children: [Padding(padding: EdgeInsets.all(8.0), child: Text("Scoliosis Brace, omurga eğriliğini düzeltmek için kullanılan bir cihazdır."))],
            ),
            ExpansionTile(
              title: Text("Cihaz bağlantı hatası alıyorum, ne yapmalıyım?"),
              children: [Padding(padding: EdgeInsets.all(8.0), child: Text("Cihazınızı Bluetooth ile tekrar bağlamayı deneyin veya uygulamayı yeniden başlatın."))],
            ),
          ],
        ),
      ),
    );
  }
}
