#!/usr/bin/swift sh

import Foundation
import XcodeProj  // @tuist ~> 7.14.0
import PathKit

func findProject() throws -> XcodeProj? {
    let fm = FileManager.default
    let items = try fm.contentsOfDirectory(atPath: fm.currentDirectoryPath)

    var projectFileURL: URL?
    for item in items {
        let url = URL(fileURLWithPath: item)
        if url.pathExtension == "xcodeproj" {
            projectFileURL = url
            break
        }
    }

    guard let projectFilePath = projectFileURL?.path else {
        return nil
    }

    return try XcodeProj(path: Path(projectFilePath))
}

func findVersion(project: XcodeProj) -> String? {
    let version = project.pbxproj.buildConfigurations.compactMap {
        $0.buildSettings["MARKETING_VERSION"]
    }.first

    let build = project.pbxproj.buildConfigurations.compactMap {
        $0.buildSettings["CURRENT_PROJECT_VERSION"]
    }.first

    if version == nil || build == nil {
        return nil
    }

    return "\(version!).\(build!)"
}

func shell(_ command: String) -> String {
    let task = Process()
    let pipe = Pipe()

    task.standardOutput = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/bash"
    task.launch()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!

    return output
}

guard let xcodeproj = try findProject() else {
    print("Project file not found")
    exit(1)
}
guard let currentVersion = findVersion(project: xcodeproj) else {
    print("Version not found")
    exit(1)
}

let currentTag = "v\(currentVersion)"
let tags = shell("git tag -l")

if tags.contains(currentTag) {
    print("Tag \(currentTag) exists")
    exit(1)
}

print("Tag \(currentTag) available")