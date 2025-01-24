import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomDropdownWidget<T> extends StatelessWidget {
  final List<T> items;
  final T? selectedItem;
  final String hint;
  final ValueChanged<T?> onChanged;
  final RxBool isSelected;
  final Rx<T?> selectedValue;
  final Widget Function(T) itemBuilder;
  final IconData icon;
  final String? Function(T?)? validator; // Add validator

  CustomDropdownWidget({
    required this.items,
    required this.selectedItem,
    required this.hint,
    required this.onChanged,
    required this.isSelected,
    required this.selectedValue,
    required this.itemBuilder,
    this.icon = Icons.location_on,
    this.validator, // Add validator
  });

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      validator: validator, // Use the validator
      builder: (FormFieldState<T> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: state.hasError ? Colors.red : Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  hint: Text(hint),
                  value: isSelected.isTrue ? selectedValue.value : null,
                  icon: Icon(icon),
                  elevation: 16,
                  style: const TextStyle(color: Colors.deepPurple),
                  onChanged: (T? newValue) {
                    isSelected.value = true;
                    selectedValue.value = newValue;
                    onChanged(newValue);
                    state.didChange(newValue); // Update the form field state
                  },
                  items: items.map<DropdownMenuItem<T>>((T value) {
                    return DropdownMenuItem<T>(
                      value: value,
                      child: itemBuilder(value),
                    );
                  }).toList(),
                  isExpanded: true,
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Text(
                  state.errorText ?? '',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}
