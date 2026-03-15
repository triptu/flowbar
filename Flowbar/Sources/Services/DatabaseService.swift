import Foundation
import SQLite3

/// Persistence layer backed by SQLite. Stores timer sessions and app key-value state.
///
/// Accessed via DatabaseService.shared singleton. TimerService calls into this for all
/// session CRUD operations; AppState does not use the database directly.
/// The database file lives in ~/Library/Application Support/Flowbar/flowbar.sqlite.
@MainActor
final class DatabaseService {
    static let shared = DatabaseService()
    private var db: OpaquePointer?

    private init() {
        openDatabase()
        createTables()
    }

    private func openDatabase() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("Flowbar", isDirectory: true)
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        let dbPath = appDir.appendingPathComponent("flowbar.sqlite").path

        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("Failed to open database at \(dbPath)")
        }
    }

    private func createTables() {
        let sql = """
        CREATE TABLE IF NOT EXISTS timer_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            todo_text TEXT NOT NULL,
            source_file TEXT NOT NULL,
            started_at REAL NOT NULL,
            ended_at REAL,
            completed INTEGER DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS app_state (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        );
        """
        sqlite3_exec(db, sql, nil, nil, nil)
        migrate()
    }

    private func migrate() {
        // paused_elapsed: NULL = running, non-NULL = paused with this many seconds elapsed
        sqlite3_exec(db, "ALTER TABLE timer_sessions ADD COLUMN paused_elapsed REAL", nil, nil, nil)
        // accumulated: total elapsed from previous run segments (before the current started_at)
        sqlite3_exec(db, "ALTER TABLE timer_sessions ADD COLUMN accumulated REAL DEFAULT 0", nil, nil, nil)
    }

    // MARK: - Timer Sessions

    @discardableResult
    func startSession(todoText: String, sourceFile: String) -> Int64 {
        let sql = "INSERT INTO timer_sessions (todo_text, source_file, started_at) VALUES (?, ?, ?)"
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        sqlite3_bind_text(stmt, 1, (todoText as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (sourceFile as NSString).utf8String, -1, nil)
        sqlite3_bind_double(stmt, 3, Date().timeIntervalSince1970)
        sqlite3_step(stmt)
        let rowId = sqlite3_last_insert_rowid(db)
        sqlite3_finalize(stmt)
        return rowId
    }

    func endSession(id: Int64, completed: Bool) {
        let sql = "UPDATE timer_sessions SET ended_at = ?, completed = ? WHERE id = ?"
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        sqlite3_bind_double(stmt, 1, Date().timeIntervalSince1970)
        sqlite3_bind_int(stmt, 2, completed ? 1 : 0)
        sqlite3_bind_int64(stmt, 3, id)
        sqlite3_step(stmt)
        sqlite3_finalize(stmt)
    }

    func totalTime(forTodo text: String, sourceFile: String) -> TimeInterval {
        let sql = "SELECT SUM(COALESCE(accumulated, 0) + ended_at - started_at) FROM timer_sessions WHERE todo_text = ? AND source_file = ? AND ended_at IS NOT NULL"
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        sqlite3_bind_text(stmt, 1, (text as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (sourceFile as NSString).utf8String, -1, nil)
        var total: TimeInterval = 0
        if sqlite3_step(stmt) == SQLITE_ROW {
            total = sqlite3_column_double(stmt, 0)
        }
        sqlite3_finalize(stmt)
        return total
    }

    /// Batch query: returns total time per todo (key = "todoText|sourceFile")
    func allTotalTimes() -> [String: TimeInterval] {
        let sql = "SELECT todo_text, source_file, SUM(COALESCE(accumulated, 0) + ended_at - started_at) as total FROM timer_sessions WHERE ended_at IS NOT NULL GROUP BY todo_text, source_file"
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        defer { sqlite3_finalize(stmt) }
        var result: [String: TimeInterval] = [:]
        while sqlite3_step(stmt) == SQLITE_ROW {
            let text = String(cString: sqlite3_column_text(stmt, 0))
            let source = String(cString: sqlite3_column_text(stmt, 1))
            let total = sqlite3_column_double(stmt, 2)
            result["\(text)|\(source)"] = total
        }
        return result
    }

    func pauseSession(id: Int64, elapsed: TimeInterval) {
        let sql = "UPDATE timer_sessions SET paused_elapsed = ? WHERE id = ?"
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        sqlite3_bind_double(stmt, 1, elapsed)
        sqlite3_bind_int64(stmt, 2, id)
        sqlite3_step(stmt)
        sqlite3_finalize(stmt)
    }

    func resumeSession(id: Int64) {
        let sql = "UPDATE timer_sessions SET accumulated = COALESCE(accumulated, 0) + COALESCE(paused_elapsed, 0), paused_elapsed = NULL, started_at = ? WHERE id = ?"
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        sqlite3_bind_double(stmt, 1, Date().timeIntervalSince1970)
        sqlite3_bind_int64(stmt, 2, id)
        sqlite3_step(stmt)
        sqlite3_finalize(stmt)
    }

    func activeSession() -> (id: Int64, todoText: String, sourceFile: String, startedAt: Date, pausedElapsed: TimeInterval?, accumulated: TimeInterval)? {
        let sql = "SELECT id, todo_text, source_file, started_at, paused_elapsed, COALESCE(accumulated, 0) FROM timer_sessions WHERE ended_at IS NULL LIMIT 1"
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        defer { sqlite3_finalize(stmt) }
        if sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let text = String(cString: sqlite3_column_text(stmt, 1))
            let source = String(cString: sqlite3_column_text(stmt, 2))
            let started = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 3))
            let paused: TimeInterval? = sqlite3_column_type(stmt, 4) != SQLITE_NULL ? sqlite3_column_double(stmt, 4) : nil
            let accumulated = sqlite3_column_double(stmt, 5)
            return (id, text, source, started, paused, accumulated)
        }
        return nil
    }

    /// Returns today's sessions grouped by todo text, with total duration per todo, ordered by most recent.
    func todaySessions() -> [(todoText: String, sourceFile: String, totalDuration: TimeInterval)] {
        let startOfDay = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        let sql = """
        SELECT todo_text, source_file, SUM(COALESCE(accumulated, 0) + ended_at - started_at) as total
        FROM timer_sessions
        WHERE started_at >= ? AND ended_at IS NOT NULL AND ended_at > started_at
        GROUP BY todo_text, source_file
        ORDER BY MAX(ended_at) DESC
        """
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        sqlite3_bind_double(stmt, 1, startOfDay)
        defer { sqlite3_finalize(stmt) }
        var results: [(String, String, TimeInterval)] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let text = String(cString: sqlite3_column_text(stmt, 0))
            let file = String(cString: sqlite3_column_text(stmt, 1))
            let total = sqlite3_column_double(stmt, 2)
            results.append((text, file, total))
        }
        return results
    }

    // MARK: - App State

    func setState(key: String, value: String) {
        let sql = "INSERT OR REPLACE INTO app_state (key, value) VALUES (?, ?)"
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        sqlite3_bind_text(stmt, 1, (key as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (value as NSString).utf8String, -1, nil)
        sqlite3_step(stmt)
        sqlite3_finalize(stmt)
    }

    func getState(key: String) -> String? {
        let sql = "SELECT value FROM app_state WHERE key = ?"
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        sqlite3_bind_text(stmt, 1, (key as NSString).utf8String, -1, nil)
        defer { sqlite3_finalize(stmt) }
        if sqlite3_step(stmt) == SQLITE_ROW {
            return String(cString: sqlite3_column_text(stmt, 0))
        }
        return nil
    }
}
