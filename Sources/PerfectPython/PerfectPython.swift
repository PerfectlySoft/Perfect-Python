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

  /// convert string to PyObj
  public func python() -> PyObj? {
    if let ref = PyString_FromString(self) {
      return PyObj(ref)
    } else {
      return nil
    }
  }

  /// convert PyObj to string
  public init(python: PyObj) throws {
    guard let p = PyString_AsString(python.ref),
       let s = String(validatingUTF8: p) else {
      throw PyObj.Exception.InvalidString
    }
    self = s
  }
}

public extension Int {

  /// convert integer to PyObj
  public func python() -> PyObj? {
    if let ref = PyInt_FromLong(self) {
      return PyObj(ref)
    } else {
      return nil
    }
  }

  /// convert PyObj to integer
  public init(python: PyObj) {
    self = PyInt_AsLong(python.ref)
  }
}

public extension Double {

  /// convert Double to PyObj
  public func python() -> PyObj? {
    if let ref = PyFloat_FromDouble(self) {
      return PyObj(ref)
    } else {
      return nil
    }
  }
  /// convert PyObj to Double
  public init(python: PyObj) {
    self = PyFloat_AsDouble(python.ref)
  }
}

/// conversion between [String] and PyObj
public extension Array where Element == String {

  /// convert [String] to PyObj
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

  /// convert PyObj to [String]
  public init(python: PyObj) throws {
    var list:[String] = []
    for i in 0 ..< PyList_Size(python.ref) {
      if let j = PyList_GetItem(python.ref, i) {
        let s = try String(python: PyObj(j))
        list.insert(s, at: i)
      }
    }
    self = list
  }
}

/// conversion between [Int] and PyObj
public extension Array where Element == Int {

  /// convert [Int] to PyObj
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

  /// convert PyObj to [Int]
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

/// conversion between [Double] and PyObj
public extension Array where Element == Double {

  /// convert [Double] to PyObj
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

  /// convert PyObj to [Double]
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


/// conversion between [String:Any] and PyObj
public extension Dictionary where Key == String, Value == Any {

  /// convert [String:Any] to PyObj
  public func python() -> PyObj? {
    return try? PyObj(value: self as Any)
  }

  /// convert PyObj to [String:Any]
  public init(python: PyObj) {
    if python.value is [String: Any], let v = python.value as? [String:Any] {
      self = v
    } else {
      self = [:]
    }
  }
}

/// Swift Wrapper Class of UnsafeMutablePointer<PyObject>
public class PyObj {

  /// reference pointer
  let ref: UnsafeMutablePointer<PyObject>

  /// if explicitly marked autoDealloc to false, the pointer will not be released
  public var autoDealloc = true

  /// Errors
  public enum Exception: Error {

    /// Python module importing failure
    case ImportFailure(String)

    /// Unsupported Python Type
    case InvalidType

    /// The array is unexpectedly null.
    case NullArray

    /// element can not be inserted
    case ElementInsertionFailure

    /// variable value can not be saved into the runtime context
    case ValueSavingFailure(String)

    /// unable to convert into a string
    case InvalidString
  }

  public static func LastError() -> String {
    var ptype: UnsafeMutablePointer<PyObject>? = nil
    var pvalue: UnsafeMutablePointer<PyObject>? = nil
    var ptraceback: UnsafeMutablePointer<PyObject>? = nil
    PyErr_Fetch(&ptype, &pvalue, &ptraceback)
    var m:[String:String] = ["error":"true"]
    /* skip type object
    if let p = ptype {
      let q = PyObj(p)
      if let v = q.value {
        m["type"] = "\(v)"
      }
    }*/
    if let p = pvalue {
      let q = PyObj(p)
      if let v = q.value {
        m["value"] = "\(v)"
      }
    }
    if let p = ptraceback {
      let q = PyObj(p)
      if let v = q.value {
        m["traceback"] = "\(v)"
      }
    }
    let n: [String] = m.map { "\"\($0.key)\": \"\($0.value)\"" }
    return "{" + n.joined(separator: ",") + "}"
  }

