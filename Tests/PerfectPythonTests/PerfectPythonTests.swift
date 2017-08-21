//
//  PerfectPythonTests.swift
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
import XCTest
@testable import PythonAPI
@testable import PerfectPython

class PerfectPythonTests: XCTestCase {

    override func setUp() {
      Py_Initialize()
      var program = "class Person:\n\tdef __init__(self, name, age):\n\t\tself.name = name\n\t\tself.age = age\n\tdef intro(self):\n\t\treturn 'Name: ' + self.name + ', Age: ' + str(self.age)\n"
      var path = "/tmp/clstest.py"
      var f = fopen(path, "w")
      _ = program.withCString { pstr -> Int in
        return fwrite(pstr, 1, program.characters.count, f)
      }
      fclose(f)
      program = "def mymul(num1, num2):\n\treturn num1 * num2;\n\ndef mydouble(num):\n\treturn num * 2;\n\nstringVar = 'Hello, world'\nlistVar = ['rocky', 505, 2.23, 'wei', 70.2]\ndictVar = {'Name': 'Rocky', 'Age': 17, 'Class': 'Top'};\n"
      path = "/tmp/helloworld.py"
      f = fopen(path, "w")
      _ = program.withCString { pstr -> Int in
        return fwrite(pstr, 1, program.characters.count, f)
      }
      fclose(f)
    }

    override func tearDown() {
      //Py_Finalize()
      unlink("/tmp/clstest.py")
    }

    func testExample() {
      let p = PyObject()
      print(p)
    }

    func testVersion() {
      if let module = PyImport_ImportModule("sys"),
        let sys = PyModule_GetDict(module),
        let verObj = PyMapping_GetItemString(sys, UnsafeMutablePointer<Int8>(mutating: "version")),
        let verstr = PyString_AsString(verObj),
        let _ = strstr(verstr, "2.7") {
        print(String(cString: verstr))
        Py_DecRef(verObj)
        Py_DecRef(module)
      } else {
        XCTFail("version checking failed")
      }
    }

  func testClass2() {
    do {
      let pymod = try PyObj(path: "/tmp", import: "clstest")
      if let personClass = pymod.load("Person"),
        let person = personClass.construct(["rocky", 24]),
        let name = person.load("name")?.value as? String,
        let age = person.load("age")?.value as? Int,
        let intro = person.call("intro")?.value as? String {
          XCTAssertEqual(name, "rocky")
          XCTAssertEqual(age, 24)
          print(intro)
      }
    }catch {
      XCTFail(error.localizedDescription)
    }
  }

    func testClass() {
      PySys_SetPath(UnsafeMutablePointer<Int8>(mutating: "/tmp"))
      if let module = PyImport_ImportModule("clstest"),
        let personClass = PyObject_GetAttrString(module, "Person"),
        let args = PyTuple_New(2),
        let name = PyString_FromString("Rocky"),
        let age = PyInt_FromLong(24),
        PyTuple_SetItem(args, 0, name) == 0,
        PyTuple_SetItem(args, 1, age) == 0,
        let personObj = PyInstance_New(personClass, args, nil),
        let introFunc = PyObject_GetAttrString(personObj, "intro"),
        let introRes = PyObject_CallObject(introFunc, nil),
        let intro = PyString_AsString(introRes)
      {
        print(String(cString: intro))
        Py_DecRef(personObj)
        Py_DecRef(introFunc)
        Py_DecRef(introRes)
        Py_DecRef(args)
        Py_DecRef(name)
        Py_DecRef(age)
        Py_DecRef(personClass)
        Py_DecRef(module)
      } else {
        XCTFail("class variable failed")
      }
    }

