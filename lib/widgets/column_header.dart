import 'package:flutter/material.dart';
import 'package:score_tracker/widgets/marquee_widget.dart';

import '../styles.dart';

class ColumnHeader extends StatelessWidget {
  const ColumnHeader({
    required int score,
    required this.header,
  })  : _score = score,
        super();

  final int _score;
  final String header;

  @override
  Widget build(BuildContext context) {
    var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    var _width = MediaQuery.of(context).size.width;
    var _height = MediaQuery.of(context).size.height;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Flexible(
          child: Container(
            width: isPortrait ? _width * 0.1 : _width * 0.04,
            height: isPortrait ? _height * 0.07 : _height * 0.9,
            decoration: BoxDecoration(
              border: Border.all(width: 0),
              shape: BoxShape.circle,
              // You can use like this way or like the below line
              //borderRadius: new BorderRadius.circular(30.0),
              color: backgroundButtonColorBlue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _score.toString(),
                  style: TextStyle(
                      color: _score < 0
                          ? const Color(0xffc92225)
                          : foregroundColor,
                      fontFamily: fontFamilySFProText,
                      fontSize: 20.0,
                      fontStyle: FontStyle.normal),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 5.0,
        ),
        SizedBox(
          width: isPortrait ? _width * 0.14 : _width * 0.23,
          child: Center(
            child: MarqueeWidget(
              child: Text(
                header,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                    color: foregroundColor,
                    fontFamily: fontFamilySFProText,
                    fontSize: 13.0,
                    fontStyle: FontStyle.normal),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
