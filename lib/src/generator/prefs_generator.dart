import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import '../annotations.dart';

class PrefsGenerator extends GeneratorForAnnotation<Prefs> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@Prefs can only be applied to classes.',
        element: element,
      );
    }

    final className = element.displayName;
    final accessorName = annotation.peek('accessorName')?.stringValue;
    final keysName = annotation.peek('keysName')?.stringValue;
    final classProtected = annotation.peek('protected')?.boolValue ?? false;
    final resolvedAccessorName = accessorName ?? '${className}Store';
    final resolvedKeysName = keysName ?? '${className}Keys';
    final extensionName = '${className}TypedPrefsExtension';
    final extensionGetter = _lowerCamel(className);

    final allConst = element.fields
        .where((field) => !field.isSynthetic)
        .where((field) => field.isStatic && field.isConst)
        .toList();

    final prefFields = allConst
        .where(_isPrefKeyField)
        .map((field) => _readField(field, classProtected: classProtected))
        .toList();
    final groupFields = allConst
        .where(_isGroupKeyField)
        .map(_readGroupField)
        .toList();

    if (prefFields.isEmpty && groupFields.isEmpty) {
      throw InvalidGenerationSourceError(
        'Class $className does not declare any static const PrefKey '
        'or PrefGroupKey fields.',
        element: element,
      );
    }

    if (prefFields.isNotEmpty) {
      _checkDuplicateKeys(prefFields, className, element);
    }

    final buffer = StringBuffer();

    // Keys class — only when there are direct pref fields.
    if (prefFields.isNotEmpty) {
      buffer.writeln('abstract final class $resolvedKeysName {');

      for (final field in prefFields) {
        buffer
          ..writeln(
            '  static const ${field.name} = PreferenceKey<${field.typeName}>(',
          )
          ..writeln("    key: '${field.storageKey}',")
          ..writeln(
            '    storage: PreferenceStorage.${field.protected ? 'secure' : 'shared'},',
          );

        if (field.defaultValueCode != null) {
          buffer.writeln('    defaultValue: ${field.defaultValueCode},');
        }

        if (field.description.isNotEmpty) {
          buffer.writeln("    description: '${_escape(field.description)}',");
        }

        if (field.serializerCode != null) {
          buffer.writeln('    serializer: ${field.serializerCode},');
        }

        buffer.writeln('  );');
      }

      buffer
        ..writeln('}')
        ..writeln();
    }

    // Accessor class — always generated.
    buffer
      ..writeln('class $resolvedAccessorName {')
      ..writeln('  final PreferencesService _service;')
      ..writeln()
      ..writeln('  const $resolvedAccessorName(this._service);')
      ..writeln();

    for (final group in groupFields) {
      buffer
        ..writeln('  ${group.accessorClassName} get ${group.fieldName} =>')
        ..writeln('      ${group.accessorClassName}(_service);')
        ..writeln();
    }

    for (final field in prefFields) {
      final pascal = _upperCamel(field.name);
      buffer
        ..writeln('  TypedPrefAccessor<${field.typeName}> get ${field.name} =>')
        ..writeln(
          '      TypedPrefAccessor<${field.typeName}>(_service, $resolvedKeysName.${field.name});',
        )
        ..writeln()
        ..writeln(field.getterCode(pascal))
        ..writeln(
          '  Future<void> set$pascal(${field.typeName} value) => ${field.name}.set(value);',
        )
        ..writeln('  Future<void> remove$pascal() => ${field.name}.remove();')
        ..writeln(field.watcherCode(pascal))
        ..writeln();
    }

    buffer
      ..writeln('}')
      ..writeln()
      ..writeln('extension $extensionName on PreferencesService {')
      ..writeln(
        '  $resolvedAccessorName get $extensionGetter => $resolvedAccessorName(this);',
      )
      ..writeln('}');

    return buffer.toString();
  }

  void _checkDuplicateKeys(
    List<_GeneratedField> fields,
    String className,
    Element element,
  ) {
    final seen = <String>{};
    for (final field in fields) {
      if (!seen.add(field.storageKey)) {
        throw InvalidGenerationSourceError(
          'Duplicate storage key "${field.storageKey}" in class $className. '
          'Use @Pref(key: \'...\') to assign unique keys.',
          element: element,
        );
      }
    }
  }

  static const _prefKeyChecker = TypeChecker.typeNamed(PrefKey);
  static const _prefGroupKeyChecker = TypeChecker.typeNamed(PrefGroupKey);
  static const _prefAnnotationChecker = TypeChecker.typeNamed(Pref);
  static const _prefsAnnotationChecker = TypeChecker.typeNamed(Prefs);

  bool _isPrefKeyField(FieldElement field) {
    final fieldType = field.type;
    return fieldType is InterfaceType &&
        _prefKeyChecker.isAssignableFromType(fieldType);
  }

  bool _isGroupKeyField(FieldElement field) {
    final fieldType = field.type;
    return fieldType is InterfaceType &&
        _prefGroupKeyChecker.isAssignableFromType(fieldType);
  }

  _GeneratedGroupField _readGroupField(FieldElement field) {
    final type = field.type;
    if (type is! InterfaceType || type.typeArguments.length != 1) {
      throw InvalidGenerationSourceError(
        'PrefGroupKey field ${field.displayName} must have exactly one type argument.',
        element: field,
      );
    }

    final groupType = type.typeArguments.single;
    if (groupType is! InterfaceType) {
      throw InvalidGenerationSourceError(
        'PrefGroupKey<T>: T must be a class annotated with @Prefs.',
        element: field,
      );
    }

    final referencedClass = groupType.element;
    final prefsAnnotation = _prefsAnnotationChecker.firstAnnotationOf(
      referencedClass,
    );

    if (prefsAnnotation == null) {
      throw InvalidGenerationSourceError(
        'PrefGroupKey<${referencedClass.displayName}> references a class '
        'that is not annotated with @Prefs.',
        element: field,
      );
    }

    final accessorName =
        ConstantReader(prefsAnnotation).peek('accessorName')?.stringValue ??
        '${referencedClass.displayName}Store';

    return _GeneratedGroupField(
      fieldName: field.displayName,
      accessorClassName: accessorName,
    );
  }

  _GeneratedField _readField(
    FieldElement field, {
    bool classProtected = false,
  }) {
    final type = field.type;
    if (type is! InterfaceType || type.typeArguments.length != 1) {
      throw InvalidGenerationSourceError(
        'PrefKey field ${field.displayName} must have exactly one type argument.',
        element: field,
      );
    }

    final prefAnnotation = _prefAnnotationChecker.firstAnnotationOf(field);
    final prefReader = prefAnnotation == null
        ? null
        : ConstantReader(prefAnnotation);
    final prefType = type.typeArguments.single;
    final typeName = prefType.getDisplayString();
    final fieldName = field.displayName;
    final storageKey =
        prefReader?.peek('key')?.stringValue ?? _snakeCase(fieldName);
    final description = prefReader?.peek('description')?.stringValue ?? '';
    final isProtected =
        classProtected || (prefReader?.peek('protected')?.boolValue ?? false);
    final serializerType = prefReader?.peek('serializer')?.typeValue;
    final defaultValueObject = prefReader?.peek('defaultValue')?.objectValue;

    _validateType(prefType, serializerType, field);
    final hasDefaultValue = defaultValueObject != null;
    final isNullable = prefType.nullabilitySuffix == NullabilitySuffix.question;

    return _GeneratedField(
      name: fieldName,
      typeName: typeName,
      readTypeName: hasDefaultValue || isNullable ? typeName : '$typeName?',
      hasDefaultValue: hasDefaultValue,
      isNullable: isNullable,
      storageKey: storageKey,
      protected: isProtected,
      description: description,
      defaultValueCode: defaultValueObject == null
          ? null
          : _dartObjectToCode(defaultValueObject),
      serializerCode: _serializerExpression(prefType, serializerType),
    );
  }

  void _validateType(
    DartType prefType,
    DartType? serializerType,
    FieldElement field,
  ) {
    if (serializerType != null) return;
    if (prefType.element is EnumElement) return;

    final baseType = prefType.getDisplayString().replaceFirst('?', '');
    const builtInSerialized = {
      'DateTime',
      'Duration',
      'Uri',
      'BigInt',
      'List<String>',
      'Map<String, String>',
    };
    const nativePrimitives = {'String', 'bool', 'int', 'double'};

    if (!nativePrimitives.contains(baseType) &&
        !builtInSerialized.contains(baseType)) {
      throw InvalidGenerationSourceError(
        'Type "$baseType" for field "${field.displayName}" is not supported. '
        'Add @Pref(serializer: YourSerializer) or use a built-in supported type '
        '(String, bool, int, double, DateTime, Duration, Uri, BigInt, '
        'List<String>, Map<String, String>, or an enum).',
        element: field,
      );
    }
  }

  String? _serializerExpression(DartType prefType, DartType? serializerType) {
    if (serializerType != null) {
      return '${serializerType.getDisplayString()}()';
    }

    final typeName = prefType.getDisplayString().replaceFirst('?', '');
    if (prefType.element is EnumElement) {
      return 'EnumPrefSerializer<$typeName>($typeName.values)';
    }
    if (typeName == 'DateTime') {
      return 'DateTimePrefSerializer()';
    }
    if (typeName == 'Duration') {
      return 'DurationPrefSerializer()';
    }
    if (typeName == 'Uri') {
      return 'UriPrefSerializer()';
    }
    if (typeName == 'BigInt') {
      return 'BigIntPrefSerializer()';
    }
    if (typeName == 'List<String>') {
      return 'StringListPrefSerializer()';
    }
    if (typeName == 'Map<String, String>') {
      return 'StringMapPrefSerializer()';
    }

    return null;
  }

  String _dartObjectToCode(DartObject object) {
    if (object.isNull) {
      return 'null';
    }

    final stringValue = object.toStringValue();
    if (stringValue != null) {
      return "'${_escape(stringValue)}'";
    }

    final boolValue = object.toBoolValue();
    if (boolValue != null) {
      return boolValue.toString();
    }

    final intValue = object.toIntValue();
    if (intValue != null) {
      return intValue.toString();
    }

    final doubleValue = object.toDoubleValue();
    if (doubleValue != null) {
      return doubleValue.toString();
    }

    final listValue = object.toListValue();
    if (listValue != null) {
      final values = listValue.map(_dartObjectToCode).join(', ');
      return '[$values]';
    }

    final mapValue = object.toMapValue();
    if (mapValue != null) {
      final entries = mapValue.entries
          .map(
            (entry) =>
                '${_dartObjectToCode(entry.key!)}: ${_dartObjectToCode(entry.value!)}',
          )
          .join(', ');
      return '{$entries}';
    }

    final typeValue = object.toTypeValue();
    if (typeValue != null) {
      return typeValue.getDisplayString();
    }

    final enumType = object.type?.element;
    final enumIndex = object.getField('index')?.toIntValue();
    if (enumType is EnumElement && enumIndex != null) {
      final enumValue = enumType.fields
          .where((field) => field.isEnumConstant)
          .elementAt(enumIndex);
      return '${enumType.displayName}.${enumValue.displayName}';
    }

    throw InvalidGenerationSourceError(
      'Unsupported defaultValue expression for generated preferences.',
    );
  }

  String _escape(String value) =>
      value.replaceAll('\\', '\\\\').replaceAll("'", "\\'");

  String _lowerCamel(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toLowerCase() + value.substring(1);
  }

  String _snakeCase(String value) {
    final buffer = StringBuffer();
    for (var index = 0; index < value.length; index++) {
      final char = value[index];
      final isUpperCase =
          char.toUpperCase() == char && char.toLowerCase() != char;
      if (isUpperCase && index > 0) {
        buffer.write('_');
      }
      buffer.write(char.toLowerCase());
    }
    return buffer.toString();
  }

  String _upperCamel(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() + value.substring(1);
  }
}

