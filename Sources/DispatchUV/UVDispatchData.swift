//
//  UVDispatchData.swift
//  Noze.io
//
//  Created by Helge Heß on 18/09/2016.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import CLibUV

public class UVDispatchData {
  
  // TODO: vectors, concat, all that :-)
  public var buf    : uv_buf_t
  public var doFree = true
  
  deinit {
    if doFree {
      free(buf.base!)
      doFree = false
    }
  }
  
  
  // MARK: - Copying Contructor
  
  public init(bytes: UnsafeBufferPointer<UInt8>) {
    let mem = UnsafeMutablePointer<Int8>.allocate(capacity: bytes.count)
    buf = uv_buf_init(mem, UInt32(bytes.count))
    memcpy(buf.base, bytes.baseAddress!, buf.len)
  }
  public init(bytes: UnsafeBufferPointer<Int8>) { // yeah
    let mem = UnsafeMutablePointer<Int8>.allocate(capacity: bytes.count)
    buf = uv_buf_init(mem, UInt32(bytes.count))
    memcpy(buf.base, bytes.baseAddress!, buf.len)
  }
  
  
  // MARK: - Convenience
  
  public static func from(string: String) -> UVDispatchData {
    return string.withCString { cs in
      let bp = UnsafeBufferPointer(start: cs, count: Int(strlen(cs)))
      return UVDispatchData(bytes: bp)
    }
  }

}
