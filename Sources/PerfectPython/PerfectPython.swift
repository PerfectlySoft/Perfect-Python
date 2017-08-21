//
//  PerfectPython.swift
//  Perfect-Python
//
//  Created by Rockford Wei on 2017-08-18.
//  Copyright © 2017 PerfectlySoft. All rights reserved.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2017 - 2018 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import PythonAPI

public extension String {
  public func python() -> PyObj? {
    if let ref = PyString_FromString(self) {
      return PyObj(ref)
    } else {
      return nil
    }
  }
  public init(python: PyObj) {
    if let p = PyString_AsString(python.ref) {
      self = String(cString: p)
    } else {
      self = ""
    }
  }
}

public extension Int {
  public func python() -> PyObj? {
    if let ref = PyInt_FromLong(self) {
      return PyObj(ref)
    } else {
      return nil
    }
  }
  public init(python: PyObj) {
    self = PyInt_AsLong(python.ref)
  }
}

public extension Double {
  public func python() -> PyObj? {
    if let ref = PyFloat_FromDouble(self) {
      return PyObj(ref)
    } else {
      return nil
    }
  }
  public init(python: PyObj) {
    self = PyFloat_AsDouble(python.ref)
  }
}

public extension Array where Element == String {
  public func python() -> PyObj? {
    if let list = PyList_New(self.count) {
      for i in 0 ..< self.count {
        if let j = self[i].python() {
          _ = PyList_SetItem(list, i, j.ref)
        }
      }
      return PyObj(list)
    } else {
      return nil
    }
  }
  public init(python: PyObj) {
    var list:[String] = []
    for i in 0 ..< PyList_Size(python.ref) {
      if let j = PyList_GetItem(python.ref, i) {
        list.insert(String(python: PyObj(j)), at: i)
      }
    }
    self = list
  }
}

public extension Array where Element == Int {
  public func python() -> PyObj? {
    if let list = PyList_New(self.count) {
      for i in 0 ..< self.count {
        if let j = self[i].python() {
          _ = PyList_SetItem(list, i, j.ref)
        }
      }
      return PyObj(list)
    } else {
      return nil
    }
  }
  public init(python: PyObj) {
    var list:[Int] = []
    for i in 0 ..< PyList_Size(python.ref) {
      if let j = PyList_GetItem(python.ref, i) {
        list.insert(Int(python: PyObj(j)), at: i)
      }
    }
    self = list
  }
}

public extension Array where Element == Double {
  public func python() -> PyObj? {
    if let list = PyList_New(self.count) {
      for i in 0 ..< self.count {
        if let j = self[i].python() {
          _ = PyList_SetItem(list, i, j.ref)
        }
      }
      return PyObj(list)
    } else {
      return nil
    }
  }
  public init(python: PyObj) {
    var list:[Double] = []
    for i in 0 ..< PyList_Size(python.ref) {
      if let j = PyList_GetItem(python.ref, i) {
        list.insert(Double(python: PyObj(j)), at: i)
      }
    }
    self = list
  }
}


public extension Dictionary where Key == String, Value == Any {
  public func python() -> PyObj? {
    return try? PyObj(value: self as Any)
  }
  public init(python: PyObj) {
    if python.value is [String: Any], let v = python.value as? [String:Any] {
      self = v
    } else {
      self = [:]
    }
  }
}

open class PyObj {
  let ref: UnsafeMutablePointer<PyObject>
  public var autoDealloc = true

  public enum Exception: Error {
    case ImportFailure
    case ObjectFailure
    case InvalidType
    case NullArray
    case ElementInsertionFailure
    case ValueSavingFailure
  }

  public init(path: String? = nil, `import`: String) throws {
    if let p = path {
      PySys_SetPath(UnsafeMutablePointer<CChar>(mutating: p))
    }
    if let reference = PyImport_ImportModule(`import`) {
      ref = reference
    } else {
      throw Exception.ImportFailure
    }
  }

  public init(_ reference: UnsafeMutablePointer<PyObject>) {
    ref = reference
  }

