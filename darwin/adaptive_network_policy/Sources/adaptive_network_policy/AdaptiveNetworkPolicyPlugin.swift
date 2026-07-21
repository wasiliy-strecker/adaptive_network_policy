#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#endif

public class AdaptiveNetworkPolicyPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
      let messenger = registrar.messenger()
    #else
      let messenger = registrar.messenger
    #endif

    let monitor = DarwinNetworkConditionsMonitor()
    NativeNetworkConditionsApiSetup.setUp(
      binaryMessenger: messenger,
      api: DarwinNetworkConditionsHostApi(monitor: monitor)
    )
    WatchStreamHandler.register(
      with: messenger,
      streamHandler: DarwinNetworkConditionsEventHandler(monitor: monitor)
    )
    monitor.start()
  }
}
