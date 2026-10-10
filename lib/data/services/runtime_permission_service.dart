import 'package:permission_handler/permission_handler.dart'
    as permission_handler;

enum RuntimePermissionState {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

abstract interface class RuntimePermissionService {
  Future<RuntimePermissionState> requestMicrophone();
  Future<RuntimePermissionState> requestCamera();
  Future<bool> openAppSettings();
}

class DeviceRuntimePermissionService implements RuntimePermissionService {
  const DeviceRuntimePermissionService();

  @override
  Future<RuntimePermissionState> requestMicrophone() =>
      _request(permission_handler.Permission.microphone);

  @override
  Future<RuntimePermissionState> requestCamera() =>
      _request(permission_handler.Permission.camera);

  Future<RuntimePermissionState> _request(
    permission_handler.Permission permission,
  ) async {
    final status = await permission.request();
    return switch (status) {
      permission_handler.PermissionStatus.granted =>
        RuntimePermissionState.granted,
      permission_handler.PermissionStatus.permanentlyDenied =>
        RuntimePermissionState.permanentlyDenied,
      permission_handler.PermissionStatus.restricted ||
      permission_handler.PermissionStatus.limited ||
      permission_handler.PermissionStatus.provisional =>
        RuntimePermissionState.restricted,
      permission_handler.PermissionStatus.denied =>
        RuntimePermissionState.denied,
    };
  }

  @override
  Future<bool> openAppSettings() => permission_handler.openAppSettings();
}
