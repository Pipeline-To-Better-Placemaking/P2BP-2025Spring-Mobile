import 'package:flutter/material.dart';
import 'strings.dart';
import 'theme.dart';

enum _PageNames { text, compare }

// Nonsense filler until backend is started
const List<String> _testNames = [
  'Acoustical Profile',
  'Spatial Boundaries',
  'Nature Prevalence',
  'Lighting Profile',
  'Absence Of Order Locator',
  'People In Place',
  'People In Motion',
  'Community Survey',
  'Identifying Access',
  'Identifying Program',
  'Section Cutter',
];
// End filler
const String _dropdownDefault = 'Select Test';

class TestSelectionScreen extends StatefulWidget {
  const TestSelectionScreen({super.key});

  @override
  State<TestSelectionScreen> createState() => _TestSelectionScreenState();
}

class _TestSelectionScreenState extends State<TestSelectionScreen> {
  static final _pages = [
    _TextScreen(),
    _SelectedTestScreen(),
  ];
  _PageNames currentPage = _PageNames.text;

  // Needs to be initialized in initState() to pass callback, hence late
  late final _DropdownRowForm _dropdownRowForm;

  @override
  void initState() {
    super.initState();
    _dropdownRowForm = _DropdownRowForm(pageChangeCallback);
  }

  /// Used to switch to project comparison view once projects are selected.
  /// setState must be called in this class to work but controllers and logic
  /// are within _DropdownRowForm, requiring this callback function.
  void pageChangeCallback(_PageNames newPage) {
    if (currentPage != newPage) {
      setState(() {
        currentPage = newPage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: DefaultTextStyle(
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue[700],
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 20),
                  // Permanent row with dropdowns at top
                  _dropdownRowForm,
                  const SizedBox(height: 25),
                  // Dynamically switches between text default and comparison
                  _pages[currentPage.index],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Form containing row which has single dropdown menu containing each test
class _DropdownRowForm extends StatefulWidget {
  /// Required callback function from parent for passing page to since using
  /// setState() here would not update anything outside this Form.
  final Function pageChangeCallback;

  const _DropdownRowForm(this.pageChangeCallback, {super.key});

  @override
  State<_DropdownRowForm> createState() => _DropdownRowFormState();
}

class _DropdownRowFormState extends State<_DropdownRowForm> {
  final TextEditingController _dropdownController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Start listening to changes to dropdown selection
    _dropdownController.addListener(_checkBothDropdownSelected);
  }

  // Passes compare page if two projects have been selected, else text page
  void _checkBothDropdownSelected() {
    if (_dropdownController.text.isNotEmpty &&
        _dropdownController.text != _dropdownDefault) {
      widget.pageChangeCallback(_PageNames.compare);
    } else {
      widget.pageChangeCallback(_PageNames.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ProjectDropdown(
            controller: _dropdownController,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dropdownController.dispose();
    super.dispose();
  }
}

/// Widget for dropdown menu of tests
class _ProjectDropdown extends StatefulWidget {
  final TextEditingController? controller;

  const _ProjectDropdown({super.key, this.controller});

  @override
  State<_ProjectDropdown> createState() => _ProjectDropdownState();
}

class _ProjectDropdownState extends State<_ProjectDropdown> {
  @override
  Widget build(BuildContext context) {
    final dropdownMenuEntries = _buildDropdownEntryList();

    return Container(
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        gradient: verticalBlueGrad,
      ),
      child: DropdownMenu<String>(
        controller: widget.controller,
        initialSelection: _dropdownDefault,
        menuStyle: MenuStyle(
          alignment: Alignment.bottomLeft,
          backgroundColor: WidgetStatePropertyAll<Color>(Color(0xFF2F6DCF)),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        textStyle: TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 20),
          constraints: BoxConstraints(maxHeight: 55),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        trailingIcon: Icon(
          Icons.arrow_drop_down,
          color: Colors.white60,
        ),
        selectedTrailingIcon: Icon(
          Icons.arrow_drop_up,
          color: Colors.white60,
        ),
        dropdownMenuEntries: dropdownMenuEntries,
      ),
    );
  }

  /// Constructs the list of entries for project dropdowns
  // Primarily constructed this way to hopefully be easy to
  // use with the backend once that is started
  // This will almost certainly need to be changed significantly once backend
  List<DropdownMenuEntry<String>> _buildDropdownEntryList() {
    List<DropdownMenuEntry<String>> result = [];

    // Default entry
    result.add(
      DropdownMenuEntry(
        value: _dropdownDefault,
        label: _dropdownDefault,
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(Colors.white),
          visualDensity: VisualDensity(vertical: -2.5),
        ),
      ),
    );

    // Loops through all tests
    for (var project in _testNames) {
      result.add(
        DropdownMenuEntry(
          value: project,
          label: project,
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(Colors.white),
            visualDensity: VisualDensity(vertical: -2.5),
          ),
        ),
      );
    }

    return result;
  }
}

/// Default lower/middle section of page with text instructions on how to use.
class _TextScreen extends StatelessWidget {
  const _TextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(Strings.testSelectionText),
      ],
    );
  }
}

/// Display the test type selected by the user
class _SelectedTestScreen extends StatefulWidget {
  const _SelectedTestScreen({super.key});

  @override
  State<_SelectedTestScreen> createState() => _SelectedTestScreenState();
}

class _SelectedTestScreenState extends State<_SelectedTestScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Selected Test Screen'),
    );
  }
}
