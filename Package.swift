// swift-tools-version:5.3
//
// Package.swift - Swift Package Manager configuration for Singularity TreeSitterMermaid
//
// This file defines the Swift package for Singularity tree-sitter-mermaid, which provides
// Swift bindings for parsing Mermaid diagram syntax using tree-sitter.
//
// PACKAGE STRUCTURE:
// - Library: TreeSitterMermaid (main library target)
// - Tests: TreeSitterMermaidTests
// - Platform support: macOS 10.13+, iOS 11+
//
// DEPENDENCIES:
// - SwiftTreeSitter: Official Swift bindings for tree-sitter
//
// BUILD PROCESS:
// The package compiles the C parser (src/parser.c) and external scanner
// (src/scanner.c) as part of the Swift module. The parser is auto-generated
// from grammar.js by tree-sitter.
//
// USAGE:
// Add to your Package.swift dependencies:
//   .package(url: "https://github.com/Singularity-ng/singularity-parser-mermaid.git", from: "0.9.1")
//
// Then import in your Swift code:
//   import TreeSitterMermaid
//   parser.setLanguage(TreeSitterMermaid.language)
//
// RESOURCES:
// The package includes tree-sitter query files (queries/*.scm) for syntax
// highlighting and other editor integration features.

import PackageDescription

let package = Package(
    // Package name (version is determined by git tags)
    name: "SingularityTreeSitterMermaid",

    // Minimum supported platforms
    platforms: [.macOS(.v10_13), .iOS(.v11)],

    // Library products exported by this package
    products: [
        .library(name: "TreeSitterMermaid", targets: ["TreeSitterMermaid"]),
    ],

    // External dependencies
    dependencies: [
        .package(url: "https://github.com/tree-sitter/swift-tree-sitter.git", from: "0.1.0")
    ],

    targets: [
        // C parser target - compiled separately
        .target(
            name: "TreeSitterMermaidC",
            path: ".",
            exclude: [
                "Cargo.toml",
                "Makefile",
                "binding.gyp",
                "bindings",
                "grammar.js",
                "package.json",
                "pyproject.toml",
                "setup.py",
                "test",
                "examples",
                "Tests",
                ".editorconfig",
                ".github",
                ".gitignore",
                ".gitattributes",
                "CHANGELOG.md",
                "CODE_OF_CONDUCT.md",
                "CONTRIBUTING.md",
                "LICENSE",
                "README.md",
                "SECURITY.md",
                "Brewfile",
                "Package.swift",
                "check-mermaid-spec.sh",
                "docker-compose.yml",
                "shell.nix",
                "tree-sitter.json",
                "queries",
                "dist",
                "docs",
            ],
            sources: [
                "src/parser.c",
                "src/scanner.c",
            ],
            publicHeadersPath: "bindings/swift",
            cSettings: [.headerSearchPath("src")]
        ),

        // Swift wrapper target
        .target(
            name: "TreeSitterMermaid",
            dependencies: [
                "TreeSitterMermaidC",
                .product(name: "SwiftTreeSitter", package: "swift-tree-sitter")
            ],
            path: "bindings/swift",
            resources: [
                .copy("../../queries")
            ]
        ),

        // Test target for the Swift package
        .testTarget(
            name: "TreeSitterMermaidTests",
            dependencies: [
                "TreeSitterMermaid",
                .product(name: "SwiftTreeSitter", package: "swift-tree-sitter")
            ],
            path: "Tests"
        )
    ],

    // Require C11 standard for parser compilation
    cLanguageStandard: .c11
)
