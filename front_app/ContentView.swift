// very thanks to QuickMacApp https://gist.github.com/chriseidhof/26768f0b63fa3cdf8b46821e099df5ff

import AppKit
import Cocoa
import Foundation
import QuickLook
import SwiftUI

struct NewMedia: Codable {
    let name: String
    let path: String
}

struct NewMediaCapture: Codable {
    let media_id: Int
    let comment: String
    let path: String
}

struct Media: Codable, Identifiable {
    let id: Int
    let name: String
    let path: String
}

struct MediaCapture: Codable, Identifiable {
    let id: Int
    let media_id: Int
    let comment: String
    let path: String
}

struct Result: Decodable {
    let code: Int
}

struct Thumbnail: NSViewRepresentable {
    let url: URL
    let size: CGFloat

    func makeNSView(context _: Context) -> NSImageView {
        let view = NSImageView()
        let thumbnail = QLThumbnailImageCreate(kCFAllocatorDefault, url as CFURL, CGSize(width: size, height: size), nil)
        if let thumbnail = thumbnail {
            view.image = NSImage(cgImage: thumbnail.takeUnretainedValue(), size: NSSize.zero)
        }
        return view
    }

    func updateNSView(_: NSImageView, context _: Context) {}

    // Thumbnail に onTapGesture を試してみたが動作しないため，こちらの onClick には未対応
}

struct ContentView: View {
    @State private var inputText = "" // ここで@Stateを定義します。
    @State private var imagePath: String = ""
    @State private var message: String? = "" // ここで@Stateを定義します。
    @State private var mediaList: [Media] = [] // ここで@Stateを定義します。
    @State private var image: NSImage? = nil

    @State var mediaShownCaptures: Media?
    @State var mediaCaptures = [MediaCapture]()

    @State private var screenCapture: NSImage? = nil
    @State private var captured: Bool = false
    @State var highlightWindow: HighlightWindow? = nil
    @State var captureRect: CGRect? = nil

    @State private var newName: String = ""
    @State private var selectedFile: URL? = nil

    var columns: [GridItem] = Array(repeating: .init(.flexible()), count: 4)

