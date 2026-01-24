import Foundation
import SQLite3

struct LegalChunk {
    let id: Int64
    let docId: String
    let docName: String
    let pageNumber: Int
    let chunkIndex: Int
    let text: String
    let embedding: [Float]
}

struct LegalChunkInsert {
    let docId: String
    let docName: String
    let pageNumber: Int
    let chunkIndex: Int
    let text: String
    let embedding: [Float]
}

final class LegalIndexStore {
    private var db: OpaquePointer?
    private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    init() throws {
        let url = try Self.databaseURL()
        if sqlite3_open(url.path, &db) != SQLITE_OK {
            throw SQLiteError.openDatabase
        }
        try createTables()
    }

    deinit {
        sqlite3_close(db)
    }

    func hasAnyChunks() -> Bool {
        let query = "SELECT COUNT(*) FROM legal_chunks;"
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }

        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else { return false }
        guard sqlite3_step(statement) == SQLITE_ROW else { return false }
        let count = sqlite3_column_int(statement, 0)
        print("[LegalIndexStore] chunks count: \(count)")
        return count > 0
    }

    func insertChunks(_ chunks: [LegalChunkInsert]) throws {
        guard !chunks.isEmpty else { return }
        print("[LegalIndexStore] inserting \(chunks.count) chunks")
        let insertSQL = "INSERT INTO legal_chunks (doc_id, doc_name, page_number, chunk_index, text, embedding) VALUES (?, ?, ?, ?, ?, ?);"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) != SQLITE_OK {
            throw SQLiteError.prepareStatement
        }

        try exec("BEGIN TRANSACTION;")
        defer {
            sqlite3_finalize(statement)
            try? exec("COMMIT;")
        }

        for chunk in chunks {
            sqlite3_reset(statement)
            sqlite3_clear_bindings(statement)

            bindText(statement, index: 1, value: chunk.docId)
            bindText(statement, index: 2, value: chunk.docName)
            sqlite3_bind_int(statement, 3, Int32(chunk.pageNumber))
            sqlite3_bind_int(statement, 4, Int32(chunk.chunkIndex))
            bindText(statement, index: 5, value: chunk.text)

            let data = Self.data(from: chunk.embedding)
            data.withUnsafeBytes { rawBuffer in
                sqlite3_bind_blob(statement, 6, rawBuffer.baseAddress, Int32(data.count), sqliteTransient)
            }

            if sqlite3_step(statement) != SQLITE_DONE {
                throw SQLiteError.stepFailed
            }
        }
    }

    func loadAllChunks() throws -> [LegalChunk] {
        let query = "SELECT id, doc_id, doc_name, page_number, chunk_index, text, embedding FROM legal_chunks;"
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }

        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteError.prepareStatement
        }

        var chunks: [LegalChunk] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let docId = String(cString: sqlite3_column_text(statement, 1))
            let docName = String(cString: sqlite3_column_text(statement, 2))
            let pageNumber = Int(sqlite3_column_int(statement, 3))
            let chunkIndex = Int(sqlite3_column_int(statement, 4))
            let text = String(cString: sqlite3_column_text(statement, 5))
            let blobPointer = sqlite3_column_blob(statement, 6)
            let blobSize = Int(sqlite3_column_bytes(statement, 6))
            let data = blobPointer.map { Data(bytes: $0, count: blobSize) } ?? Data()
            let embedding = Self.floats(from: data)
            chunks.append(LegalChunk(id: id, docId: docId, docName: docName, pageNumber: pageNumber, chunkIndex: chunkIndex, text: text, embedding: embedding))
        }
        print("[LegalIndexStore] loaded \(chunks.count) chunks")
        return chunks
    }

    private func createTables() throws {
        let createSQL = """
        CREATE TABLE IF NOT EXISTS legal_chunks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            doc_id TEXT NOT NULL,
            doc_name TEXT NOT NULL,
            page_number INTEGER NOT NULL,
            chunk_index INTEGER NOT NULL,
            text TEXT NOT NULL,
            embedding BLOB NOT NULL
        );
        """
        try exec(createSQL)
    }

    private func exec(_ sql: String) throws {
        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            throw SQLiteError.execFailed
        }
    }

    private func bindText(_ statement: OpaquePointer?, index: Int32, value: String) {
        sqlite3_bind_text(statement, index, (value as NSString).utf8String, -1, sqliteTransient)
    }

    private static func databaseURL() throws -> URL {
        let baseURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return baseURL.appendingPathComponent("legal_index.sqlite3")
    }

    private static func data(from floats: [Float]) -> Data {
        floats.withUnsafeBufferPointer { buffer in
            Data(buffer: buffer)
        }
    }

    private static func floats(from data: Data) -> [Float] {
        data.withUnsafeBytes { rawBuffer in
            let buffer = rawBuffer.bindMemory(to: Float.self)
            return Array(buffer)
        }
    }
}

enum SQLiteError: Error {
    case openDatabase
    case execFailed
    case prepareStatement
    case stepFailed
}
