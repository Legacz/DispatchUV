//
//  UVConnect.swift
//  DispatchUV
//
//  Created by Helge Hess on 19/09/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import CLibUV

public typealias UVConnectCB = ( UVError? ) -> Void

public extension UVTCPDispatchIO {
  
  func connect(address: UnsafePointer<sockaddr>, callback: UVConnectCB) {
    let req = UnsafeMutablePointer<uv_connect_t>.allocate(capacity: 1)
    req.pointee.data = CallbackHolder.wrap(callback)
    
    uv_tcp_connect(req, handle, address, cbConnect)
  }
  
}

private func cbConnect(req: UnsafeMutablePointer<uv_connect_t>?, status: Int32){
  defer { req?.deallocate(capacity: 1) }
  let cb = CallbackHolder<UVConnectCB>.unwrap(ptr: req!.pointee.data)
  
  guard status == 0 else {
    cb(UVError.ConnectFailed(status))
    return
  }
  
  cb(nil)
}
