import Foundation

/// Wraps `Process` so callers can `await` a shell-out command and receive
/// live stdout/stderr lines as they arrive, which we feed into LogStore
/// for display in the UI.
enum ShellError: Error, LocalizedError {
    case failedToLaunch(String)
    case nonZeroExit(Int32)

    var errorDescription: String? {
        switch self {
        case .failedToLaunch(let reason):
            return "Failed to launch process: \(reason)"
        case .nonZeroExit(let code):
            return "Process exited with status \(code)"
        }
    }
}

enum Shell {

    /// Runs an executable with arguments and environment, streaming each
    /// output line to `onOutput` as it's produced. Throws if the process
    /// exits non-zero.
    @discardableResult
    static func run(
        _ executablePath: String,
        arguments: [String],
        environment: [String: String] = [:],
        onOutput: @escaping (String) -> Void = { _ in }
    ) async throws -> Int32 {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = arguments

            var env = ProcessInfo.processInfo.environment
            for (key, value) in environment {
                env[key] = value
            }
            process.environment = env

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            func drain(_ pipe: Pipe) {
                pipe.fileHandleForReading.readabilityHandler = { handle in
                    let data = handle.availableData
                    guard !data.isEmpty else { return }
                    if let text = String(data: data, encoding: .utf8) {
                        text.split(separator: "\n", omittingEmptySubsequences: true)
                            .forEach { onOutput(String($0)) }
                    }
                }
            }
            drain(stdoutPipe)
            drain(stderrPipe)

            process.terminationHandler = { proc in
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                if proc.terminationStatus == 0 {
                    continuation.resume(returning: proc.terminationStatus)
                } else {
                    continuation.resume(throwing: ShellError.nonZeroExit(proc.terminationStatus))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: ShellError.failedToLaunch(error.localizedDescription))
            }
        }
    }

    /// Fire-and-forget launch (used for launching GUI apps like winecfg or
    /// an installed game, where we don't want to block waiting for exit).
    static func launchDetached(
        _ executablePath: String,
        arguments: [String],
        environment: [String: String] = [:]
    ) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        var env = ProcessInfo.processInfo.environment
        for (key, value) in environment { env[key] = value }
        process.environment = env
        try process.run()
    }
}
