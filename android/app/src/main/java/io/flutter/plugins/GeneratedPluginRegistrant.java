package io.flutter.plugins;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;
import io.flutter.Log;

import io.flutter.embedding.engine.FlutterEngine;

/**
 * Generated file. Do not edit.
 * This file is generated by the Flutter tool based on the
 * plugins that support the Android platform.
 */
@Keep
public final class GeneratedPluginRegistrant {
  private static final String TAG = "GeneratedPluginRegistrant";
  public static void registerWith(@NonNull FlutterEngine flutterEngine) {
    try {
      flutterEngine.getPlugins().add(new com.pravera.flutter_foreground_task.FlutterForegroundTaskPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin flutter_foreground_task, com.pravera.flutter_foreground_task.FlutterForegroundTaskPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.baseflow.geocoding.GeocodingPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin geocoding_android, com.baseflow.geocoding.GeocodingPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.pathprovider.PathProviderPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin path_provider_android, io.flutter.plugins.pathprovider.PathProviderPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin shared_preferences_android, io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new eu.simonbinder.sqlite3_flutter_libs.Sqlite3FlutterLibsPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin sqlite3_flutter_libs, eu.simonbinder.sqlite3_flutter_libs.Sqlite3FlutterLibsPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new dev.flutternetwork.wifi.wifi_scan.WifiScanPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin wifi_scan, dev.flutternetwork.wifi.wifi_scan.WifiScanPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new dev.fluttercommunity.workmanager.WorkmanagerPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin workmanager, dev.fluttercommunity.workmanager.WorkmanagerPlugin", e);
    }
  }
}
