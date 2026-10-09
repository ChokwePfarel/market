
import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String labelText;
  final List<T> items;
  final T value;
  final void Function(T?) onChanged;
  final String Function(T)? displayItem;
  final Color borderColor;

  const CustomDropdown({
    super.key,
    required this.labelText,
    required this.items,
    required this.value,
    required this.onChanged,
    this.displayItem,
    this.borderColor = Colors.black,
  });



  //TO-DO :I shold Check this code again

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth),

          //Wrap with a Theme to customize the dropdown menu's SHAPE
          child: Theme(
            data: Theme.of(context).copyWith(
              // Use DropdownMenuTheme to set the border radius via MenuStyle
              dropdownMenuTheme: DropdownMenuThemeData(
                menuStyle: MenuStyle(
                  // This applies the rounded corners to the floating menu box
                  shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            child: DropdownButtonFormField<T>(
              isExpanded: true,
              initialValue: value,
              // 2. Use dropdownColor to set the background color
              dropdownColor: Colors.white,
              // 3. Keep the elevation to make it look "floating"
              elevation: 8,
              decoration: InputDecoration(
                labelText: labelText,
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(20),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: borderColor, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: borderColor),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    displayItem != null ? displayItem!(item) : item.toString(),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }
}
