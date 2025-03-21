import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:p2bp_2025spring_mobile/theme.dart';

/// Bar Indicator for the Sliding Up Panels (Edit Project, Results)
class BarIndicator extends StatelessWidget {
  const BarIndicator({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Center(
        child: Container(
          width: 40,
          height: 5,
          decoration: const BoxDecoration(
            color: Colors.white60,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
    );
  }
}

/// Text Boxes used in Edit Project. With correct text counters, alignment, and
/// coloring.
class EditProjectTextBox extends StatelessWidget {
  final int maxLength;
  final int maxLines;
  final int minLines;
  final String labelText;

  const EditProjectTextBox(
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

/// Icon buttons used in Edit Project Panel. Rounded buttons with icon alignment
/// set to end. 15 padding on left and right.
class EditButton extends StatelessWidget {
  final String text;
  final Color foregroundColor;
  final Color backgroundColor;
  final Icon? icon;
  final VoidCallback? onPressed;
  final Color iconColor;
  final IconAlignment iconAlignment;

  const EditButton({
    super.key,
    required this.text,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onPressed,
    this.icon,
    this.iconColor = Colors.white,
    this.iconAlignment = IconAlignment.end,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.only(left: 15, right: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        iconColor: iconColor,
        disabledBackgroundColor: disabledGrey,
      ),
      onPressed: onPressed,
      label: Text(text),
      icon: icon,
      iconAlignment: iconAlignment,
    );
  }
}

class CreationTextBox extends StatelessWidget {
  final int maxLength;
  final int maxLines;
  final int minLines;
  final String labelText;
  final ValueChanged? onChanged;
  final Icon? icon;
  final String? errorMessage;

  const CreationTextBox({
    super.key,
    required this.maxLength,
    required this.labelText,
    required this.maxLines,
    required this.minLines,
    this.onChanged,
    this.icon,
    this.errorMessage,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: const TextSelectionThemeData(
              selectionColor: Colors.blue, selectionHandleColor: Colors.blue),
        ),
        child: TextFormField(
          onChanged: onChanged,
          style: const TextStyle(color: Colors.black),
          maxLength: maxLength,
          maxLines: maxLines,
          minLines: minLines,
          cursorColor: const Color(0xFF585A6A),
          validator: (value) {
            // TODO: custom error check parameter?
            if (errorMessage != null && (value == null || value.length < 3)) {
              // TODO: eventually require error message?
              return errorMessage ??
                  'Error, insufficient input (validator error message not set)';
            }
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: icon,
            alignLabelWithHint: true,
            counterStyle: const TextStyle(color: Colors.black),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(
                color: Color(0xFFD32F2F),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(
                color: Color(0xFFD32F2F),
                width: 2,
              ),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(
                width: 1.5,
                color: Color(0xFF6A89B8),
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(
                width: 2,
                color: Color(0xFF5C78A1),
              ),
            ),
            hintText: labelText,
            hintStyle: const TextStyle(
              fontWeight: FontWeight.w300,
              color: Color(0xA9000000),
            ),
          ),
        ),
      ),
    );
  }
}

// Square drop/upload area widget, with variable size and icon.
// Requires width, height, function, and IconData (in format: Icons.<icon_name>)
class PhotoUpload extends StatelessWidget {
  final double width;
  final double height;
  final IconData icon;
  final bool circular;
  final GestureTapCallback onTap;

  const PhotoUpload({
    super.key,
    required this.width,
    required this.height,
    required this.icon,
    required this.onTap,
    required this.circular,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: circular
            ? BoxDecoration(
                color: const Color(0x2A000000),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6A89B8)),
              )
            : BoxDecoration(
                color: const Color(0x2A000000),
                shape: BoxShape.rectangle,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                border: Border.all(color: const Color(0xFF6A89B8)),
              ),
        child: Icon(
          icon,
          size: circular ? ((width + height) / 4) : ((width + height) / 10),
        ),
      ),
    );
  }
}

class PasswordTextFormField extends StatelessWidget {
  final InputDecoration _decoration;
  final TextEditingController? _controller;
  final String? _forceErrorText;
  final bool _obscureText;
  final void Function(String)? _onChanged;

