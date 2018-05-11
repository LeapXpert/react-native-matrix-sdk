package com.octopitus.RNMatrixSDK;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;

public class RNMatrixSDKModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;

  public RNMatrixSDKModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }

  @Override
  public String getName() {
    return "RNMatrixSDK";
  }
}
