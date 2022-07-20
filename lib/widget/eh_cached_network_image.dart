import 'package:cached_network_image/cached_network_image.dart';
import 'package:fehviewer/common/controller/image_hide_controller.dart';
import 'package:fehviewer/fehviewer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart' as retry;
import 'package:octo_image/octo_image.dart';

class EhCachedNetworkImage extends StatelessWidget {
  EhCachedNetworkImage({
    Key? key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.progressIndicatorBuilder,
    this.httpHeaders,
    this.onLoadCompleted,
    this.checkHide = false,
  }) : super(key: key);

  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final Map<String, String>? httpHeaders;

  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;
  final ProgressIndicatorBuilder? progressIndicatorBuilder;
  final VoidCallback? onLoadCompleted;
  final bool checkHide;

  final ImageHideController imageHideController = Get.find();

  ImageWidgetBuilder get imageWidgetBuilder => (context, imageProvider) {
        final _image = OctoImage(
          image: imageProvider,
          width: width,
          height: height,
          fit: fit,
        );
        if (checkHide) {
          return FutureBuilder<bool>(
              future: imageHideController.checkPHashHide(imageUrl),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return _image;
                  }
                  final showCustomWidget = snapshot.data ?? false;
                  return showCustomWidget
                      ? Container(
                          child: Center(
                            child: Icon(
                              CupertinoIcons.xmark_shield_fill,
                              size: 32,
                              color: CupertinoDynamicColor.resolve(
                                  CupertinoColors.systemGrey3, context),
                            ),
                          ),
                        )
                      : _image;
                } else {
                  return placeholder?.call(context, imageUrl) ??
                      Container(
                        alignment: Alignment.center,
                        child: const CupertinoActivityIndicator(),
                      );
                  // return _image;
                }
              });
        } else {
          return _image;
        }
      };

  @override
  Widget build(BuildContext context) {
    final _httpHeaders = {
      'Cookie': Global.profile.user.cookie,
      'Host': Uri.parse(imageUrl).host,
      'User-Agent': EHConst.CHROME_USER_AGENT,
      'Accept-Encoding': 'gzip, deflate, br'
    };
    if (httpHeaders != null) {
      _httpHeaders.addAll(httpHeaders!);
    }

    final image = CachedNetworkImage(
      cacheManager: imageCacheManager,
      imageBuilder: imageWidgetBuilder,
      httpHeaders: _httpHeaders,
      width: width,
      height: height,
      fit: fit,
      imageUrl: imageUrl.dfUrl,
      placeholder: placeholder,
      errorWidget: errorWidget,
      progressIndicatorBuilder: progressIndicatorBuilder,
    );

    return image;
  }

  Widget _octoPlaceholderBuilder(BuildContext context) {
    return placeholder!(context, imageUrl);
  }

  Widget _octoProgressIndicatorBuilder(
    BuildContext context,
    ImageChunkEvent? progress,
  ) {
    int? totalSize;
    var downloaded = 0;
    if (progress != null) {
      totalSize = progress.expectedTotalBytes;
      downloaded = progress.cumulativeBytesLoaded;
    }
    return progressIndicatorBuilder!(
        context, imageUrl, DownloadProgress(imageUrl, totalSize, downloaded));
  }

  Widget _octoErrorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return errorWidget!(context, imageUrl, error);
  }
}

final client = retry.RetryClient(
  http.Client(),
);

final imageCacheManager = CacheManager(
  Config(
    'CachedNetworkImage',
    fileService: HttpFileService(
      httpClient: client,
    ),
  ),
);
