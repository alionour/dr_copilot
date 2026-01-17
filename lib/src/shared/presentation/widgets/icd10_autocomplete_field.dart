import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/services/icd10_service.dart';

class ICD10AutocompleteField extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String?>? onChanged;
  final String? labelText;
  final bool enabled;

  const ICD10AutocompleteField({
    super.key,
    this.initialValue,
    this.onChanged,
    this.labelText,
    this.enabled = true,
  });

  @override
  State<ICD10AutocompleteField> createState() => _ICD10AutocompleteFieldState();
}

class _ICD10AutocompleteFieldState extends State<ICD10AutocompleteField> {
  final ICD10Service _icd10Service = ICD10Service();
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _icd10Service.loadCodes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<ICD10Code>(
      initialValue: TextEditingValue(text: widget.initialValue ?? ''),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<ICD10Code>.empty();
        }
        return _icd10Service.searchCodes(textEditingValue.text);
      },
      displayStringForOption: (ICD10Code option) => option.toString(),
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: widget.labelText ?? 'diagnosisCode'.tr(),
            hintText: 'searchDiagnosisCodes'.tr(),
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.search),
          ),
          onChanged: (value) {
            widget.onChanged?.call(value);
          },
        );
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<ICD10Code> onSelected,
        Iterable<ICD10Code> options,
      ) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 400),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final ICD10Code option = options.elementAt(index);
                  return ListTile(
                    title: Text(
                      option.code,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      option.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      onSelected(option);
                      widget.onChanged?.call(option.toString());
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
      onSelected: (ICD10Code selection) {
        widget.onChanged?.call(selection.toString());
      },
    );
  }
}
