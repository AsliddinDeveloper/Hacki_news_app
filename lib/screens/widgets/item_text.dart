import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';

class ItemText extends StatelessWidget {
  const ItemText({
    required this.item,
    required this.textScaleFactor,
    required this.selectable,
    super.key,
    this.onTap,
  });

  final Item item;
  final double textScaleFactor;
  final bool selectable;

  /// Reserved for collapsing a comment tile when
  /// [CollapseModePreference] is enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final PreferenceState prefState = context.read<PreferenceCubit>().state;
    final TextStyle style = TextStyle(
      fontSize: prefState.fontSize.fontSize,
    );
    final TextStyle linkStyle = TextStyle(
      fontSize: prefState.fontSize.fontSize,
      decoration: TextDecoration.underline,
      color: Palette.orange,
    );

    void onSelectionChanged(
      TextSelection selection,
      SelectionChangedCause? cause,
    ) {
      if (cause == SelectionChangedCause.longPress &&
          selection.baseOffset != selection.extentOffset) {
        context.tryRead<CollapseCubit>()?.lock();
      }
    }

    if (selectable && item is Buildable) {
      return SelectableText.rich(
        buildTextSpan(
          (item as Buildable).elements,
          style: style,
          linkStyle: linkStyle,
          onOpen: (LinkableElement link) => LinkUtil.launch(link.url),
        ),
        onTap: onTap,
        textScaleFactor: textScaleFactor,
        onSelectionChanged: onSelectionChanged,
        contextMenuBuilder: (
          BuildContext context,
          EditableTextState editableTextState,
        ) =>
            contextMenuBuilder(
          context,
          editableTextState,
          item: item,
        ),
        semanticsLabel: item.text,
      );
    } else {
      if (item is Buildable) {
        return InkWell(
          child: Text.rich(
            buildTextSpan(
              (item as Buildable).elements,
              style: style,
              linkStyle: linkStyle,
              onOpen: (LinkableElement link) => LinkUtil.launch(link.url),
            ),
            textScaleFactor: textScaleFactor,
            semanticsLabel: item.text,
          ),
        );
      } else {
        return InkWell(
          child: Linkify(
            text: item.text,
            textScaleFactor: textScaleFactor,
            style: style,
            linkStyle: linkStyle,
            onOpen: (LinkableElement link) => LinkUtil.launch(link.url),
          ),
        );
      }
    }
  }
}
