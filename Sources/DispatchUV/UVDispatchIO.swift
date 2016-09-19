//
//  UVDispatchIO.swift
//  Noze.io
//
//  Created by Helge Heß on 18/09/2016.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import CLibUV

public typealias UVReadCB  = ( Bool, UVDispatchData?, Error? ) -> Void
public typealias UVWriteCB = ( Bool, UVDispatchData?, Error? ) -> Void

public protocol UVDispatchIO: class { // TODO: make superclass, add StreamType
  // Note: the queue arguments are superfluous here, always goes to the same
  //       queue as the handle it's bound to.
  //       FIXME: Which is a bug. It should do Q.async with the handler!
  
  func read (offset: Int, length: Int, queue: UVLoopQueue,
             callback: @escaping UVReadCB)
  
  func write(offset: Int, data: UVDispatchData, queue: UVLoopQueue,
             callback: @escaping UVWriteCB)
  
  var fileDescriptor : Int32 { get }
}

class UVReadRequest {
  
  var next      : UVReadRequest? = nil
  
  var tail      : UVReadRequest? { // it is late, make this right :-)
    if next != nil { return next }
    
    var n = next
    while n != nil {
      if n!.next == nil { return n }
      n = n!.next
    }
    
    return nil
  }
  
  let queue     : UVLoopQueue
  let callback  : UVReadCB
  let count     : Int
  
  var pending   : Int
  
  var isDone    : Bool { return pending == 0 }
  
  init(count: Int, queue: UVLoopQueue, callback: @escaping UVReadCB) {
    self.queue    = queue
    self.callback = callback
    self.count    = count
    self.pending  = count
  }
  
  func eof() {
    callback(true, nil, nil)
  }
  
  func invoke(error: Error) {
    callback(true, nil, error)
  }
  
  func feed(count: Int, data: UnsafeMutablePointer<Int8>) -> Int {
    guard pending > 0 else { return count }
    
    let grabCount = min(self.pending, count)
    self.pending -= grabCount
    
    let bp   = UnsafeBufferPointer(start: data, count: grabCount)
    let data = UVDispatchData(bytes: bp) // copies
    
    callback(isDone, data, nil)
    
    return count - grabCount // return bytes left
  }
}

public class UVTCPDispatchIO: UVDispatchIO {
  
  public enum StreamType {
    case stream
  }

  var handle : UnsafeMutablePointer<uv_tcp_t>?
  
  func castHandle<T>() -> UnsafeMutablePointer<T>? {
    guard let handle = handle else { return nil }
    return UnsafeMutableRawPointer(handle).assumingMemoryBound(to: T.self)
  }
  
  public var fileDescriptor : Int32 { return handle?.pointee.u.fd ?? -1 }
  
