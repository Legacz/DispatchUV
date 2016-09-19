//
//  UVCallbackHolder.swift
//  Noze.io
//
//  Created by Helge Hess on 18/09/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

final class CallbackHolder<ClosureType> {
  
  // TBD: This may not be necessary. Can we directly use the 'closure object'?
  
  static func wrap(_ cb: ClosureType, extra: AnyObject? = nil)
              -> UnsafeMutableRawPointer
  {
    return CallbackHolder(callback: cb, extra: extra).toCPointer()
  }
  
  static func unwrap(ptr: UnsafeMutableRawPointer) -> ClosureType {
    let r = Unmanaged<CallbackHolder<ClosureType>>
              .fromOpaque(ptr).takeRetainedValue()
    return r.callback
  }
  static func unwrapRaw(ptr: UnsafeMutableRawPointer)
              -> CallbackHolder<ClosureType>
  {
    let r = Unmanaged<CallbackHolder<ClosureType>>
             .fromOpaque(ptr).takeRetainedValue()
    return r
  }
  
  let callback : ClosureType
  let extra    : AnyObject?
  
  init(callback: ClosureType, extra: AnyObject?) {
    self.callback = callback
    self.extra    = extra
  }
  
  func toCPointer() -> UnsafeMutableRawPointer {
    return UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())
  }
}

