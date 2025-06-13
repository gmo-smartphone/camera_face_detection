import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../face_camera.dart';
import 'controllers/face_camera_state.dart';
import 'paints/face_painter.dart';
import 'paints/hole_painter.dart';
import 'res/builders.dart';

class CameraFaceDetection extends StatefulWidget {
  /// Use this pass a message above the camera.
  final String? message;

  /// Style applied to the message widget.
  final TextStyle messageStyle;

  /// Use this to build custom widgets for capture control.
  final CaptureControlBuilder? captureControlBuilder;

  /// Use this to render a custom widget for camera lens control.
  final Widget? lensControlIcon;

  /// Use this to build custom widgets for flash control based on camera flash mode.
  final FlashControlBuilder? flashControlBuilder;

  /// Use this to build custom messages based on face position.
  final MessageBuilder? messageBuilder;

  /// Use this to change the shape of the face indicator.
  final IndicatorShape indicatorShape;

  /// Use this to pass an asset image when IndicatorShape is set to image.
  final String? indicatorAssetImage;

  /// Use this to build custom widgets for the face indicator
  final IndicatorBuilder? indicatorBuilder;

  /// Set true to automatically disable capture control widget when no face is detected.
  final bool autoDisableCaptureControl;

  /// The controller for the [CameraFaceDetection] widget.
  final FaceCameraController controller;

  const CameraFaceDetection({
    required this.controller,
    this.message,
    this.messageStyle = const TextStyle(
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w400,
    ),
    this.captureControlBuilder,
    this.lensControlIcon,
    this.flashControlBuilder,
    this.messageBuilder,
    this.indicatorShape = IndicatorShape.defaultShape,
    this.indicatorAssetImage,
    this.indicatorBuilder,
    this.autoDisableCaptureControl = false,
    super.key,
  }) : assert(
            indicatorShape != IndicatorShape.image ||
                indicatorAssetImage != null,
            'IndicatorAssetImage must be provided when IndicatorShape is set to image.');

  @override
  State<CameraFaceDetection> createState() => _CameraFaceDetectionState();
}

class _CameraFaceDetectionState extends State<CameraFaceDetection>
    with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    widget.controller.initialize();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.stopImageStream();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      widget.controller.stopImageStream();
    } else if (state == AppLifecycleState.paused) {
      widget.controller.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      widget.controller.startImageStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return ValueListenableBuilder<FaceCameraState>(
      valueListenable: widget.controller,
      builder: (BuildContext context, FaceCameraState value, Widget? child) {
        final CameraController? cameraController = value.cameraController;
        final isIndicator = widget.indicatorShape != IndicatorShape.none;

        return Stack(
          alignment: Alignment.center,
          children: [
            if (cameraController != null &&
                cameraController.value.isInitialized) ...[
              Transform.scale(
                scale: 1.0,
                child: AspectRatio(
                  aspectRatio: size.aspectRatio,
                  child: OverflowBox(
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.fitHeight,
                      child: SizedBox(
                        width: size.width,
                        height: size.width * cameraController.value.aspectRatio,
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            _cameraDisplayWidget(value),
                            if (value.detectedFace != null && isIndicator) ...[
                              SizedBox(
                                width:
                                    cameraController.value.previewSize!.width,
                                height:
                                    cameraController.value.previewSize!.height,
                                child: widget.indicatorBuilder?.call(
                                      context,
                                      value.detectedFace,
                                      Size(
                                        cameraController
                                            .value.previewSize!.height,
                                        cameraController
                                            .value.previewSize!.width,
                                      ),
                                    ) ??
                                    CustomPaint(
                                      painter: FacePainter(
                                        face: value.detectedFace!.face,
                                        indicatorShape: widget.indicatorShape,
                                        indicatorAssetImage:
                                            widget.indicatorAssetImage,
                                        imageSize: Size(
                                          cameraController
                                              .value.previewSize!.height,
                                          cameraController
                                              .value.previewSize!.width,
                                        ),
                                      ),
                                    ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ] else ...[
              const Text(
                'No Camera Detected',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              CustomPaint(
                size: size,
                painter: HolePainter(),
              )
            ],
          ],
        );
      },
    );
  }

  /// Render camera.
  Widget _cameraDisplayWidget(FaceCameraState value) {
    final CameraController? cameraController = value.cameraController;
    if (cameraController != null && cameraController.value.isInitialized) {
      return CameraPreview(
        cameraController,
        child: Builder(
          builder: (context) {
            if (widget.messageBuilder != null) {
              return widget.messageBuilder!.call(context, value.detectedFace);
            }
            if (widget.message != null) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 55, vertical: 15),
                child: Text(
                  widget.message!,
                  textAlign: TextAlign.center,
                  style: widget.messageStyle,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