  PasswordTextFormField({
    super.key,
    decoration,
    controller,
    forceErrorText,
    obscureText,
    onChanged,
  })  : _decoration = decoration ??
            InputDecoration().applyDefaults(ThemeData().inputDecorationTheme),
        _controller = controller,
        _forceErrorText = forceErrorText,
        _obscureText = obscureText ?? true,
        _onChanged = onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: _obscureText,
      enableSuggestions: false,
      autocorrect: false,
      autovalidateMode: AutovalidateMode.disabled,
      decoration: _decoration,
      controller: _controller,
      forceErrorText: _forceErrorText,
      onChanged: _onChanged,
    );
  }
}

/// Text form field used for dialog boxes.
///
/// Enter an [errorMessage] for error validation. Put in a form for validation.
/// Takes a [maxLength], [labelText] and optional [errorMessage], [icon], and
/// [onChanged]. Optional [minChars] parameter to specify the minimum number of
/// characters for validation (default: 3)
class DialogTextBox extends StatelessWidget {
  final int? maxLength;
  final String labelText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatter;
  final bool? autofocus;
  final ValueChanged? onChanged;
  final Icon? icon;
  final String? errorMessage;
  final int? minChars;

  const DialogTextBox({
    super.key,
    this.maxLength,
    required this.labelText,
    this.onChanged,
    this.icon,
    this.errorMessage,
    this.minChars,
    this.keyboardType,
    this.inputFormatter,
    this.autofocus,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: const TextSelectionThemeData(
              selectionColor: Colors.blue, selectionHandleColor: Colors.blue),
        ),
        child: TextFormField(
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: inputFormatter,
          autofocus: autofocus ?? false,
          style: const TextStyle(color: Colors.black),
          maxLength: maxLength,
          cursorColor: const Color(0xFF585A6A),
          validator: (value) {
            if (errorMessage != null &&
                (value == null || value.length < (minChars ?? 3))) {
              return errorMessage ??
                  'Error, insufficient input (validator error message not set)';
            }
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: icon,
            alignLabelWithHint: true,
            counterStyle: const TextStyle(color: Colors.black),
            errorBorder: UnderlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xFFD32F2F),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFFD32F2F),
                width: 2,
              ),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                width: 1.5,
                color: Color(0xFF6A89B8),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                width: 2,
                color: Color(0xFF5C78A1),
              ),
            ),
            hintText: labelText,
            hintStyle: const TextStyle(
              fontWeight: FontWeight.w300,
              color: Color(0xA9000000),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog for test finish confirmation.
///
/// Takes only an [onNext] parameter. This should contain the function to be
/// called when finish the test (i.e. saving the data, pushing to the next
/// page).
class TestFinishDialog extends StatelessWidget {
  const TestFinishDialog({
    super.key,
    required this.onNext,
  });

  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Column(
        children: [
          Text(
            "Finish",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Text(
        "This will leave the test. Only continue if you are finished with this test.",
        style: TextStyle(fontWeight: FontWeight.bold),
        overflow: TextOverflow.clip,
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancel")),
        TextButton(onPressed: onNext, child: Text("Next"))
      ],
    );
  }
}

/// Directions widget used for tests.
///
/// Pass through a [visibility] variable. This should be of type [bool] and
/// control the visibility of the directions. The [onTap] function passed
/// should toggle the [visibility] boolean in a [setState]. It may do other
/// things on top of this if desired. The [text] should be the directions
/// variable which controls the text to display.
class DirectionsWidget extends StatelessWidget {
  const DirectionsWidget({
    super.key,
    required this.onTap,
    required this.text,
    required this.visibility,
  });

  final VoidCallback? onTap;
  final String text;
  final bool visibility;

  @override
  Widget build(BuildContext context) {
    return visibility
        ? Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 20.0, horizontal: 25.0),
              child: InkWell(
                onTap: onTap,
                child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      color: directionsTransparency,
                      gradient: defaultGrad,
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    )),
              ),
            ),
          )
        : Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    gradient: defaultGrad,
                    color: directionsTransparency),
                child: IconButton(
                    color: Colors.white,
                    onPressed: onTap,
                    icon: Icon(
                      Icons.help_outline,
                      size: 35,
                    )),
              ),
            ),
          );
  }
}

