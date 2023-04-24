// lib/env/env.dart
// run flutter pub run build_runner build
import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'OPENAI_API_KEY', obfuscate: true)
  static final String openApiKey = _Env.openApiKey;
  @EnviedField(varName: 'MONOGDB_CONN_STR', obfuscate: true)
  static final String mongoDbConnStr = _Env.mongoDbConnStr;
}