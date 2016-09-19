//
//  UVError.swift
//  Noze.io
//
//  Created by Helge Heß on 18/09/2016.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import CLibUV

public enum UVError: Error, CustomStringConvertible {
  
  case Generic      (Int32)
  case ConnectFailed(Int32)
  case WriteFailed  (Int32)
  case ReadFailed   (Int32)
  
  public var description : String {
    switch self {
      case .Generic      (let code): return ed(code)
      case .ConnectFailed(let code): return ed(code)
      case .WriteFailed  (let code): return ed(code)
      case .ReadFailed   (let code): return ed(code)
    }
  }
}

private func ed(_ code: Int32) -> String {
  return String(cString: uv_strerror(code))
}
