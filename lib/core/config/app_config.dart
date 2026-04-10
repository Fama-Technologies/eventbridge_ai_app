enum Environment { dev, staging, production }

class AppConfig {
  static late Environment _environment;

  static Environment get environment => _environment;

  static void init(Environment env) {
    _environment = env;
  }

  static bool get isProduction => _environment == Environment.production;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isDev => _environment == Environment.dev;

  static String get firebaseProjectId {
    switch (_environment) {
      case Environment.dev:
      case Environment.staging:
        return 'eventbridge-34569';
      case Environment.production:
        return 'eventbridge-34569';
    }
  }

  /// Prefix for Firestore collections based on environment
  static String get collectionPrefix {
    switch (_environment) {
      case Environment.dev:
        return 'dev_';
      case Environment.staging:
        return 'staging_';
      case Environment.production:
        return '';
    }
  }
}
