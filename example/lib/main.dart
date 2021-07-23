import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sound_generator/sound_generator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class MyPainter extends CustomPainter {
  //         <-- CustomPainter class
  final List<int> oneCycleData;

  MyPainter(this.oneCycleData);

  @override
  void paint(Canvas canvas, Size size) {
    var i = 0;
    List<Offset> maxPoints = [];

    final t = size.width / (oneCycleData.length - 1);
    for (var _i = 0, _len = oneCycleData.length; _i < _len; _i++) {
      maxPoints.add(Offset(t * i, size.height / 2 - oneCycleData[_i].toDouble() / 32767.0 * size.height / 2));
      i++;
    }

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawPoints(PointMode.polygon, maxPoints, paint);
  }

  @override
  bool shouldRepaint(MyPainter old) {
    if (oneCycleData != old.oneCycleData) {
      return true;
    }
    return false;
  }
}

class _MyAppState extends State<MyApp> {
  Map<String, bool> oscillators = {'440': false, '880': false, '1000': false};

  double balance = 0;
  double volume = 1;
  WaveForm waveForm = WaveForm.sine;

  List<int> ?oneCycleData;

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
                  Text("A Cycle's Snapshot With Real Data"),
                  SizedBox(height: 2),
                  Container(
                      height: 100,
                      width: double.infinity,
                      color: Colors.white54,
                      padding: EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 0,
                      ),
                      child: oneCycleData != null
                          ? CustomPaint(
                              //                       <-- CustomPaint widget
                              painter: MyPainter(oneCycleData!),
                            )
                          : Container()),
                  SizedBox(height: 2),
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
                  Text("Balance"),
                  Container(
                      width: double.infinity,
                      height: 40,
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
                        Expanded(
                          flex: 2,
                          child: Center(child: Text(this.balance.toStringAsFixed(2))),
                        ),
                        Expanded(
                          flex: 8, // 60%
                          child: Slider(
                              min: -1,
                              max: 1,
                              value: this.balance,
                              onChanged: (_value) {
                                setState(() {
                                  this.balance = _value.toDouble();
                                  SoundGenerator.setBalance(this.balance);
                                });
                              }),
                        )
                      ])),
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
                      ]))
                ]))));
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

    SoundGenerator.onOneCycleDataHandler.listen((value) {
      setState(() {
        oneCycleData = value;
      });
    });

    SoundGenerator.setAutoUpdateOneCycleSample(true);
    SoundGenerator.refreshOneCycleData();
  }
}
