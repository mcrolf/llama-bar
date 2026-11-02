import Foundation

/// Runs the repo's scripts and system tools. GUI apps inherit a minimal PATH,
/// so Homebrew's bin directories are prepended for `ollama` and `opencode`.
enum Shell {
    struct Failure: LocalizedError {
        let command: String
        let status: Int32
        let errorOutput: String

        var errorDescription: String? {
            "\(command) failed (exit \(status))" + (errorOutput.isEmpty ? "" : ": \(errorOutput)")
        }
    }

    /// Runs `executable` to completion and returns its standard output.
    static func run(_ executable: URL, _ arguments: [String] = []) async throws -> Data {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = executable
            process.arguments = arguments
            process.environment = environmentWithHomebrew()
            let output = Pipe()
            let errors = Pipe()
            process.standardOutput = output
            process.standardError = errors
            try process.run()

            // Drain stderr concurrently so a chatty command cannot fill the pipe and stall.
            let errorData = Task.detached { errors.fileHandleForReading.readDataToEndOfFile() }
            let outputData = output.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            let errorText = String(decoding: await errorData.value, as: UTF8.self)

            guard process.terminationStatus == 0 else {
                throw Failure(
                    command: ([executable.lastPathComponent] + arguments).joined(separator: " "),
                    status: process.terminationStatus,
                    errorOutput: errorText.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            return outputData
        }.value
    }

    static func launchctl(_ arguments: String...) async throws {
        _ = try await run(URL(fileURLWithPath: "/bin/launchctl"), arguments)
    }

    private static func environmentWithHomebrew() -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + (environment["PATH"] ?? "/usr/bin:/bin")
        return environment
    }
}
