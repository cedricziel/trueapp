import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

/// Finders for the Cupertino form rows used across the server screens.
///
/// The screens build their inputs with [CupertinoTextFormFieldRow] and label
/// them through the row's `prefix`. Addressing fields by that label keeps tests
/// readable and, more importantly, stable: positional lookups such as
/// `find.byType(CupertinoTextField).first` silently start editing a different
/// field as soon as a row is added or reordered.

/// The form row carrying [label] as its prefix.
Finder formRowWithLabel(String label) {
  return find.ancestor(
    of: find.text(label),
    matching: find.byType(CupertinoTextFormFieldRow),
  );
}

/// The editable text of the form row labelled [label].
///
/// Pass this to [WidgetTester.enterText], which needs the [EditableText]
/// itself rather than one of its ancestors.
Finder formFieldWithLabel(String label) {
  return find.descendant(
    of: formRowWithLabel(label),
    matching: find.byType(EditableText),
  );
}
