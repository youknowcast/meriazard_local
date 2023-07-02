// very thanks to QuickMacApp https://gist.github.com/chriseidhof/26768f0b63fa3cdf8b46821e099df5ff

import Cocoa
import SwiftUI
import Foundation

struct ContentView: View {
    @State private var inputText = "" // ここで@Stateを定義します。
	    @State private var imagePath: String = ""
    @State private var message: String? = "" // ここで@Stateを定義します。
    @State private var image: NSImage? = nil

    var body: some View {
        VStack(spacing: 10) {
			// 画像を表示します。
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }

            if let message = message {
               				Text(message)
					.font(.headline) // フォントスタイルを変更する場合 
            }

			HStack {
				// ヘルプの表示
				Text("Enter your text below and hit Enter:")
					.font(.headline) // フォントスタイルを変更する場合
				Spacer()
			}

            // 入力フィールドを追加
            TextField("Enter some text", text: $inputText, onCommit: {
                // モック関数に入力を送信して、画像のパスを取得します。
                //imagePath = mockSendToElixirBackend(input: inputText)

                // 取得した画像のパスを使用して、画像をロードします。
                //image = NSImage(contentsOfFile: imagePath)

                message = mockSendToElixirBackend2(input: inputText)
                
                // 入力をクリアします。
                inputText = ""
			})
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom)
			

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

	// モック関数：入力を受け取り、画像のパスを返します。
    func mockSendToElixirBackend2(input: String) -> String {
        // 入力を表示します。
        print("Input Text: \(input)")

    let sockfd = socket(AF_INET, SOCK_STREAM, 0)
    if sockfd < 0 {
        print("Error: \(errno), \(strerror(errno))")
        return ""
    }

    var server = sockaddr_in()
    server.sin_family = sa_family_t(AF_INET)
    server.sin_port = in_port_t(UInt16(32552).bigEndian)

    let serverIp = "127.0.0.1"
    if inet_pton(AF_INET, serverIp, &server.sin_addr) <= 0 {
        print("inet_pton error occurred")
        return ""
    }

    var serverCopy = server
    let connectStatus = withUnsafeMutablePointer(to: &serverCopy) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            connect(sockfd, $0, socklen_t(MemoryLayout.size(ofValue: server)))
        }
    }

    if connectStatus < 0 {
        print("Error in connect: \(errno), \(strerror(errno))")
        return ""
    }

    let hello = input + "\n" 
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

        return response

    }

    func mockSendToElixirBackend(input: String) -> String {
        // 入力を表示します。
        print("Input Text: \(input)")
        // ここでは、ダミーの画像パスを返します。
        // 実際には、Elixirバックエンドに接続し、結果を取得します。
        return "/path/to/local/image.png"
    }
}

NSApplication.shared.run {
	ContentView()
}

extension NSApplication {
    public func run<V: View>(@ViewBuilder view: () -> V) {
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
        self.servicesMenu = NSMenu()
        services.submenu = self.servicesMenu
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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Main Window")
        hostingView = NSHostingView(rootView: contentView)
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        window.delegate = self
        NSApp.activate(ignoringOtherApps: true)
    }
}