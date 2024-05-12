// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$databaseHash() => r'b74fb084b7e62bd0d1caf5cfdaf3c871e0382671';

/// See also [database].
@ProviderFor(database)
final databaseProvider = AutoDisposeProvider<ReportDatabase>.internal(
  database,
  name: r'databaseProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$databaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DatabaseRef = AutoDisposeProviderRef<ReportDatabase>;
String _$reportListHash() => r'f5f72568d9040bad14bb7c1a405950a489bdfecb';

/// See also [ReportList].
@ProviderFor(ReportList)
final reportListProvider =
    AutoDisposeAsyncNotifierProvider<ReportList, List<Report>>.internal(
  ReportList.new,
  name: r'reportListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$reportListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ReportList = AutoDisposeAsyncNotifier<List<Report>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, inference_failure_on_uninitialized_variable, inference_failure_on_function_return_type, inference_failure_on_untyped_parameter, deprecated_member_use_from_same_package
