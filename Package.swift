// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

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

import PackageDescription

let package = Package(
    name: "PerfectPython",
    products: [
        .library(
            name: "PerfectPython",
            targets: ["PerfectPython"]),
    ],
    targets: [
      .target(name: "PythonAPI", dependencies: []),
      .target(name: "PerfectPython", dependencies: ["PythonAPI"]),
      .testTarget(name: "PerfectPythonTests", dependencies: ["PerfectPython"])
    ]
)
