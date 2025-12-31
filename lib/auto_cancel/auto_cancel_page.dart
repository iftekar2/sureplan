import 'package:flutter/material.dart';

class AutoCancelPage extends StatefulWidget {
  const AutoCancelPage({super.key});

  @override
  State<AutoCancelPage> createState() => _AutoCancelPageState();
}

class FullWidthTrackShape extends RoundedRectSliderTrackShape {
  const FullWidthTrackShape();
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight!;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;

    return Rect.fromLTWH(
      offset.dx,
      trackTop,
      parentBox.size.width,
      trackHeight,
    );
  }
}

class _AutoCancelPageState extends State<AutoCancelPage> {
  bool _isAutoCancelEnabled = false;
  int _minAttendance = 60;
  int _sendNotificationBefore = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Auto Cancel Settings",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                ),

                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Enable Auto Cancellation",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 2),

                          Text(
                            "Automatically cancel event if attendence is low.",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Transform.scale(
                      scale: 1.2,
                      child: Switch(
                        value: _isAutoCancelEnabled,
                        onChanged: (bool newValue) {
                          setState(() {
                            _isAutoCancelEnabled = newValue;
                          });
                        },
                        activeColor: Colors.white,
                        activeTrackColor: Color(0xFF135BEC),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Minimum Attendance",
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                ),
              ),

              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                ),

                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          "Cancel if below",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        Expanded(
                          child: Text(
                            "${_minAttendance}%",
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF135BEC),
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 8.0,
                          trackShape: const FullWidthTrackShape(),

                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 12.0,
                            elevation: 3,
                          ),
                          overlayShape: SliderComponentShape.noOverlay,
                        ),

                        child: Slider(
                          value: _minAttendance.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 100,
                          label: _minAttendance.toString(),
                          onChanged: (value) {
                            setState(() {
                              _minAttendance = value.round();
                            });
                          },
                          activeColor: Color(0xFF135BEC),
                        ),
                      ),
                    ),

                    SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          "0%",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        Spacer(),
                        Text(
                          "100%",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Check Response",
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                ),
              ),

              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _sendNotificationBefore = 1;
                        });
                      },

                      child: Container(
                        height: 80,
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: _sendNotificationBefore == 1
                              ? Color(0xFF135BEC)
                              : Colors.white,
                          border: Border.all(
                            color: _sendNotificationBefore == 1
                                ? Color(0xFF135BEC)
                                : Colors.grey,
                          ),
                        ),

                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "1 Hour",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _sendNotificationBefore == 1
                                    ? Colors.white
                                    : Color(0xFF135BEC),
                              ),
                            ),

                            Text(
                              "Before",
                              style: TextStyle(
                                fontSize: 16,
                                color: _sendNotificationBefore == 1
                                    ? Colors.grey[200]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _sendNotificationBefore = 2;
                        });
                      },

                      child: Container(
                        height: 80,
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: _sendNotificationBefore == 2
                              ? Color(0xFF135BEC)
                              : Colors.white,
                          border: Border.all(
                            color: _sendNotificationBefore == 2
                                ? Color(0xFF135BEC)
                                : Colors.grey,
                          ),
                        ),

                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "2 Hour",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _sendNotificationBefore == 2
                                    ? Colors.white
                                    : Color(0xFF135BEC),
                              ),
                            ),

                            Text(
                              "Before",
                              style: TextStyle(
                                fontSize: 16,
                                color: _sendNotificationBefore == 2
                                    ? Colors.grey[200]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _sendNotificationBefore = 6;
                        });
                      },

                      child: Container(
                        height: 80,
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: _sendNotificationBefore == 6
                              ? Color(0xFF135BEC)
                              : Colors.white,
                          border: Border.all(
                            color: _sendNotificationBefore == 6
                                ? Color(0xFF135BEC)
                                : Colors.grey,
                          ),
                        ),

                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "6 Hour",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _sendNotificationBefore == 6
                                    ? Colors.white
                                    : Color(0xFF135BEC),
                              ),
                            ),

                            Text(
                              "Before",
                              style: TextStyle(
                                fontSize: 16,
                                color: _sendNotificationBefore == 6
                                    ? Colors.grey[200]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.network(
                      "https://img.icons8.com/?size=100&id=JJjDa0GHZLiS&format=png&color=000000",
                      height: 30,
                      width: 30,
                      color: Colors.grey[600],
                    ),

                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "We will send a final confirmation poll to all guests via notification before making the cancellation decision.",
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _isAutoCancelEnabled ? Color(0xFF135BEC) : Colors.grey,
                  border: Border.all(color: Colors.grey),
                ),

                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    "Save Changes",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _isAutoCancelEnabled ? Colors.white : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