    var body: some View {
        VStack(spacing: 10) {
            // 画像を表示します。
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }

            List(mediaList, id: \.id) { media in
                HStack(alignment: .center, spacing: 10) {
                    Thumbnail(url: URL(fileURLWithPath: media.path), size: 50)
                    Text("Name: \(media.name)")
                    Text("Path: \(media.path)")
                    Button(action: {
                        print("Button clicked for media id: \(media.id)")
                        let url = URL(fileURLWithPath: media.path)
                        if media.path.hasSuffix(".mov") || media.path.hasSuffix(".mp4") {
                            // Open video with QuickTime Player
                            let quickTimeURL = URL(fileURLWithPath: "/System/Applications/QuickTime Player.app")
                            let configuration = NSWorkspace.OpenConfiguration()
                            NSWorkspace.shared.open([url], withApplicationAt: quickTimeURL, configuration: configuration, completionHandler: { _, error in
                                if let error = error {
                                    print("Failed to open URL: \(error)")
                                }
                            })

                        } else {
                            image = NSImage(contentsOfFile: media.path)
                        }
                    }) {
                        Text("Show")
                    }
                    Button(action: {
                        print("Delete button clicked for media id: \(media.id)")
                        let command = "delete_media,\(media.id)"
                        let result: [Result] = sendBE(message: command)

                        mediaList = getMediaList()
                    }) {
                        Text("Delete")
                    }
                    Button("Show Tags") {
                        mediaCaptures = sendBE(message: "get_media_captures,\(media.id)")
                        mediaShownCaptures = media
                    }

                    // screenCapture があるときに tag づけを行うかのボタンを表示する
                    // tag づけを行う場合，まず，ローカルにファイル保存を行う(saveScreenCapture)
                    // 次に Elixir 側に保存を行う
                    // タグづけできたら screenCapture は初期化する．
                    if screenCapture != nil {
                        Button("ScreenCapture Tagged") {
                            guard let capture = screenCapture else {
                                print("No screen capture to save")
                                return
                            }
                            let path = NSHomeDirectory().appending("/Desktop/captures")
                            let fullPath = saveScreenCapture(capture: capture, path: path)
                            addMediaCapture(mediaId: media.id, comment: "foo", path: fullPath)

                            screenCapture = nil
                        }
                    }
                }
                // mediaCaptures を表示する
                // 表示条件: 表示対象が設定されており表示対象である(mediaShownCaptures == self.media)
                if let shownCaptures = mediaShownCaptures, shownCaptures.id == media.id {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            Button("x") {
                                mediaShownCaptures = nil
                            }

                            ForEach(mediaCaptures, id: \.id) { capture in
                                let nsImage = NSImage(byReferencing: URL(fileURLWithPath: capture.path))
                                VStack {
                                    Image(nsImage: nsImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 50) // or your preferred height
                                        .padding(.horizontal, 2)
                                        .onTapGesture {
                                            image = nsImage
                                        }
                                    Text(capture.comment)
                                        .font(.footnote)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                    }
                }
            }

            Button(action: {
                mediaList = getMediaList()
            }) {
                Text("一覧表示")
            }

            HStack {
                // ヘルプの表示
                Text("スクリーンショット")
                    .font(.headline) // フォントスタイルを変更する場合
                Spacer()
            }
            if let capture = screenCapture {
                Image(nsImage: capture)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            HStack {
                Button("全体スクリーンショット") {
                    let displayId = CGMainDisplayID()
                    let bounds = CGDisplayBounds(displayId)

                    guard let image = CGWindowListCreateImage(bounds, [.optionOnScreenOnly], kCGNullWindowID, []) else {
                        return
                    }

                    screenCapture = NSImage(cgImage: image, size: NSZeroSize)
                }
                Button("capture area") {
                    if highlightWindow == nil {
                        if let screen = NSScreen.main {
                            let screenWidth = screen.frame.size.width
                            let screenHeight = screen.frame.size.height

                            let rectSize: CGFloat = 600
                            let rect = CGRect(x: (screenWidth - rectSize) / 2,
                                              y: (screenHeight - rectSize) / 2,
                                              width: rectSize,
                                              height: rectSize)
                            highlightWindow = HighlightWindow(rect: rect)
                            captureRect = rect
                        }
                    }

                    if let highlightWindow = highlightWindow {
                        if highlightWindow.isVisible {
                            highlightWindow.orderOut(nil)
                            captureRect = highlightWindow.frame
                        } else {
                            if let captureRect = captureRect {
                                highlightWindow.setFrame(captureRect, display: true)
                            }
                            highlightWindow.makeKeyAndOrderFront(nil)
                        }
                    }
                }
                Button("中央キャプチャ") {
                    if let screen = NSScreen.main {
                        if highlightWindow == nil {
                            let screenWidth = screen.frame.size.width
                            let screenHeight = screen.frame.size.height

                            let rectSize: CGFloat = 600

                            let rect = CGRect(x: (screenWidth - rectSize) / 2,
                                              y: (screenHeight - rectSize) / 2,
                                              width: rectSize,
                                              height: rectSize)
                        } else {
                            captureRect = highlightWindow?.frame
                        }

                        if let rect = captureRect {
                            if highlightWindow?.isVisible == true {
                                highlightWindow?.orderOut(nil)
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if let capture = captureRectImage(rect) {
                                    screenCapture = capture
                                }
                            }
                        }
                    }
                    captureRect = nil
                }

                Button("Clear screenshot") {
                    screenCapture = nil
                }
                Button("Save Screenshot") {
                    guard let screenCapture = screenCapture else {
                        print("No screen capture to save")
                        return
                    }

                    let path = NSHomeDirectory().appending("/Desktop/captures")
                    saveScreenCapture(capture: screenCapture, path: path)

                    captured = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        captured = false
                    }
                }
                if captured {
                    Text("saved!")
                }
            }
            HStack {
                Text("ファイル登録")
                Spacer()
            }
            VStack {
                TextField("ファイル名", text: $newName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                HStack {
                    Button("Select File") {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = false
                        if panel.runModal() == .OK {
                            selectedFile = panel.url
                        }
                    }
                    if let selected = selectedFile {
                        Text("Selected file: \(selected.path)")
                        Button("Clear File") {
                            selectedFile = nil
                        }
                    } else {
                        Text("No file selected")
                    }
                }
                Button("登録") {
                    if let selectedFile = selectedFile {
                        addMedia(name: newName, path: selectedFile.path)
                        newName = ""
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func captureRectImage(_ rect: CGRect) -> NSImage? {
        let screenRect = NSScreen.main?.frame
        let screenBounds = CGRect(x: rect.origin.x, y: screenRect!.height - rect.origin.y - rect.height, width: rect.width, height: rect.height)
        if let imageRef = CGWindowListCreateImage(screenBounds, .optionOnScreenBelowWindow, kCGNullWindowID, [.boundsIgnoreFraming]) {
            return NSImage(cgImage: imageRef, size: NSZeroSize)
        }
        return nil
    }

    func saveScreenCapture(capture: NSImage, path: String) -> String {
        // 現在の時刻を元にUUIDを生成
        let uuid = UUID().uuidString
        // ファイル名としてUUIDを使用
        let fileName = "\(uuid).png"
        // パスとファイル名を結合して完全なファイルパスを生成
        let fullPath = path.appending("/\(fileName)")

        // NSImageをDataに変換
        guard let tiffRepresentation = capture.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation),
              let pngData = bitmapImage.representation(using: .png, properties: [:])
        else {
            print("Failed to convert NSImage to Data")
            return ""
        }

        do {
            // Dataを使用してファイルを書き出し
            try pngData.write(to: URL(fileURLWithPath: fullPath))
            print("File saved at: \(fullPath)")
        } catch {
            print("Failed to save file: \(error)")
        }
        return fullPath
    }

    func addMedia(name: String, path: String) {
        let command = "add_media,"
        let newMedia = NewMedia(name: name, path: path)

        let encoder = JSONEncoder()
        // encoder.outputFormatting = .compact

        do {
            let jsonData = try encoder.encode(newMedia)
            if var jsonString = String(data: jsonData, encoding: .utf8) {
                jsonString = jsonString.replacingOccurrences(of: "\n", with: "")
                let message = "\(command)\(jsonString)"
                let response: [Result] = sendBE(message: message)
            }
        } catch {
            print("Error encoding media: \(error)")
        }
    }

    func addMediaCapture(mediaId: Int, comment: String, path: String) {
        let command = "add_media_capture,"
        let newMediaCapture = NewMediaCapture(media_id: mediaId, comment: comment, path: path)

        let encoder = JSONEncoder()
        // encoder.outputFormatting = .compact

        do {
            let jsonData = try encoder.encode(newMediaCapture)
            if var jsonString = String(data: jsonData, encoding: .utf8) {
                jsonString = jsonString.replacingOccurrences(of: "\n", with: "")
                let message = "\(command)\(jsonString)"
                let response: [Result] = sendBE(message: message)
            }
        } catch {
            print("Error encoding media: \(error)")
        }
    }

    func getMediaList() -> [Media] {
        let response: [Media] = sendBE(message: "get_media_list")
        return response
    }

    // モック関数：入力を受け取り、画像のパスを返します。
    func mockSendToElixirBackend2(input: String) -> [Media] {
        // 入力を表示します。
        print("Input Text: \(input)")

        return sendBE(message: input)
    }

    func mockSendToElixirBackend(input: String) -> String {
        // 入力を表示します。
        print("Input Text: \(input)")
        // ここでは、ダミーの画像パスを返します。
        // 実際には、Elixirバックエンドに接続し、結果を取得します。
        return "/path/to/local/image.png"
    }

    func sendBE<T: Decodable>(message: String) -> [T] {
        let sockfd = socket(AF_INET, SOCK_STREAM, 0)
        if sockfd < 0 {
            print("Error: \(errno), \(strerror(errno))")
            return []
        }

        var server = sockaddr_in()
        server.sin_family = sa_family_t(AF_INET)
        server.sin_port = in_port_t(UInt16(32552).bigEndian)

        let serverIp = "127.0.0.1"
        if inet_pton(AF_INET, serverIp, &server.sin_addr) <= 0 {
            print("inet_pton error occurred")
            return []
        }

        var serverCopy = server
        let connectStatus = withUnsafeMutablePointer(to: &serverCopy) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(sockfd, $0, socklen_t(MemoryLayout.size(ofValue: server)))
            }
        }

        if connectStatus < 0 {
            print("Error in connect: \(errno), \(strerror(errno))")
            return []
        }

        let hello = message + "\n"
        let helloBytes = hello.utf8
        let helloBytesCount = helloBytes.count
        let result = hello.withCString { ptr -> ssize_t in
            send(sockfd, ptr, helloBytesCount, 0)
        }
        if result == -1 {
            print("Error in send: \(errno), \(strerror(errno))")
        } else {
            print("Sent \(result) bytes")
        }

        // FIXME: localhost 間なのでとりあえず当面ここで詰まらない程度のサイズにする．
        let bufferSize = 104_857_600
        var buffer = [CChar](repeating: 0, count: bufferSize)

        let bytesRead = recv(sockfd, &buffer, bufferSize - 1, 0)
        var response = ""
        if bytesRead > 0 {
            response = String(cString: buffer)
            print("Received from server: \(response)")
        } else if bytesRead < 0 {
            print("Error in recv: \(errno), \(strerror(errno))")
        } else {
            print("Server closed connection")
        }

        do {
            guard let data = response.data(using: .utf8) else {
                return []
            }
            let decoder = JSONDecoder()
            let decoded = try decoder.decode([T].self, from: data)

            return decoded
        } catch {
            print("JSON decode error: \(error)")
            return []
        }
    }
}

class HighlightWindow: NSWindow, ObservableObject {
    @Published var windowFrame: NSRect
    init(rect: CGRect) {
        windowFrame = rect
        super.init(contentRect: rect, styleMask: .titled, backing: .buffered, defer: false)
        backgroundColor = NSColor.red.withAlphaComponent(0.1)
        level = .normal
        isMovable = true
        isReleasedWhenClosed = false
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidMove(notification:)), name: NSWindow.didMoveNotification, object: self)
    }

    @objc func windowDidMove(notification: NSNotification) {
        if let window = notification.object as? NSWindow {
            print(window.frame) // Print new window position. You may want to store it somewhere.
            windowFrame = window.frame
        }
    }
}

NSApplication.shared.run {
    ContentView()
}

public extension NSApplication {
    func run<V: View>(@ViewBuilder view: () -> V) {
        let appDelegate = AppDelegate(view())
        NSApp.setActivationPolicy(.regular)
        mainMenu = customMenu
        delegate = appDelegate
        run()
    }
}

// Inspired by https://www.cocoawithlove.com/2010/09/minimalist-cocoa-programming.html
extension NSApplication {
    var customMenu: NSMenu {
        let appMenu = NSMenuItem()
        appMenu.submenu = NSMenu()
        let appName = ProcessInfo.processInfo.processName
        appMenu.submenu?.addItem(NSMenuItem(title: "About \(appName)", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.submenu?.addItem(NSMenuItem.separator())
        let services = NSMenuItem(title: "Services", action: nil, keyEquivalent: "")
        servicesMenu = NSMenu()
        services.submenu = servicesMenu
        appMenu.submenu?.addItem(services)
        appMenu.submenu?.addItem(NSMenuItem.separator())
        appMenu.submenu?.addItem(NSMenuItem(title: "Hide \(appName)", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        let hideOthers = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.submenu?.addItem(hideOthers)
        appMenu.submenu?.addItem(NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""))
        appMenu.submenu?.addItem(NSMenuItem.separator())
        appMenu.submenu?.addItem(NSMenuItem(title: "Quit \(appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        let windowMenu = NSMenuItem()
        windowMenu.submenu = NSMenu(title: "Window")
        windowMenu.submenu?.addItem(NSMenuItem(title: "Minmize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m"))
        windowMenu.submenu?.addItem(NSMenuItem(title: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: ""))
        windowMenu.submenu?.addItem(NSMenuItem.separator())
        windowMenu.submenu?.addItem(NSMenuItem(title: "Show All", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "m"))

        let mainMenu = NSMenu(title: "Main Menu")
        mainMenu.addItem(appMenu)
        mainMenu.addItem(windowMenu)
        return mainMenu
    }
}

class AppDelegate<V: View>: NSObject, NSApplicationDelegate, NSWindowDelegate {
    init(_ contentView: V) {
        self.contentView = contentView
    }

    var window: NSWindow!
    var hostingView: NSView?
    var contentView: V

    func applicationDidFinishLaunching(_: Notification) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        window.center()
        window.setFrameAutosaveName("Main Window")
        hostingView = NSHostingView(rootView: contentView)
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        window.delegate = self
        NSApp.activate(ignoringOtherApps: true)
    }
}
