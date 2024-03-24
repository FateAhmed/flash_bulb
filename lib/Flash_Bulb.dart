// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:torch_light/torch_light.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

class FlashBulb extends StatefulWidget {
  const FlashBulb({super.key});

  @override
  State<FlashBulb> createState() => _FlashBulbState();
}

class _FlashBulbState extends State<FlashBulb> with SingleTickerProviderStateMixin {
  final _springDescription = const SpringDescription(mass: 1.0, stiffness: 500.0, damping: 15.0);
  late SpringSimulation _springSimX;
  late SpringSimulation _springSimY;
  Ticker? _ticker;
  Offset thumboffsets = const Offset(0, 100.0);
  Offset anchoroffsets = Offset.zero;
  bool _states = false;
  final player = AudioPlayer();
  final playerStop = AudioPlayer();

  Future<void> torchLightOn() async {
    try {
      player.play(AssetSource('audio/switch.mp3'), volume: 100);

      await TorchLight.enableTorch();
    } catch (e) {
      var snackBar = SnackBar(content: Text("Error: $e"));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> torchLightOff() async {
    playerStop.play(AssetSource('audio/switch.mp3'), volume: 100);
    await TorchLight.disableTorch();
  }

  // when anchor is stretch
  void _onpanStart(DragStartDetails details) {
    endSpring();
  }

  // Update between the event
  void _onpanupdate(DragUpdateDetails details) {
    setState(() {
      thumboffsets += details.delta;
    });
  }

  // When Anchor is Stretch off
  void _onPanEnd(DragEndDetails details) {
    startSpring();
    setState(() {
      if (thumboffsets.dy >= 0.0) {
        _states != false ? torchLightOff() : torchLightOn();
        _states = !_states;
        // _states == false ? play() : play();
      }
    });
  }

  void endSpring() {
    if (_ticker != null) {
      _ticker!.stop();
    }
  }

  void startSpring() {
    _springSimX = SpringSimulation(_springDescription, thumboffsets.dx, anchoroffsets.dx, 0);

    _springSimY = SpringSimulation(_springDescription, thumboffsets.dy, 100, 100);

    _ticker ??= createTicker(_onTick);
    _ticker!.start();
  }

  void _onTick(Duration elapsedTime) {
    final elapsedSecondFraction = elapsedTime.inMilliseconds / 1000.0;
    setState(() {
      thumboffsets = Offset(_springSimX.x(elapsedSecondFraction), _springSimY.x(elapsedSecondFraction));
    });

    if (_springSimY.isDone(elapsedSecondFraction) && _springSimX.isDone(elapsedSecondFraction)) {
      endSpring();
    }
  }

  Color yellow = const Color.fromARGB(255, 253, 227, 139);

  @override
  Widget build(BuildContext context) {
    if (anchoroffsets == null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        RenderBox box = context.findRenderObject() as RenderBox;
        if (box.hasSize) {
          setState(() {
            anchoroffsets = box.size.center(Offset.zero);
            thumboffsets = anchoroffsets;
          });
        }
      });
      return const SizedBox();
    }

    double height = MediaQuery.of(context).size.height;
    return PopScope(
      canPop: _states != true,
      child: Scaffold(
          backgroundColor: _states != true ? Colors.white : yellow,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onPanStart: _onpanStart,
                  onPanUpdate: _onpanupdate,
                  onPanEnd: _onPanEnd,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        color: _states != true ? Colors.white : yellow,
                        width: 400,
                        height: 700,
                      ),
                      // Position of Text
                      Positioned(
                          top: 100,
                          child: Text(
                            "Flash Bulb",
                            style: GoogleFonts.lemon(
                              fontSize: 30,
                              color: _states != true ? Colors.black : Colors.white,
                            ),
                          )),
                      // Position of image
                      Positioned(
                        top: height / 2.5,
                        child: _states != true
                            ? Image.asset(
                                'assets/images/light-bulb-grey-128px.png',
                                height: 100,
                              )
                            : Image.asset(
                                'assets/images/light-bulb-on-128px.png',
                                height: 100,
                              ),
                      ),
                      // Position of image
                      Positioned(
                        top: (height / 2.5) + 95,
                        child: CustomPaint(
                          foregroundPainter: PullRope(
                            _states != true
                                ? const Color.fromRGBO(148, 145, 145, 1)
                                : const Color.fromRGBO(110, 96, 184, 1),
                            anchorOffset: anchoroffsets,
                            springOffset: thumboffsets,
                          ),
                        ),
                      ),
                      // Position of knot
                      Positioned(
                        top: (height / 2.5) + 85,
                        child: Transform.translate(
                          offset: thumboffsets,
                          child: Icon(
                            Icons.circle,
                            size: 14,
                            color: _states != true
                                ? const Color.fromRGBO(148, 145, 145, 1)
                                : const Color.fromRGBO(110, 96, 184, 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }
}

// Drawn Line here
class PullRope extends CustomPainter {
  final Offset springOffset;

  final Color lineColor;
  final Offset anchorOffset;
  PullRope(this.lineColor, {required this.anchorOffset, required this.springOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3;
    canvas.drawLine(anchorOffset, springOffset, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
