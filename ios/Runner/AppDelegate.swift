import UIKit
import Flutter
import QuickLook

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  var loadingAlert: UIAlertController?
  var arQuickLookDataSource: ARQuickLookDataSource? // <-- Strong reference!

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "ar_intent_channel", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "launchARQuickLook" {
        if let args = call.arguments as? [String: Any],
           let urlStr = args["url"] as? String,
           let remoteUrl = URL(string: urlStr),
           let topVC = self?.topMostController() {
          print("iOS: Received USDZ URL from Flutter: \(urlStr)")
          self?.showLoadingAlert(on: topVC)
          self?.downloadUSDZFile(from: remoteUrl) { localUrl in
            DispatchQueue.main.async {
              self?.hideLoadingAlert {
                if let fileUrl = localUrl {
                  print("iOS: Downloaded to local file: \(fileUrl)")
                  self?.presentQuickLook(for: fileUrl, from: topVC)
                  result(true)
                } else {
                  print("iOS: Download failed!")
                  result(false)
                }
              }
            }
          }
        } else {
          print("iOS: Invalid URL or no top controller.")
          result(false)
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Quick Look
  private func presentQuickLook(for url: URL, from controller: UIViewController) {
    print("iOS: Attempting to launch AR Quick Look for \(url)")
    let previewController = QLPreviewController()
    // Store the data source so it's not deallocated!
    arQuickLookDataSource = ARQuickLookDataSource(url: url)
    previewController.dataSource = arQuickLookDataSource
    controller.present(previewController, animated: true) {
      print("iOS: AR Quick Look presented.")
    }
  }

  private func topMostController() -> UIViewController? {
    var topController = window?.rootViewController
    while let presentedViewController = topController?.presentedViewController {
      topController = presentedViewController
    }
    return topController
  }

  // MARK: - Loader UI
  private func showLoadingAlert(on controller: UIViewController) {
    let alert = UIAlertController(title: nil, message: "Preparing AR View", preferredStyle: .alert)
    let loadingIndicator = UIActivityIndicatorView(style: .medium)
    loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
    alert.view.addSubview(loadingIndicator)
    NSLayoutConstraint.activate([
      loadingIndicator.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
      loadingIndicator.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: -20)
    ])
    loadingIndicator.isUserInteractionEnabled = false
    loadingIndicator.startAnimating()
    controller.present(alert, animated: true, completion: nil)
    loadingAlert = alert
  }

  private func hideLoadingAlert(completion: @escaping () -> Void) {
    if let alert = loadingAlert {
      alert.dismiss(animated: true, completion: completion)
      loadingAlert = nil
    } else {
      completion()
    }
  }

  // MARK: - File Download
  private func downloadUSDZFile(from remoteUrl: URL, completion: @escaping (URL?) -> Void) {
    let session = URLSession(configuration: .default)
    let task = session.downloadTask(with: remoteUrl) { (tempLocalUrl, response, error) in
      guard let tempLocalUrl = tempLocalUrl, error == nil else {
        print("iOS: Error downloading file: \(error?.localizedDescription ?? "Unknown error")")
        completion(nil)
        return
      }
      // Save to Documents directory with unique name
      let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      let fileName = UUID().uuidString + "_" + remoteUrl.lastPathComponent
      let savedUrl = documentsUrl.appendingPathComponent(fileName)
      try? FileManager.default.removeItem(at: savedUrl) // remove if exists
      do {
        try FileManager.default.moveItem(at: tempLocalUrl, to: savedUrl)
        completion(savedUrl)
      } catch {
        print("iOS: Could not move file: \(error.localizedDescription)")
        completion(nil)
      }
    }
    task.resume()
  }
}

class ARQuickLookDataSource: NSObject, QLPreviewControllerDataSource {
  let url: URL

  init(url: URL) {
    self.url = url
  }

  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    return 1
  }

  func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
    return url as QLPreviewItem
  }
}

// import UIKit
// import Flutter
// import ModelIO

// @UIApplicationMain
// @objc class AppDelegate: FlutterAppDelegate {
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {

//     let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
//     let channel = FlutterMethodChannel(name: "glb_to_usdz", binaryMessenger: controller.binaryMessenger)

//     channel.setMethodCallHandler { (call, result) in
//       if call.method == "convertDuckSample" {
//         self.convertGltfFromGithub(result: result)
//       } else {
//         result(FlutterMethodNotImplemented)
//       }
//     }

//     GeneratedPluginRegistrant.register(with: self)
//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }

//   private func convertGltfFromGithub(result: @escaping FlutterResult) {
//     let baseUrl = "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/main/2.0/Duck/glTF/"
//     let fileNames = ["Duck.gltf", "Duck.bin", "DuckCM.png"]
    
//     let tempDir = FileManager.default.temporaryDirectory
//     var fileURLs: [String: URL] = [:]

//     let dispatchGroup = DispatchGroup()
//     var downloadError: Error?

//     for fileName in fileNames {
//       guard let url = URL(string: baseUrl + fileName) else { continue }

//       dispatchGroup.enter()
//       let destination = tempDir.appendingPathComponent(fileName)
//       fileURLs[fileName] = destination

//       URLSession.shared.downloadTask(with: url) { tempFile, _, error in
//         if let error = error {
//           downloadError = error
//           dispatchGroup.leave()
//           return
//         }
//         guard let tempFile = tempFile else {
//           dispatchGroup.leave()
//           return
//         }

//         do {
//           if FileManager.default.fileExists(atPath: destination.path) {
//             try FileManager.default.removeItem(at: destination)
//           }
//           try FileManager.default.moveItem(at: tempFile, to: destination)
//         } catch {
//           downloadError = error
//         }

//         dispatchGroup.leave()
//       }.resume()
//     }

//     dispatchGroup.notify(queue: .main) {
//       if let error = downloadError {
//         result(FlutterError(code: "DOWNLOAD_FAILED", message: error.localizedDescription, details: nil))
//         return
//       }

//       guard let gltfURL = fileURLs["Duck.gltf"] else {
//         result(FlutterError(code: "MISSING_GLTF", message: "GLTF file missing", details: nil))
//         return
//       }

//       let usdzURL = tempDir.appendingPathComponent("Duck.usdz")
//       print("📥 Converting GLTF: \(gltfURL.path)")

//       do {
//         let asset = MDLAsset(url: gltfURL)
//         try asset.export(to: usdzURL)
//         print("✅ USDZ created at: \(usdzURL.path)")
//         result(usdzURL.path)
//       } catch {
//         result(FlutterError(code: "EXPORT_FAILED", message: "Conversion failed: \(error.localizedDescription)", details: nil))
//       }
//     }
//   }
// }



//import UIKit
//import Flutter
//
//@UIApplicationMain
//@objc class AppDelegate: FlutterAppDelegate {
//  override func application(
//    _ application: UIApplication,
//    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//  ) -> Bool {
//    GeneratedPluginRegistrant.register(with: self)
//    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//  }
//}
