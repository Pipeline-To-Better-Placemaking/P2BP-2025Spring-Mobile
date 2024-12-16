import 'package:flutter/material.dart';
import 'theme.dart';

// TODO: Change text pick color from purple

class EditProjectPanel extends StatefulWidget {
  const EditProjectPanel({super.key});

  @override
  State<EditProjectPanel> createState() => _EditProjectPanel();
}

class _EditProjectPanel extends State<EditProjectPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (context) {
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: SingleChildScrollView(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: defaultGrad,
                        // rounded corners of panel
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24.0),
                          topRight: Radius.circular(24.0),
                        ),
                      ),
                      child: Column(
                        children: [
                          BarIndicator(),
                          Column(
                            children: [
                              ListView(
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                children: <Widget>[
                                  Container(
                                    alignment: Alignment.center,
                                    margin: const EdgeInsets.only(bottom: 20),
                                    child: Text(
                                      "Edit Project",
                                      style: TextStyle(
                                          color: Colors.yellow[700],
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          // alignment: Alignment.center,
                                          padding: EdgeInsets.only(bottom: 20),
                                          margin:
                                              const EdgeInsets.only(left: 20),
                                          child: ObscuredTextBox(
                                            maxLength: 60,
                                            maxLines: 2,
                                            minLines: 1,
                                            labelText: 'Project Name',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          children: [
                                            CircleAvatar(
                                              radius: 27.0,
                                              backgroundColor:
                                                  Color(0xFFFFCC00),
                                              child: Center(
                                                child: Icon(
                                                    Icons.add_photo_alternate,
                                                    size: 37),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 3),
                                              child: Text(
                                                'Update Cover',
                                                style: TextStyle(
                                                  color: Color(0xFFFFD700),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: EdgeInsets.only(bottom: 20),
                                    margin: const EdgeInsets.only(
                                        left: 20, right: 20),
                                    child: ObscuredTextBox(
                                      maxLength: 240,
                                      maxLines: 4,
                                      minLines: 3,
                                      labelText: 'Project Description',
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        alignment: Alignment.topLeft,
                                        margin: const EdgeInsets.only(
                                            left: 20, right: 5),
                                        child: EditButton(
                                          text: 'Update Map',
                                          foregroundColor: Colors.black,
                                          backgroundColor: Color(0xFFFFCC00),
                                          icon: Icon(Icons.gps_fixed),
                                          // TODO: edit w/ actual function
                                          onPressed: () {},
                                        ),
                                      ),
                                      Container(
                                        alignment: Alignment.topLeft,
                                        margin: const EdgeInsets.only(
                                            left: 5, right: 20),
                                        child: EditButton(
                                          text: 'Delete Project',
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.black,
                                          icon: Icon(Icons.delete),
                                          // TODO: edit w/ actual function
                                          onPressed: () {},
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 165, top: 20, bottom: 20),
                                        child: EditButton(
                                          text: 'Save Changes',
                                          foregroundColor: Colors.black,
                                          backgroundColor: Color(0xFFFFCC00),
                                          icon: Icon(Icons.save),
                                          // TODO: edit w/ actual function
                                          onPressed: () {},
                                        ),
                                      ),
                                      InkWell(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              left: 20, top: 20, bottom: 20),
                                          child: Text(
                                            'Cancel',
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Color(0xFFFFD700)),
                                          ),
                                        ),
                                        onTap: () {
                                          setState(() {});
                                        },
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          child: const Text('Open bottom sheet'),
        ),
      ),
    );
  }
}

class EditButton extends StatelessWidget {
  final String text;
  final Color foregroundColor;
  final Color backgroundColor;
  final Icon icon;
  final Function onPressed;

  const EditButton({
    super.key,
    required this.text,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        padding: EdgeInsets.only(left: 15, right: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
      ),
      onPressed: () => onPressed(),
      label: Text(text),
      icon: icon,
      iconAlignment: IconAlignment.end,
    );
  }
}

class ObscuredTextBox extends StatelessWidget {
  final int maxLength;
  final int maxLines;
  final int minLines;
  final String labelText;

  const ObscuredTextBox(
      {super.key,
      required this.maxLength,
      required this.labelText,
      required this.maxLines,
      required this.minLines});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: TextField(
        style: const TextStyle(color: Colors.white),
        maxLength: maxLength,
        maxLines: maxLines,
        minLines: minLines,
        cursorColor: Colors.white10,
        decoration: InputDecoration(
          alignLabelWithHint: true,
          counterStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white70),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          labelText: labelText,
          floatingLabelAlignment: FloatingLabelAlignment.start,
          floatingLabelStyle: const TextStyle(
            color: Colors.white,
          ),
          labelStyle: const TextStyle(
            color: Colors.white60,
          ),
        ),
      ),
    );
  }
}