  public init(arguments: [Any]) throws {
    guard arguments.count > 0,
      let args = PyTuple_New(arguments.count) else {
      throw Exception.NullArray
    }
    for i in 0 ..< arguments.count {
      let obj = try PyObj(value: arguments[i])
      obj.autoDealloc = false
      guard PyTuple_SetItem(args, i, obj.ref) == 0 else {
        throw Exception.ElementInsertionFailure
      }
    }
    ref = args
  }

  public init(value: Any) throws {
    if value is String, let v = value as? String {
      ref = PyString_FromString(v)
    } else if value is Int, let v = value as? Int {
      ref = PyInt_FromLong(v)
    } else if value is Float, let v = value as? Float {
      ref = PyFloat_FromDouble(Double(v))
    } else if value is Double, let v = value as? Double {
      ref = PyFloat_FromDouble(v)
    } else if value is [Any], let v = value as? [Any] {
      ref = PyList_New(v.count)
      for i in 0 ..< v.count {
        if let j = try? PyObj(value: v[i]) {
          j.autoDealloc = false
          _ = PyList_SetItem(ref, i, j.ref)
        }
      }
    } else if value is [String: Any], let v = value as? [String: Any] {
      ref = PyDict_New()
      for (i, j) in v {
        if let u = try? PyObj(value: j), let k = try? PyObj(value: i) {
          u.autoDealloc = false
          k.autoDealloc = false
          _ = PyDict_SetItem(ref, k.ref, u.ref)
        }
      }
    } else {
      throw Exception.InvalidType
    }
  }

  public var value: Any? {
    let j = ref.pointee
    let tpName = String(cString: j.ob_type.pointee.tp_name)
    let v: Any?
    switch tpName {
    case "str":
      v = String(cString: PyString_AsString(ref))
      break
    case "int":
      v = PyInt_AsLong(ref)
      break
    case "float":
      v = PyFloat_AsDouble(ref)
      break
    case "list":
      var list: [Any?] = []
      for i in 0 ..< PyList_Size(ref) {
        if let j = PyList_GetItem(ref, i) {
          let o = PyObj(j)
          list.insert(o.value, at: i)
        }
      }
      v = list
      break
    case "dict":
      var dict: [String: Any?] = [:]
      if let keys = PyDict_Keys(ref) {
        for i in 0 ..< PyDict_Size(ref) {
          if let key = PyList_GetItem(keys, i),
            let keyName = PyString_AsString(key),
            let j = PyDict_GetItem(ref, key) {
            let k = String(cString: keyName)
            let o = PyObj(j)
            dict[k] = o.value
            defer {
              Py_DecRef(key)
            }
          }
        }
        defer {
          Py_DecRef(keys)
        }
      }
      v = dict
      break
    default:
      v = nil
    }
    return v
  }

  public func call(_ functionName: String, args: [Any]? = nil) -> PyObj? {
    guard let function = PyObject_GetAttrString(ref, functionName)
      else {
        return nil
    }
    defer {
      Py_DecRef(function)
    }
    let result: UnsafeMutablePointer<PyObject>
    if let a = args, a.count < 1 {
      result = PyObject_CallObject(function, nil)
    } else if let a = args, let tuple = try? PyObj(arguments: a)  {
      result = PyObject_CallObject(function, tuple.ref)
    } else {
      return nil
    }
    return PyObj(result)
  }

  public func construct(_ arguments: [Any]? = nil) -> PyObj? {
    var args: PyObj? = nil
    if let b = arguments, let a = try? PyObj(arguments: b) {
      args = a
    }
    if let obj = PyInstance_New(ref, args?.ref, nil) {
      return PyObj(obj)
    } else {
      return nil
    }
  }

  public func load(_ variableName: String) -> PyObj? {
    if let reference = PyObject_GetAttrString(ref, variableName) {
      return PyObj(reference)
    } else {
      return nil
    }
  }

  public func save(_ variableName: String, newValue: Any) throws {
    let value = try PyObj(value: newValue)
    guard 0 == PyObject_SetAttrString(ref, variableName, value.ref) else {
      PyErr_Print()
      throw Exception.ValueSavingFailure
    }
  }

  deinit {
    defer {
      if autoDealloc {
        Py_DecRef(ref)
      }
    }
  }
}
