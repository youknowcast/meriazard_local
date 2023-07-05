// very thanks to QuickMacApp https://gist.github.com/chriseidhof/26768f0b63fa3cdf8b46821e099df5ff

import Cocoa
import Foundation
import SwiftUI

struct NewMedia: Codable {
    let name: String
    let path: String
}

struct Media: Codable, Identifiable {
    let id: Int
    let name: String
    let path: String
}

struct Result: Decodable {
    let code: Int
}

struct ContentView: View {
    @State private var inputText = "" // ここで@Stateを定義します。
    @State private var imagePath: String = ""
    @State private var message: String? = "" // ここで@Stateを定義します。
    @State private var mediaList: [Media] = [] // ここで@Stateを定義します。
    @State private var image: NSImage? = nil

    @State private var newName: String = ""
    @State private var newPath: String = ""

    var columns: [GridItem] = Array(repeating: .init(.flexible()), count: 4)

    var body: some View {
        VStack(spacing: 10) {
            // 画像を表示します。
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(mediaList) { media in
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ID: \(media.id)")
                        Text("Name: \(media.name)")
                        Text("Path: \(media.path)")

                        Button(action: {
                            print("Button clicked for media id: \(media.id)")
                            image = NSImage(contentsOfFile: media.path)
                        }) {
                            Text("Action")
                        }
                    }
                    .padding()
                    .cornerRadius(10)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2)
                }
            }

            HStack {
                // ヘルプの表示
                Text("Enter your text below and hit Enter:")
                    .font(.headline) // フォントスタイルを変更する場合
                Spacer()
            }
            Button(action: {
                mediaList = mockSendToElixirBackend2(input: "get_media_list")
            }) {
                Text("一覧表示")
            }

            TextField("ファイル名", text: $newName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom)
            TextField("ファイルパス", text: $newPath)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom)
            Button(action: {
                addMedia()
                newName = ""
                newPath = ""
            }) {
                Text("登録")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func addMedia() {
        let command = "add_media,"
        let newMedia = NewMedia(name: newName, path: newPath)

        let encoder = JSONEncoder()
        // encoder.outputFormatting = .compact

        do {
            let jsonData = try encoder.encode(newMedia)
            if var jsonString = String(data: jsonData, encoding: .utf8) {
                jsonString = jsonString.replacingOccurrences(of: "\n", with: "")
                jsonString = jsonString.replacingOccurrences(of: " ", with: "")
                let message = "add_media,\(jsonString)"
                let response: [Result] = sendBE(message: message)
            }
        } catch {
            print("Error encoding media: \(error)")
        }
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

        // Buffer for the received data.
        let bufferSize = 1024
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
