import 'package:get_storage/get_storage.dart';  
  

class MemoryService {
  static final MemoryService _instance = MemoryService._internal();
  static MemoryService get instance => _instance;

  GetStorage? _storage;
  bool _initialized = false;

  MemoryService._internal();

  Future<void> initialize() async {
    if (_initialized) return; // ✅ Do nothing if already initialized
    await GetStorage.init('uae-pass-app');
    _storage = GetStorage('uae-pass-app');
    _initialized = true;
  }

  String? get accessCode => _storage?.read<String>('accessCode');
  set accessCode(String? value) => _storage?.write('accessCode', value);
}
