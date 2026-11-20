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
    ///
    /// `workingDirectory` matters for Wine: many Windows programs load
    /// files relative to the current directory, and an app launched from
    /// Finder otherwise inherits `/` as its working directory.
    @discardableResult
    static func run(
        _ executablePath: String,
        arguments: [String],
        environment: [String: String] = [:],
        workingDirectory: String? = nil,
        onOutput: @escaping (String) -> Void = { _ in }
    ) async throws -> Int32 {
        try await withCheckedThrowingContinuation { continuation in
            let process = makeProcess(executablePath, arguments, environment, workingDirectory)
            let pipes = attachOutputPipes(to: process, onOutput: onOutput)

            process.terminationHandler = { proc in
                finishDraining(pipes, onOutput: onOutput)
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
    /// Output is still streamed to `onOutput` and the exit status reported
    /// to `onExit`, so a crash on startup shows up in the log console
    /// instead of vanishing.
    static func launchDetached(
        _ executablePath: String,
        arguments: [String],
        environment: [String: String] = [:],
        workingDirectory: String? = nil,
        onOutput: ((String) -> Void)? = nil,
        onExit: ((Int32) -> Void)? = nil
    ) throws {
        let process = makeProcess(executablePath, arguments, environment, workingDirectory)
        if let onOutput {
            let pipes = attachOutputPipes(to: process, onOutput: onOutput)
            process.terminationHandler = { proc in
                finishDraining(pipes, onOutput: onOutput)
                onExit?(proc.terminationStatus)
            }
        } else if let onExit {
            process.terminationHandler = { proc in onExit(proc.terminationStatus) }
        }
        try process.run()
    }

    // MARK: - Helpers

    private static func makeProcess(
        _ executablePath: String,
        _ arguments: [String],
        _ environment: [String: String],
        _ workingDirectory: String?
    ) -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        var env = ProcessInfo.processInfo.environment
        for (key, value) in environment { env[key] = value }
        process.environment = env

        if let workingDirectory, FileManager.default.fileExists(atPath: workingDirectory) {
            process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        }
        return process
    }

    private static func attachOutputPipes(to process: Process, onOutput: @escaping (String) -> Void) -> [Pipe] {
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        for pipe in [stdoutPipe, stderrPipe] {
            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }
                emitLines(data, onOutput: onOutput)
            }
        }
        return [stdoutPipe, stderrPipe]
    }

    /// Stops the async readers, then grabs whatever is still buffered in
    /// the pipes. This must NOT use `readDataToEndOfFile()`: Wine programs
    /// often spawn children that inherit the pipe (e.g. an installer whose
    /// last step launches the app it just installed), so end-of-file never
    /// arrives and the read blocks until that child quits — which left the
    /// install spinner stuck forever.
    private static func finishDraining(_ pipes: [Pipe], onOutput: @escaping (String) -> Void) {
        for pipe in pipes {
            pipe.fileHandleForReading.readabilityHandler = nil
            let remaining = readAvailableWithoutBlocking(pipe.fileHandleForReading)
            if !remaining.isEmpty { emitLines(remaining, onOutput: onOutput) }
        }
    }

    private static func readAvailableWithoutBlocking(_ handle: FileHandle) -> Data {
        let fd = handle.fileDescriptor
        let flags = fcntl(fd, F_GETFL)
        guard flags >= 0 else { return Data() }
        _ = fcntl(fd, F_SETFL, flags | O_NONBLOCK)

        var result = Data()
        var buffer = [UInt8](repeating: 0, count: 64 * 1024)
        while true {
            let count = buffer.withUnsafeMutableBytes { read(fd, $0.baseAddress, $0.count) }
            if count <= 0 { break }   // 0 = EOF, -1 = nothing more right now (EAGAIN)
            result.append(contentsOf: buffer[0..<count])
        }
        return result
    }

    private static func emitLines(_ data: Data, onOutput: (String) -> Void) {
        let text = String(decoding: data, as: UTF8.self)
        text.split(whereSeparator: \.isNewline)
            .forEach { onOutput(String($0)) }
    }
}
