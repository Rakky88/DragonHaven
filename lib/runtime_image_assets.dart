/// Resolves logical artwork paths to the smaller, pixel-identical runtime file.
/// Saved catalog identifiers and source artwork names do not change.
String runtimeImageAsset(String path) => losslessPngAssets.contains(path)
    ? '${path.substring(0, path.length - 4)}.webp'
    : path;

// Generated from the reviewed lossless asset manifest.
const losslessPngAssets = <String>{
  'assets/images/egg_altar/altar_grove.png',
  'assets/images/events/harvestmoon/trial_background.png',
  'assets/images/events/sunwake/trial_background.png',
  'assets/images/ui/dragon_school.png',
};
