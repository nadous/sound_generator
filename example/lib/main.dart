import 'package:flutter/material.dart';
import 'package:sound_generator/sound_generator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Map<String, bool> oscillators = {'440': false, '880': false, '1000': false};

  double balance = 0;
  double volume = 1;
  WaveForm waveForm = WaveForm.sine;

  List<int>? oneCycleData;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Sound Generator Example'),
        ),
        body: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 20,
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
            Divider(color: Colors.red),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(oscillators.length, (index) {
                final uid = oscillators.keys.elementAt(index);
                final isPlaying = oscillators.values.elementAt(index);

                return CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.lightBlueAccent,
                  child: IconButton(
                      icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                      onPressed: () {
                        isPlaying ? SoundGenerator.stop(uid) : SoundGenerator.start(uid, double.tryParse(uid) ?? 440.0);
                      }),
                );
              }),
            ),
            SizedBox(height: 5),
            Divider(color: Colors.red),
            SizedBox(height: 5),
            Text("Volume"),
            Container(
              width: double.infinity,
              height: 40,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Center(child: Text(this.volume.toStringAsFixed(2))),
                ),
                Expanded(
                  flex: 8, // 60%
                  child: Slider(
                      min: 0,
                      max: 1,
                      value: this.volume,
                      onChanged: (_value) {
                        setState(() {
                          this.volume = _value.toDouble();
                          SoundGenerator.setVolume(this.volume);
                        });
                      }),
                )
              ]),
            )
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    SoundGenerator.release();
  }

  @override
  void initState() {
    super.initState();

    SoundGenerator.onIsPlayingChanged.listen((value) {
      print(value);
      setState(() {
        oscillators[value["uid"]] = value["is_playing"];
      });
    });
  }
}
