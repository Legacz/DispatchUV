//
//  UVLookup.swift
//  DispatchUV
//
//  Created by Helge Hess on 19/09/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import CLibUV

public typealias UVLookupCB =
                   ( UVError?, UnsafeMutablePointer<addrinfo>? ) -> Void

public extension UVLoopQueue {
  
  func lookup(host: String, port: Int, callback: @escaping UVLookupCB) {
    let req = UnsafeMutablePointer<uv_getaddrinfo_t>.allocate(capacity: 1)
    req.pointee.data = CallbackHolder.wrap(callback)
    
    // TBD: is this really vargs?
    uv_getaddrinfo(loop, req, cbAddrLookup, host, "\(port)", nil);
  }
  
}

private func cbAddrLookup(req:    UnsafeMutablePointer<uv_getaddrinfo_t>?,
                          status: Int32,
                          result: UnsafeMutablePointer<addrinfo>?)
{
  defer { uv_freeaddrinfo(result)      }
  defer { req?.deallocate(capacity: 1) }
  
  let cb = CallbackHolder<UVLookupCB>.unwrap(ptr: req!.pointee.data)
  
  guard status == 0 else {
    cb(UVError.Generic(status), nil)
    return
  }
  
  cb(nil, result)
}
