import 'package:flutter/material.dart';
import 'widgets.dart';
import 'strings.dart';

// Nonsense filler until backend is started
typedef Project = Map<int, String>;
final Project _projects = {
  -1: 'Select Project',
  0: 'Project Nona',
  1: 'Project Eola',
  2: 'Project Osceola',
  3: 'Project Oviedo',
  4: 'Project Orlando'
};
// End filler

enum PageNames { text, compare }

class ProjectComparisonPage extends StatefulWidget {
  const ProjectComparisonPage({super.key});

  @override
  State<ProjectComparisonPage> createState() => _ProjectComparisonPageState();
}

class _ProjectComparisonPageState extends State<ProjectComparisonPage> {
  PageNames currentPage = PageNames.text;
  var pages = [
    const _TextPage(),
    const _CompareDataPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        bottomNavigationBar: const BottomFloatingNavBar(),
        body: DefaultTextStyle(
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue[700],
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  _DropdownRowForm(),
                  const SizedBox(height: 25),
                  pages[currentPage.index],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownRowForm extends StatefulWidget {
  const _DropdownRowForm({super.key});

  @override
  State<_DropdownRowForm> createState() => _DropdownRowFormState();
}

class _DropdownRowFormState extends State<_DropdownRowForm> {
  final TextEditingController _dropdownController1 = TextEditingController(),
      _dropdownController2 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Row(
        children: [
          Expanded(
            flex: 45,
            child: _ProjectDropdown(
              controller: _dropdownController1,
            ),
          ),
          Expanded(
            flex: 5,
            child: SizedBox(),
          ),
          Expanded(
            flex: 45,
            child: _ProjectDropdown(
              controller: _dropdownController2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dropdownController1.dispose();
    _dropdownController2.dispose();
    super.dispose();
  }
}

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
          borderRadius: BorderRadius.circular(10),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.blue[900]!,
            Colors.blueAccent,
          ],
        ),
      ),
      child: DropdownMenu<String>(
        controller: widget.controller,
        menuStyle: MenuStyle(
          alignment: Alignment.bottomLeft,
          backgroundColor: WidgetStatePropertyAll<Color>(Colors.blueAccent),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        textStyle: TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          contentPadding: EdgeInsets.only(left: 9),
          constraints: BoxConstraints.tight(Size.fromHeight(45)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        trailingIcon: Icon(
          Icons.keyboard_arrow_up_sharp,
          color: Colors.white60,
        ),
        initialSelection: _projects[-1],
        dropdownMenuEntries: dropdownMenuEntries,
      ),
    );
  }

  // Constructs the list of entries for project dropdowns
  // Primarily constructed this way to hopefully be easy to
  // use with the backend once that is started
  // This will almost certainly need to be changed significantly once backend
  List<DropdownMenuEntry<String>> _buildDropdownEntryList() {
    List<DropdownMenuEntry<String>> result = [];

    for (int i = -1; i < _projects.length - 1; i++) {
      result.add(
        DropdownMenuEntry(
          value: _projects[i]!,
          label: _projects[i]!,
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

class _TextPage extends StatelessWidget {
  const _TextPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(Strings.compareProjectText1),
        SizedBox(height: 18),
        Text(Strings.compareProjectText2),
      ],
    );
  }
}

class _CompareDataPage extends StatefulWidget {
  const _CompareDataPage({super.key});

  @override
  State<_CompareDataPage> createState() => _CompareDataPageState();
}

class _CompareDataPageState extends State<_CompareDataPage> {
  @override
  Widget build(BuildContext context) {
    return Column(//TODO
        );
  }
}
