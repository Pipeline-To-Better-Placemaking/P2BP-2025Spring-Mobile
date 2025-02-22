import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:p2bp_2025spring_mobile/theme.dart'; // for ImageFilter

// Bar Indicator for the Sliding Up Panels (Edit Project, Results)
class BarIndicator extends StatelessWidget {
  const BarIndicator({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
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

// Text Boxes used in Edit Project. With correct text counters, alignment, and
// coloring.
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

// Icon buttons used in Edit Project Panel. Rounded buttons with icon alignment
// set to end. 15 padding on left and right.
class EditButton extends StatelessWidget {
  final String text;
  final Color foregroundColor;
  final Color backgroundColor;
  final Icon icon;
  final Function onPressed;
  final Color iconColor;

  const EditButton({
    super.key,
    required this.text,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.icon,
    required this.onPressed,
    this.iconColor = Colors.white,
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
      ),
      onPressed: () => onPressed(),
      label: Text(text),
      icon: icon,
      iconAlignment: IconAlignment.end,
    );
  }
}

class CreationTextBox extends StatefulWidget {
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
  State<CreationTextBox> createState() => _CreationTextBoxState();
}

class _CreationTextBoxState extends State<CreationTextBox> {
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    // Listen for focus changes
    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Decide icon color based on focus
    final Icon? focusedIcon = widget.icon != null
        ? Icon(
            widget.icon!.icon,
            color: _hasFocus
                ? const Color.fromARGB(255, 28, 91, 192) // Focused color
                : widget.icon!.color ?? const Color(0xFF757575),
          )
        : null;

    return SizedBox(
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: const TextSelectionThemeData(
              selectionColor: Colors.blue, selectionHandleColor: Colors.blue),
        ),
        child: TextFormField(
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          style: const TextStyle(
              color: Color(0xFF2F6DCF), fontWeight: FontWeight.w600),
          maxLength: widget.maxLength,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          cursorColor: const Color(0xFF2F6DCF),
          // Validator remains the same as in Version 2:
          validator: (value) {
            if (widget.errorMessage != null &&
                (value == null || value.length < 3)) {
              return widget.errorMessage!;
            }
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: focusedIcon,
            alignLabelWithHint: true,
            counterStyle:
                const TextStyle(color: Color.fromARGB(255, 28, 91, 192)),
            // BEGIN: Restored error styling from Version 1
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
            // END: Restored error styling from Version 1
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(
                width: 1.5,
                color: Color(0xFF2F6DCF),
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(
                width: 2,
                color: Color.fromARGB(255, 28, 91, 192),
              ),
            ),
            hintText: widget.labelText,
            hintStyle: const TextStyle(
              fontWeight: FontWeight.w300,
              color: Color(0xFF757575),
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
  final Color backgroundColor;
  final IconData icon;
  final bool circular;
  final GestureTapCallback onTap;

  const PhotoUpload({
    super.key,
    required this.width,
    required this.height,
    required this.backgroundColor,
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
                border: Border.all(color: const Color(0xFF2F6DCF)),
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
  final TextStyle? style;
  final Color? cursorColor;

  PasswordTextFormField({
    super.key,
    decoration,
    controller,
    forceErrorText,
    obscureText,
    onChanged,
    this.style,
    this.cursorColor,
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
      style: style,
      cursorColor: cursorColor,
    );
  }
}

enum CustomTab { projects, team }

/// Segmented Tab for Projects and Teams View V2
class CustomSegmentedTab extends StatefulWidget {
  final CustomTab selectedTab;
  final ValueChanged<CustomTab> onTabSelected;

  const CustomSegmentedTab({
    Key? key,
    required this.selectedTab,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  _CustomSegmentedTabState createState() => _CustomSegmentedTabState();
}

class _CustomSegmentedTabState extends State<CustomSegmentedTab> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(120),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 64, vertical: 16),
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            // Use your existing gradient or color:
            borderRadius: BorderRadius.circular(60),
            gradient: verticalBlueGrad,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                offset: Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          // A row with two expanded segments: Projects and Team.
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSegment(
                tab: CustomTab.projects,
                label: 'PROJECT',
              ),
              _buildSegment(
                tab: CustomTab.team,
                label: 'TEAM',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegment({required CustomTab tab, required String label}) {
    final bool isSelected = (widget.selectedTab == tab);

    // Selected tab
    final TextStyle selectedStyle = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );

    // Unselected tab
    final TextStyle unselectedStyle = const TextStyle(
      color: Color(0xFFB6D1EC),
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );

    return GestureDetector(
      onTap: () => widget.onTabSelected(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: isSelected ? selectedStyle : unselectedStyle,
        ),
      ),
    );
  }
}