/// Visibility switch widget for tests page.
///
/// Toggles visibility for the old shapes on test pages. Takes in a [visibility]
/// variable and an [onChanged] function. The [onChanged] function is of type
/// [Function(bool)?]. It takes a [bool] parameter and should change the
/// [visibility] variable to the value of the [bool] parameter. Should be in a
/// [setState].
class VisibilitySwitch extends StatelessWidget {
  const VisibilitySwitch({
    super.key,
    required bool visibility,
    this.onChanged,
  }) : _visibility = visibility;

  final bool _visibility;
  final Function(bool)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: defaultGrad,
          color: directionsTransparency,
          borderRadius: BorderRadius.all(Radius.circular(15))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Visibility:",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Tooltip(
              message: "Toggle Visibility of Old Shapes",
              child: Switch(
                // This bool value toggles the switch.
                value: _visibility,
                activeTrackColor: placeYellow,
                inactiveThumbColor: placeYellow,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TestButton extends StatelessWidget {
  /// Test button used for test bottom sheets.
  ///
  /// Takes a [buttonText] parameter for the button text and [onPressed]
  /// parameter for the function. Takes an optional [flex] parameter for flex of
  /// button. Defaults to a flex of 1 if null.
  const TestButton({
    this.flex,
    this.backgroundColor,
    required this.buttonText,
    required this.onPressed,
    super.key,
  });

  final Color? backgroundColor;
  final int? flex;
  final String buttonText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex ?? 1,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.white,
          foregroundColor: Colors.black,
          disabledBackgroundColor: disabledGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        onPressed: onPressed,
        child: Center(
            child: Text(
          buttonText,
          textAlign: TextAlign.center,
        )),
      ),
    );
  }
}

/// Generic modal bottom sheet for tests.
///
/// Takes a [title] and [subtitle] to display above the [contentList].
/// The [subtitle] is optional, and will default to none.
/// The format starts with a centered title, then subtitle under that. Then,
/// some spacing, and then [contentList] is rendered under this. This
/// [contentList] should contain all buttons and categories needed for the
/// sheet. Then a cancel inkwell, which will use the [onCancel] parameter.
void showTestModalGeneric(BuildContext context,
    {required VoidCallback? onCancel,
    required String title,
    required String? subtitle,
    required List<Widget> contentList}) {
  showModalBottomSheet<void>(
      sheetAnimationStyle:
          AnimationStyle(reverseDuration: Duration(milliseconds: 100)),
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Container(
              // Container decoration- rounded corners and gradient
              decoration: BoxDecoration(
                gradient: defaultGrad,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24.0),
                  topRight: Radius.circular(24.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  spacing: 5,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const BarIndicator(),
                    Center(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: placeYellow,
                        ),
                      ),
                    ),
                    subtitle != null
                        ? Center(
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[400],
                              ),
                            ),
                          )
                        : SizedBox(),
                    subtitle != null ? SizedBox(height: 10) : SizedBox(),
                    ...contentList,
                    SizedBox(height: 15),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: InkWell(
                        onTap: onCancel,
                        child: const Padding(
                          padding: EdgeInsets.only(right: 20, bottom: 0),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFFFD700)),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      });
}

/// Error text for test pages.
///
/// Displays a text error at bottom of screen with the text specified by the
/// [text] parameter. Defaults to point placed outside of polygon error text.
class TestErrorText extends StatelessWidget {
  const TestErrorText({
    this.text,
    super.key,
  });

  final String? text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 100.0),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red[900],
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text ?? 'You have placed a point outside of the project area!',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.red[50],
            ),
          ),
        ),
      ),
    );
  }
}
