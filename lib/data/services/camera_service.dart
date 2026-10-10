import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

abstract interface class CameraService {
  Future<CameraController?> initialize();
  Future<String?> capture(CameraController controller);
  Future<String?> chooseFromGallery();
}

class DeviceCameraService implements CameraService {
  DeviceCameraService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<CameraController?> initialize() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return null;
    final controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    try {
      await controller.initialize();
      return controller;
    } catch (_) {
      await controller.dispose();
      rethrow;
    }
  }

  @override
  Future<String?> capture(CameraController controller) async {
    if (!controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return null;
    }
    return (await controller.takePicture()).path;
  }

  @override
  Future<String?> chooseFromGallery() async =>
      (await _picker.pickImage(source: ImageSource.gallery))?.path;
}