  public init(handle: UnsafeMutablePointer<uv_tcp_t>) {
    self.handle = handle
    self.handle!.pointee.data =
      UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())
  }
  
  public convenience init(queue: UVLoopQueue) {
    let handle = UnsafeMutablePointer<uv_tcp_t>.allocate(capacity: 1)
    uv_tcp_init(queue.loop, handle)
    self.init(handle: handle)
  }
  
  public convenience init(type: StreamType, fileDescriptor: Int32,
                          queue: UVLoopQueue,
                          cleanupHandler: () ->())
  {
    assert(type == .stream, "only supporting streams")
    
    self.init(queue: queue)
    
    // Changed in version 1.2.1: the file descriptor is set to non-blocking mode
    uv_tcp_open(handle, fileDescriptor)
  }
  
  deinit { // TBD
    handle?.deallocate(capacity: 1)
  }
  
  func close() {
    handle?.withMemoryRebound(to: uv_handle_t.self, capacity: 1) { handle in
      uv_close(handle, cbClose)
    }
  }
  func _didClose() {
    handle?.deallocate(capacity: 1)
    handle = nil
  }
  
  
  // MARK: - Reading
  
  var readRequests : UVReadRequest? = nil
  var isReading    = false
  
  func _onRead(nread: Int, data: UnsafePointer<uv_buf_t>?) {
    guard nread >= 0 else {
      var head = readRequests
      readRequests = nil
      
      if uv_errno_t(Int32(nread)) == UV_EOF {
        while let req = head {
          req.eof()
          head = req.next
        }
      }
      else {
        while let req = head {
          req.invoke(error: UVError.ReadFailed(Int32(nread))) // TODO
          head = req.next
        }
      }
      return
    }
    
    guard let data = data else {
      assert(false, "got no data in read-cb?")
      return
    }
    
    var pendingData = nread
    var ptr : UnsafeMutablePointer<Int8> = data.pointee.base
    
    while let req = readRequests {
      pendingData = req.feed(count: pendingData, data: ptr)
      ptr = ptr.advanced(by: pendingData)
      
      if req.isDone { // this one is good
        readRequests = req.next
      }
      
      if pendingData == 0 {
        break
      }
    }

    if pendingData > 0 {
      assert(readRequests == nil, "pending data but also pending read-reqs?!")
      
      // TODO: cache pending data before stopping
    }
    
    if readRequests == nil {
      uv_read_stop(castHandle())
      isReading = false
    }
  }
  
  public func read(offset: Int, length: Int, queue: UVLoopQueue,
                   callback: @escaping UVReadCB)
  {
    let req = UVReadRequest(count: length, queue: queue, callback: callback)
   
    if let q = readRequests {
      q.tail!.next = req
    }
    else {
      readRequests = req
    }
    
    if isReading { return } // already reading
    
    // TODO: deliver spooled data
    
    isReading = true
    uv_read_start(castHandle(), cbAlloc, cbRead)
  }

  
  // MARK: - Writing
  
  public func write(offset: Int, data: UVDispatchData, queue: UVLoopQueue,
                    callback: @escaping UVWriteCB)
  {
    let req = UnsafeMutablePointer<uv_write_t>.allocate(capacity: 1)
    req.pointee.data = CallbackHolder.wrap(callback, extra: data)
    
    uv_write(req, castHandle(), &data.buf, 1, cbWriteDone)
  }
}

private func cbClose(handle: UnsafeMutablePointer<uv_handle_t>?) {
  guard let handle = handle else { return }
  defer { handle.deallocate(capacity: 1) }
  
  let object = Unmanaged<UVTCPDispatchIO>
                 .fromOpaque(handle.pointee.data).takeRetainedValue()
  object._didClose()
}


// MARK: - Reading

private func cbAlloc(handle: UnsafeMutablePointer<uv_handle_t>?, size: Int,
                     buffer: UnsafeMutablePointer<uv_buf_t>?)
{
  guard let buffer_ = buffer else {
    assert(buffer != nil, "got no target location?!")
    return
  }
  buffer_.pointee.base = malloc(size).assumingMemoryBound(to: Int8.self)
  buffer_.pointee.len  = size // can be different size!
}

private func cbRead(handle oh: UnsafeMutablePointer<uv_stream_t>?,
                    nread: Int, data: UnsafePointer<uv_buf_t>?)
{
  guard let handle = oh else {
    assert(oh != nil, "got no handle?!")
    return
  }
  let object = Unmanaged<UVTCPDispatchIO>
                 .fromOpaque(handle.pointee.data).takeUnretainedValue()
  object._onRead(nread: nread, data: data)
}


// MARK: - Writing

private func cbWriteDone(req: UnsafeMutablePointer<uv_write_t>?, status: Int32) {
  defer { req?.deallocate(capacity: 1) }
  let cb = CallbackHolder<UVWriteCB>.unwrap(ptr: req!.pointee.data)
  
  guard status == 0 else {
    cb(true, nil, UVError.WriteFailed(status))
    return
  }
  
  cb(true, nil, nil) // all good and done
}



