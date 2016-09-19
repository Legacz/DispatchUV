//
//  UVLoopQueue.swift
//  Noze.io
//
//  Created by Helge Hess on 18/09/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import CLibUV

public class UVLoopQueue {
  
  public static var main : UVLoopQueue = UVLoopQueue(loop: uv_default_loop()!)
  
  public let loop : UnsafeMutablePointer<uv_loop_t>
  
  public init(loop: UnsafeMutablePointer<uv_loop_t>) {
    self.loop = loop
  }
  
  public func run() {
    uv_run(loop, UV_RUN_DEFAULT)
  }
}
