
# react-native-matrix-sdk

## Getting started

`$ npm install react-native-matrix-sdk --save`

### Mostly automatic installation

`$ react-native link react-native-matrix-sdk`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-matrix-sdk` and add `RNMatrixSdk.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNMatrixSdk.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.reactlibrary.RNMatrixSdkPackage;` to the imports at the top of the file
  - Add `new RNMatrixSdkPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-matrix-sdk'
  	project(':react-native-matrix-sdk').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-matrix-sdk/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-matrix-sdk')
  	```

#### Windows
[Read it! :D](https://github.com/ReactWindows/react-native)

1. In Visual Studio add the `RNMatrixSdk.sln` in `node_modules/react-native-matrix-sdk/windows/RNMatrixSdk.sln` folder to their solution, reference from their app.
2. Open up your `MainPage.cs` app
  - Add `using Matrix.Sdk.RNMatrixSdk;` to the usings at the top of the file
  - Add `new RNMatrixSdkPackage()` to the `List<IReactPackage>` returned by the `Packages` method


## Usage
```javascript
import RNMatrixSdk from 'react-native-matrix-sdk';

// TODO: What to do with the module?
RNMatrixSdk;
```
  