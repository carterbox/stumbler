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
      flutterEngine.getPlugins().add(new com.baseflow.geocoding.GeocodingPlugin());
    } catch(Exception e) {
      Log.e(TAG, "Error registering plugin geocoding_android, com.baseflow.geocoding.GeocodingPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.lyokone.location.LocationPlugin());
    } catch(Exception e) {
      Log.e(TAG, "Error registering plugin location, com.lyokone.location.LocationPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new dev.flutternetwork.wifi.wifi_scan.WifiScanPlugin());
    } catch(Exception e) {
      Log.e(TAG, "Error registering plugin wifi_scan, dev.flutternetwork.wifi.wifi_scan.WifiScanPlugin", e);
    }
  }
}
