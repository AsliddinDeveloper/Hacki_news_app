import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hacki/config/custom_router.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/screens.dart'
    show ItemScreen, ItemScreenArgs, WebViewScreen;
import 'package:hacki/styles/styles.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class LinkUtil {
  static final ChromeSafariBrowser _browser = ChromeSafariBrowser();

  static void launchInExternalBrowser(
    String link,
  ) {
    final Uri uri = Uri.parse(link);
    launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  static void launch(
    String link, {
    bool useReader = false,
    bool offlineReading = false,
    bool useHackiForHnLink = true,
  }) {
    if (offlineReading) {
      locator
          .get<OfflineRepository>()
          .hasCachedWebPage(url: link)
          .then((bool cached) {
        if (cached) {
          router.push(
            '/${WebViewScreen.routeName}',
            extra: link,
          );
        }
      });

      return;
    }

    if (useHackiForHnLink && link.isStoryLink) {
      _onStoryLinkTapped(link);
      return;
    }

    final Uri uri = Uri.parse(link);
    canLaunchUrl(uri).then((bool val) {
      if (val) {
        if (link.contains('http')) {
          if (Platform.isAndroid) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            _browser
                .open(
                  url: uri,
                  options: ChromeSafariBrowserClassOptions(
                    ios: IOSSafariOptions(
                      entersReaderIfAvailable: useReader,
                      preferredControlTintColor: Palette.orange,
                    ),
                  ),
                )
                .onError((_, __) => launchUrl(uri));
          }
        } else {
          launchUrl(uri);
        }
      }
    });
  }

  static Future<void> _onStoryLinkTapped(String link) async {
    final int? id = link.itemId;
    if (id != null) {
      await locator
          .get<StoriesRepository>()
          .fetchItem(id: id)
          .then((Item? item) {
        if (item != null) {
          router.push(
            '/${ItemScreen.routeName}',
            extra: ItemScreenArgs(item: item),
          );
        }
      });
    } else {
      launch(link, useHackiForHnLink: false);
    }
  }
}
