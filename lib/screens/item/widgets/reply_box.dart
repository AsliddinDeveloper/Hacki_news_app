import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';

class ReplyBox extends StatefulWidget {
  const ReplyBox({
    required this.focusNode,
    required this.textEditingController,
    required this.onSendTapped,
    required this.onChanged,
    super.key,
    this.splitViewEnabled = false,
  });

  final bool splitViewEnabled;
  final FocusNode focusNode;
  final TextEditingController textEditingController;
  final VoidCallback onSendTapped;
  final ValueChanged<String> onChanged;

  @override
  _ReplyBoxState createState() => _ReplyBoxState();
}

class _ReplyBoxState extends State<ReplyBox> with ItemActionMixin {
  bool expanded = false;
  double? expandedHeight;

  static const double collapsedHeight = 140;

  @override
  Widget build(BuildContext context) {
    expandedHeight ??= MediaQuery.of(context).size.height;
    return BlocConsumer<EditCubit, EditState>(
      listenWhen: (EditState previous, EditState current) =>
          previous.showReplyBox != current.showReplyBox,
      listener: (BuildContext context, EditState editState) {
        if (editState.showReplyBox) {
          widget.focusNode.requestFocus();
        } else {
          widget.focusNode.unfocus();
        }
      },
      buildWhen: (EditState previous, EditState current) =>
          previous.showReplyBox != current.showReplyBox ||
          previous.itemBeingEdited != current.itemBeingEdited ||
          previous.replyingTo != current.replyingTo,
      builder: (BuildContext context, EditState editState) {
        return BlocBuilder<PostCubit, PostState>(
          builder: (BuildContext context, PostState postState) {
            final Item? replyingTo = editState.replyingTo;
            final bool isLoading = postState.status.isLoading;

            return Padding(
              padding: EdgeInsets.only(
                bottom: expanded
                    ? Dimens.zero
                    : widget.splitViewEnabled
                        ? MediaQuery.of(context).viewInsets.bottom
                        : Dimens.zero,
              ),
              child: AnimatedContainer(
                height: editState.showReplyBox
                    ? (expanded ? expandedHeight : collapsedHeight)
                    : Dimens.zero,
                duration: Durations.ms200,
                decoration: BoxDecoration(
                  boxShadow: <BoxShadow>[
                    if (!context.read<SplitViewCubit>().state.enabled)
                      BoxShadow(
                        color: expanded ? Palette.transparent : Palette.black26,
                        blurRadius: Dimens.pt40,
                      ),
                  ],
                ),
                child: Material(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (context.read<SplitViewCubit>().state.enabled)
                        const Divider(
                          height: Dimens.zero,
                        ),
                      AnimatedContainer(
                        height: expanded ? Dimens.pt40 : Dimens.zero,
                        duration: Durations.ms300,
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: Dimens.pt12,
                                top: Dimens.pt8,
                                bottom: Dimens.pt8,
                              ),
                              child: Text(
                                replyingTo == null
                                    ? 'Editing'
                                    : 'Replying to '
                                        '${replyingTo.by}',
                                style: const TextStyle(color: Palette.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (!isLoading) ...<Widget>[
                            ...<Widget>[
                              if (replyingTo != null)
                                AnimatedOpacity(
                                  opacity:
                                      expanded ? NumSwitch.on : NumSwitch.off,
                                  duration: Durations.ms300,
                                  child: IconButton(
                                    key: const Key('quote'),
                                    icon: const Icon(
                                      FeatherIcons.code,
                                      color: Palette.orange,
                                      size: TextDimens.pt18,
                                    ),
                                    onPressed: expanded ? showTextPopup : null,
                                  ),
                                ),
                              IconButton(
                                key: const Key('expand'),
                                icon: Icon(
                                  expanded
                                      ? FeatherIcons.minimize2
                                      : FeatherIcons.maximize2,
                                  color: Palette.orange,
                                  size: TextDimens.pt18,
                                ),
                                onPressed: () {
                                  setState(() {
                                    expanded = !expanded;
                                  });
                                },
                              ),
                            ],
                            IconButton(
                              key: const Key('close'),
                              icon: const Icon(
                                Icons.close,
                                color: Palette.orange,
                              ),
                              onPressed: () {
                                setState(() {
                                  expanded = false;
                                });

                                final EditState state =
                                    context.read<EditCubit>().state;
                                if (state.replyingTo != null &&
                                    state.text.isNotNullOrEmpty) {
                                  showDialog<void>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) =>
                                        AlertDialog(
                                      title: const Text('Abort editing?'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: context.pop,
                                          child: const Text(
                                            'No',
                                            style: TextStyle(
                                              color: Palette.red,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            context.pop();
                                            onCloseTapped();
                                          },
                                          child: const Text('Yes'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  onCloseTapped();
                                }
                              },
                            ),
                          ],
                          if (isLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: Dimens.pt12,
                                horizontal: Dimens.pt16,
                              ),
                              child: SizedBox(
                                height: Dimens.pt24,
                                width: Dimens.pt24,
                                child: CircularProgressIndicator(
                                  color: Palette.orange,
                                  strokeWidth: Dimens.pt2,
                                ),
                              ),
                            )
                          else
                            IconButton(
                              key: const Key('send'),
                              icon: const Icon(
                                Icons.send,
                                color: Palette.orange,
                              ),
                              onPressed: () {
                                widget.onSendTapped();
                                expanded = false;
                              },
                            ),
                        ],
                      ),
                      Expanded(
                        child: TextField(
                          focusNode: widget.focusNode,
                          controller: widget.textEditingController,
                          expands: true,
                          maxLines: null,
                          decoration: const InputDecoration(
                            alignLabelWithHint: true,
                            contentPadding: EdgeInsets.only(
                              left: Dimens.pt10,
                            ),
                            hintText: '...',
                            hintStyle: TextStyle(
                              color: Palette.grey,
                            ),
                            focusedBorder: InputBorder.none,
                            border: InputBorder.none,
                          ),
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.newline,
                          onChanged: widget.onChanged,
                        ),
                      ),
                      const SizedBox(
                        height: Dimens.pt8,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void onCloseTapped() {
    context.read<EditCubit>().deleteDraft();
    widget.textEditingController.clear();
  }

  void showTextPopup() {
    final Item? replyingTo = context.read<EditCubit>().state.replyingTo;

    if (replyingTo == null) {
      return;
    } else if (replyingTo is Story) {
      final ItemScreenArgs args = ItemScreenArgs(item: replyingTo);
      context.push('/${ItemScreen.routeName}', extra: args);
      expanded = false;
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: Dimens.pt12,
            vertical: Dimens.pt24,
          ),
          contentPadding: EdgeInsets.zero,
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500,
              maxHeight: 500,
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                    left: Dimens.pt12,
                    top: Dimens.pt6,
                  ),
                  child: Row(
                    children: <Widget>[
                      Text(
                        replyingTo.by,
                        style: const TextStyle(
                          fontSize: TextDimens.pt14,
                          color: Palette.grey,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        child: const Text(
                          'View thread',
                          style: TextStyle(
                            fontSize: TextDimens.pt14,
                          ),
                        ),
                        onPressed: () {
                          HapticFeedbackUtil.light();
                          setState(() {
                            expanded = false;
                          });
                          goToItemScreen(
                            args: ItemScreenArgs(
                              item: replyingTo,
                              useCommentCache: true,
                            ),
                            forceNewScreen: true,
                          );
                        },
                      ),
                      TextButton(
                        child: const Text(
                          'Copy all',
                          style: TextStyle(
                            fontSize: TextDimens.pt14,
                          ),
                        ),
                        onPressed: () => FlutterClipboard.copy(
                          replyingTo.text,
                        ).then((_) => HapticFeedbackUtil.selection()),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Palette.orange,
                          size: TextDimens.pt18,
                        ),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: Dimens.pt12,
                        right: Dimens.pt6,
                        top: Dimens.pt6,
                      ),
                      child: SingleChildScrollView(
                        child: ItemText(
                          item: replyingTo,
                          selectable: true,
                          textScaleFactor:
                              MediaQuery.of(context).textScaleFactor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
