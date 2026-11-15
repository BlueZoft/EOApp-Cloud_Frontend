{{flutter_js}}
{{flutter_build_config}}

// Ship the renderer with the app instead of requiring Google's CDN at runtime.
_flutter.loader.load({
  config: { canvasKitBaseUrl: 'canvaskit/' }
});
