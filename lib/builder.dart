import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generator/prefs_generator.dart';

Builder typedPrefsBuilder(BuilderOptions options) =>
    SharedPartBuilder([PrefsGenerator()], 'typed_prefs');