  func testBasic2() {
    let program = "def mymul(num1, num2):\n\treturn num1 * num2;\n\nstringVar = 'Hello, world'\nlistVar = ['rocky', 505, 2.23, 'wei', 70.2]\ndictVar = {'Name': 'Rocky', 'Age': 17, 'Class': 'Top'};\n"
    let path = "/tmp/hola.py"
    let f = fopen(path, "w")
    _ = program.withCString { pstr -> Int in
      return fwrite(pstr, 1, program.characters.count, f)
    }
    fclose(f)

    do {
      let pymod = try PyObj(path: "/tmp", import: "hola")
      if let res = pymod.call("mymul", args: [2,3]),
        let ires = res.value as? Int {
        XCTAssertEqual(ires, 6)
      } else {
        XCTFail("function call failure")
      }
      let testString = "Hola, 🇨🇳🇨🇦"
      if let str = pymod.load("stringVar") {
        do {
          XCTAssertEqual(str.value as? String ?? "failed", "Hello, world")
          try pymod.save("stringVar", newValue: testString)
        }catch{
          XCTFail(error.localizedDescription)
        }
      } else {
        XCTFail("string call failure")
      }
      if let str2 = pymod.load("stringVar") {
        XCTAssertEqual(str2.value as? String ?? "failed", testString)
      } else {
        XCTFail("string call failure")
      }
      if let listObj = pymod.load("listVar"),
        let list = listObj.value as? [Any] {
        XCTAssertEqual(list.count, 5)
        print(list)
      } else {
        XCTFail("loading list failure")
      }
      if let dictObj = pymod.load("dictVar"),
        let dict = dictObj.value as? [String:Any] {
        XCTAssertEqual(dict.count, 3)
        print(dict)
      }
    }catch {
      XCTFail(error.localizedDescription)
    }

  }

    func testBasic() {
      PySys_SetPath(UnsafeMutablePointer<Int8>(mutating: "/tmp"))
      if let module = PyImport_ImportModule("helloworld"),
        let function = PyObject_GetAttrString(module, "mydouble"),
        let num = PyInt_FromLong(2),
        let args = PyTuple_New(1),
        PyTuple_SetItem(args, 0, num) == 0,
        let res = PyObject_CallObject(function, args) {
        let four = PyInt_AsLong(res)
        XCTAssertEqual(four, 4)
        if let strObj = PyObject_GetAttrString(module, "stringVar"),
          let pstr = PyString_AsString(strObj) {
          let strvar = String(cString: pstr)
          print(strvar)
          Py_DecRef(function)
          Py_DecRef(args)
          Py_DecRef(num)
          Py_DecRef(res)
          Py_DecRef(strObj)
        } else {
          XCTFail("string variable failed")
        }
        if let listObj = PyObject_GetAttrString(module, "listVar") {
          XCTAssertEqual(String(cString: listObj.pointee.ob_type.pointee.tp_name), "list")
          let size = PyList_Size(listObj)
          XCTAssertEqual(size, 5)
          for i in 0 ..< size {
            if let item = PyList_GetItem(listObj, i) {
              let j = item.pointee
              let tpName = String(cString: j.ob_type.pointee.tp_name)
              let v: Any?
              switch tpName {
              case "str":
                v = String(cString: PyString_AsString(item))
                break
              case "int":
                v = PyInt_AsLong(item)
              case "float":
                v = PyFloat_AsDouble(item)
              default:
                v = nil
              }
              if let v = v {
                print(i, tpName, v)
              } else {
                print(i, tpName, "Unknown")
              }
              Py_DecRef(item)
            }
          }
          Py_DecRef(listObj)
        } else {
          XCTFail("list variable failed")
        }

        if let dicObj = PyObject_GetAttrString(module, "dictVar"),
          let keys = PyDict_Keys(dicObj) {
          XCTAssertEqual(String(cString: dicObj.pointee.ob_type.pointee.tp_name), "dict")
          let size = PyDict_Size(dicObj)
          XCTAssertEqual(size, 3)
          for i in 0 ..< size {
            guard let key = PyList_GetItem(keys, i),
              let item = PyDict_GetItem(dicObj, key) else {
                continue
            }
            let keyName = String(cString: PyString_AsString(key))
            let j = item.pointee
            let tpName = String(cString: j.ob_type.pointee.tp_name)
            let v: Any?
            switch tpName {
            case "str":
              v = String(cString: PyString_AsString(item))
              break
            case "int":
              v = PyInt_AsLong(item)
            case "float":
              v = PyFloat_AsDouble(item)
            default:
              v = nil
            }
            if let v = v {
              print(keyName, tpName, v)
            } else {
              print(keyName, tpName, "Unknown")
            }
            Py_DecRef(item)
          }
          Py_DecRef(keys)
          Py_DecRef(dicObj)
        } else {
          XCTFail("dictionary variable failed")
        }
        Py_DecRef(module)
      } else {
        XCTFail("library import failed")
      }
    }

    static var allTests = [
      ("testExample", testExample),
      ("testVersion", testVersion),
      ("testBasic", testBasic),
      ("testBasic2", testBasic2),
      ("testClass", testClass),
      ("testClass2", testClass2)
      ]}
