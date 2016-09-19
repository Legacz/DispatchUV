//
//  main.swift
//  Playground
//
//  Created by Helge Hess on 19/09/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Darwin
import DispatchUV

func myMain() {
  let Q = UVLoopQueue.main
  
  print("Hello UV: \(Q)")
  
  Q.lookup(host: "zeezide.de", port: 80) { err, result in
    guard err == nil else {
      print("address lookup failed: \(err)")
      return
    }
    guard let ai = result else {
      print("address lookup OK but no address info?!")
      return
    }
    
    print("Lookup: \(ai.pointee)")
    
    let io = UVTCPDispatchIO(queue: Q)
    io.connect(address: ai.pointee.ai_addr) { err in
      guard err == nil else { print("connect failed: \(err)"); return }
      
      let s = "GET / HTTP/1.0\r\nHost: zeezide.de\r\n\r\n"
      
      let data = UVDispatchData.from(string: s)
      io.write(offset: 0, data: data, queue: Q) {
        done, _, error in
        
        print("did write: \(done) \(error)")
      }
      
      io.read(offset: 0, length: 10000, queue: Q) {
        done, data, err in
        
        print("read: \(done) \(err) \(data)")
        if let data = data {
          fwrite(data.buf.base, 1, data.buf.len, stdout)
        }
      }
    }
  }

  UVLoopQueue.main.run()

  print("Loop didn't run? Nah, it is empty!")
}
