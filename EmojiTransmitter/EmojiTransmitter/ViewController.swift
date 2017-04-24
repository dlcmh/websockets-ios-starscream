/**
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit

import Starscream

final class ViewController: UIViewController {

  // MARK: - Properties
  var username = ""
  var socket = WebSocket(url: URL(string: "ws://localhost:1337/")!, protocols: ["chat"])

  // MARK: - IBOutlets
  @IBOutlet var emojiLabel: UILabel!
  @IBOutlet var usernameLabel: UILabel!

  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    socket.delegate = self
    socket.connect()

    navigationItem.hidesBackButton = true
  }
  
  deinit {
    socket.disconnect(forceTimeout: 0)
    socket.delegate = nil
  }
}

// MARK: - IBActions
extension ViewController {

  @IBAction func selectedEmojiUnwind(unwindSegue: UIStoryboardSegue) {
    guard let viewController = unwindSegue.source as? CollectionViewController,
      let emoji = viewController.selectedEmoji() else{
        return
    }

    sendMessage(emoji)
  }
}

// MARK: - FilePrivate
fileprivate extension ViewController {

  func sendMessage(_ message: String) {
//    print("NOOP - sendMessage: \(message)")
    socket.write(string: message)
  }

  func messageReceived(_ message: String, senderName: String) {
    emojiLabel.text = message
    usernameLabel.text = senderName
  }
}

// MARK: - WebSocketDelegate
extension ViewController: WebSocketDelegate {
  func websocketDidConnect(_ socket: WebSocket) {
    socket.write(string: username)
  }
  
  func websocketDidDisconnect(_ socket: WebSocket, error: NSError?) {
    performSegue(withIdentifier: "websocketDisconnected", sender: self)
  }
  
  func websocketDidReceiveMessage(_ socket: WebSocket, text: String) {
    guard let data = text.data(using: .utf16),
          let jsonData = try? JSONSerialization.jsonObject(with: data),
          let jsonDict = jsonData as? [String: Any],
          let messageType = jsonDict["type"] as? String else {
      return
    }
    
    if messageType == "message",
       let messageData = jsonDict["data"] as? [String: Any],
       let messageAuthor = messageData["author"] as? String,
       let messageText = messageData["text"] as? String {
      messageReceived(messageText, senderName: messageAuthor)
    }
  }
  
  func websocketDidReceiveData(_ socket: WebSocket, data: Data) {
    
  }
}