class _GeneratedField {
  final String name;
  final String typeName;
  final String readTypeName;
  final bool hasDefaultValue;
  final bool isNullable;
  final String storageKey;
  final bool protected;
  final String description;
  final String? defaultValueCode;
  final String? serializerCode;

  const _GeneratedField({
    required this.name,
    required this.typeName,
    required this.readTypeName,
    required this.hasDefaultValue,
    required this.isNullable,
    required this.storageKey,
    required this.protected,
    required this.description,
    required this.defaultValueCode,
    required this.serializerCode,
  });

  String getterCode(String pascalName) {
    if (!hasDefaultValue) {
      return '  Future<$readTypeName> get$pascalName() => $name.get();';
    }

    return '  Future<$readTypeName> get$pascalName() async => '
        '(await $name.get()) ?? $defaultValueCode;';
  }

  String watcherCode(String pascalName) {
    if (!hasDefaultValue) {
      return '  Stream<$readTypeName> watch$pascalName() => $name.watch();';
    }

    return '  Stream<$readTypeName> watch$pascalName() => '
        '$name.watch().map((value) => value ?? $defaultValueCode);';
  }

}

class _GeneratedGroupField {
  final String fieldName;
  final String accessorClassName;

  const _GeneratedGroupField({
    required this.fieldName,
    required this.accessorClassName,
  });
}