  /// Load a python module from the given path and turn the module into a PyObj
  /// - parameters: 
  ///   - path: String, the module directory
  ///   - import: String, the module name without path and suffix
  /// - throws: `Exception.ImportFailure`
  public init(path: String? = nil, `import`: String) throws {
    if let p = path {
      PySys_SetPath(UnsafeMutablePointer<CChar>(mutating: p))
    }

    if let reference = PyImport_ImportModule(`import`) {
      ref = reference
    } else {
      let err = PyObj.LastError()
      throw Exception.ImportFailure(err)
    }
  }

  /// Initialize a PyObj by its reference pointer
  /// - parameters:
  ///   - reference: UnsafeMutablePointer<PyObject>, the reference pointer
  public init(_ reference: UnsafeMutablePointer<PyObject>) {
    ref = reference
  }

  /// convert a Swift array to a python tuple object
  /// - parameters:
  ///   - arguments: [Any], the Swift array to convert
  /// - throws:
  ///   - Exception.NullArray, if python tuple can not be allocated.
  ///   - Exception.ElementInsertionFailure, if one elment of the given array can not be inserted into the objective python tuple
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

  /// convert a Swift constant to a PyObj, currently supported types include:
  /// Int, Float, Double, [Any], [String: Any] and PyObj itself.
  /// - throws: `Exception.InvalidType`, if the given type is not supported.
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
    } else if value is PyObj, let v = value as? PyObj {
      self.ref = v.ref
    } else {
      throw Exception.InvalidType
    }
  }

  /// get the type name
  public var `type`: String {
    return String(cString: ref.pointee.ob_type.pointee.tp_name)
  }

  /// automatically convert the current PyObj to a Swift constant.
  /// currently supported types are: str, int, float, list, dict, 
  /// otherwise will be null.
  public var value: Any? {
    let v: Any?
    switch self.type {
    //case "type": - this may be useful for PyTypeObject
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

  /// call a function by its name and the given arguments, if the PyObj itself
  /// is a module or a class instance.
  /// - parameters: 
  ///   - functionName: String, name of the function to call
  ///   - args: [Any]?, the arguement array.
  /// - returns: PyObj?
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
      result = PyObject_CallObject(function, nil)
    }
    return PyObj(result)
  }

  /// initialize the current python object to a class instance.
  /// for example, suppose there is a class called "Person" and can be 
  /// initialized with two properties: name and age. then 
  /// ``` 
  /// let personClass = try PyObj(path:, import:) 
  /// ``` 
  /// can get the class, and
  /// ``` 
  /// let person = personClass?.construct(["rocky", 24]) 
  /// ```
  /// will get the object instance.
  /// - parameters:
  ///   - arguements: [Any]?, optional parameters to initialize the instance.
  /// - returns: PyObj?
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

  /// load a variable by its name.
  /// - parameters:
  ///   - variableName: String, name of the variable to load
  /// - returns: PyObj?
  public func load(_ variableName: String) -> PyObj? {
    if let reference = PyObject_GetAttrString(ref, variableName) {
      return PyObj(reference)
    } else {
      return nil
    }
  }

  /// save a variable with a new value and by its name
  /// - parameters:
  ///   - variableName: String, name of the variable to save
  ///   - newValue: new value to save
  /// - throws: `Exception.ValueSavingFailure`
  public func save(_ variableName: String, newValue: Any) throws {
    let value = try PyObj(value: newValue)
    guard 0 == PyObject_SetAttrString(ref, variableName, value.ref) else {
      throw Exception.ValueSavingFailure(PyObj.LastError())
    }
  }

  deinit {
    if autoDealloc {
      Py_DecRef(ref)
    }
  }

  /// get version info 
  public static var Version: String? {
    if let module = PyImport_ImportModule("sys"),
      let sys = PyModule_GetDict(module),
      let verObj = PyMapping_GetItemString(sys, UnsafeMutablePointer<Int8>(mutating: "version")),
      let verstr = PyString_AsString(verObj) {
      let version = String(cString: verstr)
      Py_DecRef(verObj)
      Py_DecRef(module)
      return version
    } else {
      return nil
    }
  }
}
