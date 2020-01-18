// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:vector_math/vector_math_64.dart' show radians;
import 'package:flutter/services.dart';

import 'container_hand.dart';
import 'drawn_hand.dart';

/// Total distance traveled by a second or a minute hand, each second or minute,
/// respectively.
final radiansPerTick = radians(360 / 60);

/// Total distance traveled by an hour hand, each hour, in radians.
final radiansPerHour = radians(360 / 12);

/// A basic analog clock.
///
/// You can do better than this!
class AnalogClock extends StatefulWidget {
  const AnalogClock(this.model);

  final ClockModel model;

  @override
  _AnalogClockState createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock>
    with SingleTickerProviderStateMixin {
  var _now = DateTime.now();
  var _temperature = '';
  var _temperatureRange = '';
  var _condition = '';
  var _location = '';
  static double screenWidth = 0;
  static double screenHeight = 0;

  Timer _timer;

//  final RelativeRectTween relativeRectTween = RelativeRectTween(
//    begin: RelativeRect.fromLTRB(screenWidth, screenHeight / 2, 0, 0),
//    end: RelativeRect.fromLTRB(0, 0, 0, screenHeight / 2),
//  );

  AnimationController _controller;
  Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);

    double timeInHrs = _now.hour + (_now.minute / 60) + (_now.second / 3600);
    double timeInMS = (timeInHrs * 3600);
    int time = timeInMS.truncate();
    int diff = 18 * 3600 - time;
    print("time " + diff.toString());

    // Set the initial values.
    _controller = AnimationController(
      duration: Duration(seconds: diff * 60),
      vsync: this,
    );

    updateOffset();
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(AnalogClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  void updateOffset() {
    double now_double_hrs =
        _now.hour + (_now.minute / 60) + (_now.second / 3600);
    if (_now.hour < 18 && _now.hour >= 6) {
      double input_start = 18, input_end = 6;
      double output_start = 1, output_end = -1;
      double output = output_start +
          ((output_end - output_start) / (input_end - input_start)) *
              (now_double_hrs - input_start);

      _offsetAnimation =
          Tween<Offset>(begin: Offset(-output, 0), end: Offset(-1, 0.0))
              .animate(_controller);
    } else {
      _offsetAnimation =
          Tween<Offset>(begin: Offset(-1.1, 0), end: Offset(-1.1, 0.0))
              .animate(_controller);
    }
    if (_now.hour >= 18) {
      _controller.reset();
    } else if (_now.hour < 18 && _now.hour >= 6) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    _controller.dispose();
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      _temperature = widget.model.temperatureString;
      _temperatureRange = '(${widget.model.low} - ${widget.model.highString})';
      _condition = widget.model.weatherString;
      _location = widget.model.location;
    });
  }

  void _updateTime() {
    setState(() {
      _now = DateTime.now();

      updateOffset();

      // Update once per second. Make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _now.millisecond),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // There are many ways to apply themes to your clock. Some are:
    //  - Inherit the parent Theme (see ClockCustomizer in the
    //    flutter_clock_helper package).
    //  - Override the Theme.of(context).colorScheme.
    //  - Create your own [ThemeData], demonstrated in [AnalogClock].
    //  - Create a map of [Color]s to custom keys, demonstrated in
    //    [DigitalClock].
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    final customTheme = (_now.hour < 18 && _now.hour >= 6)
        ? Theme.of(context).copyWith(
            primaryColor: Color.fromRGBO(128, 128, 128, 1),
            textSelectionColor: Colors.black54,
            highlightColor: Color.fromRGBO(128, 128, 128, 1),
            accentColor: Color.fromRGBO(179, 0, 0, 1),
            backgroundColor: Colors.white,
          )
        : Theme.of(context).copyWith(
            primaryColor: Colors.white,
            textSelectionColor: Colors.white,
            highlightColor: Colors.white,
            accentColor: Color.fromRGBO(179, 0, 0, 1),
            backgroundColor: Color(0x4F3C4043),
          );

    final time = DateFormat.Hms().format(DateTime.now());
    final weatherInfo = DefaultTextStyle(
      style: TextStyle(color: customTheme.textSelectionColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_temperature),
          Text(_temperatureRange),
          Text(_condition),
          Text(_location),
        ],
      ),
    );

    return Semantics.fromProperties(
      properties: SemanticsProperties(
        label: 'Analog clock with time $time',
        value: time,
      ),
      child: Center(
        child: Container(
          child: ClipOval(
            child: Container(
              height: screenHeight - (screenHeight % 100),
              width: screenHeight - (screenHeight % 100),
              child: Stack(
                alignment: AlignmentDirectional.center,
                children: [
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromRGBO(0, 0, 0, 1),
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [
                              0.1,
                              0.25,
                              0.75,
                              0.9
                            ],
                            colors: [
                              Colors.black12,
                              Colors.black54,
                              Colors.black54,
                              Colors.black12
                            ]),
                      ),
                    ),
                  ),

                  Center(
                    child: SlideTransition(
                      position: _offsetAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromRGBO(255, 180, 0, 1),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Color.fromRGBO(255, 180, 0, 1),
                              blurRadius: 40.0,
                            )
                          ],
                          gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomCenter,
                              stops: [
                                0.1,
                                0.25,
                                0.5,
                                0.75,
                                1
                              ],
                              colors: [
                                Color.fromRGBO(255, 180, 0, 1),
                                Color.fromRGBO(255, 204, 128, 1),
                                Color.fromRGBO(255, 204, 50, 1),
                                Color.fromRGBO(250, 200, 100, 1),
                                Color.fromRGBO(255, 204, 0, 1)
                              ]),
                        ),
                      ),
                    ),
                  ),

                  DrawnHand(
                    color: customTheme.accentColor,
                    thickness: 1.5,
                    size: 0.9,
                    angleRadians: _now.second * radiansPerTick,
                  ),
                  DrawnHand(
                    color: customTheme.highlightColor,
                    thickness: 1.5,
                    size: 0.7,
                    angleRadians: _now.minute * radiansPerTick,
                  ),
                  // Example of a hand drawn with [Container].
                  ContainerHand(
                    color: Colors.transparent,
                    size: 0.5,
                    angleRadians: _now.hour * radiansPerHour +
                        (_now.minute / 60) * radiansPerHour,
                    child: Transform.translate(
                      offset: Offset(0.0, -60.0),
                      child: Container(
                        width: 6,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: customTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
