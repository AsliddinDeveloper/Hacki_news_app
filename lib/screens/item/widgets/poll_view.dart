import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:hacki/blocs/auth/auth_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';

class PollView extends StatefulWidget {
  const PollView({super.key});

  @override
  State<PollView> createState() => _PollViewState();
}

class _PollViewState extends State<PollView> with ItemActionMixin {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PollCubit, PollState>(
      builder: (BuildContext context, PollState state) {
        return Column(
          children: <Widget>[
            const SizedBox(
              height: Dimens.pt24,
            ),
            if (state.status == Status.inProgress) ...<Widget>[
              const LinearProgressIndicator(),
              const SizedBox(
                height: Dimens.pt24,
              ),
            ] else ...<Widget>[
              Row(
                children: <Widget>[
                  const SizedBox(
                    width: Dimens.pt24,
                  ),
                  Text(
                    'Total votes: ${state.totalVotes}',
                    style: const TextStyle(
                      fontSize: TextDimens.pt14,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: Dimens.pt12,
              ),
            ],
            for (final PollOption option in state.pollOptions)
              FadeIn(
                child: BlocProvider<VoteCubit>(
                  create: (BuildContext context) => VoteCubit(
                    item: option,
                    authBloc: context.read<AuthBloc>(),
                  ),
                  child: BlocConsumer<VoteCubit, VoteState>(
                    listenWhen: (VoteState previous, VoteState current) {
                      return previous.status != current.status;
                    },
                    listener: (BuildContext context, VoteState voteState) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      if (voteState.status == VoteStatus.submitted) {
                        showSnackBar(
                          content: 'Vote submitted successfully.',
                        );
                      } else if (voteState.status == VoteStatus.canceled) {
                        showSnackBar(content: 'Vote canceled.');
                      } else if (voteState.status == VoteStatus.failure) {
                        showErrorSnackBar();
                      } else if (voteState.status ==
                          VoteStatus.failureKarmaBelowThreshold) {
                        showSnackBar(
                          content: "You can't downvote because"
                              ' you are karmaly broke.',
                        );
                      } else if (voteState.status ==
                          VoteStatus.failureNotLoggedIn) {
                        showSnackBar(
                          content: 'Not logged in, no voting! (;｀O´)o',
                          action: onLoginTapped,
                          label: 'Log in',
                        );
                      } else if (voteState.status ==
                          VoteStatus.failureBeHumble) {
                        showSnackBar(
                          content: 'No voting on your own post! (;｀O´)o',
                        );
                      }
                    },
                    builder: (BuildContext context, VoteState voteState) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          left: Dimens.pt12,
                          right: Dimens.pt24,
                          bottom: Dimens.pt4,
                        ),
                        child: Row(
                          children: <Widget>[
                            IconButton(
                              onPressed: () {
                                HapticFeedbackUtil.light();
                                context.read<VoteCubit>().upvote();
                              },
                              icon: Icon(
                                Icons.arrow_drop_up,
                                color: voteState.vote == Vote.up
                                    ? Palette.orange
                                    : Palette.grey,
                                size: TextDimens.pt36,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    option.text,
                                  ),
                                  Text(
                                    '''${option.score} vote${option.score > 1 ? 's' : ''}''',
                                    style: const TextStyle(
                                      color: Palette.grey,
                                      fontSize: TextDimens.pt12,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: Dimens.pt4,
                                  ),
                                  LinearProgressIndicator(
                                    value: option.ratio,
                                    color: Palette.deepOrange,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
