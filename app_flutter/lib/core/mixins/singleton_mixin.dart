mixin SingletonMixin {
  static final Map<Type, dynamic> _instances = {};

  static T getInstance<T>(T Function() factory) {
    if (!_instances.containsKey(T)) {
      _instances[T] = factory();
    }
    return _instances[T] as T;
  }

  static void clearInstance<T>() {
    _instances.remove(T);
  }

  static void clearAllInstances() {
    _instances.clear();
  }
}

abstract class SingletonService {
  SingletonService._();
}
