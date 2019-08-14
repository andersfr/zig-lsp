const std = @import("std");
const warn = std.debug.warn;

const ZigParser = @import("zig/zig_parser.zig").Parser;
const ZigNode = @import("zig/zig_parser.zig").Node;

usingnamespace @import("json/json.zig");

const allocator = std.heap.c_allocator;

var stdout_file: std.fs.File = undefined;
var stdout: std.fs.File.OutStream = undefined;

const initialize_response =
    \\,"jsonrpc":"2.0","result":{"capabilities":{"signatureHelpProvider":{"triggerCharacters":["(",","]},"textDocumentSync":1,"completionProvider":{"resolveProvider":false,"triggerCharacters":[".",":"]},"documentHighlightProvider":false,"codeActionProvider":false,"workspace":{"workspaceFolders":{"supported":true}}}}}
    ;
const error_response =
    \\,"jsonrpc":"2.0","error":{"code":-32601,"message":"NotImplemented"}}
    ;
const null_result_response =
    \\,"jsonrpc":"2.0","result":null}
    ;
const empty_result_response =
    \\,"jsonrpc":"2.0","result":{}}
    ;
const empty_array_response =
    \\,"jsonrpc":"2.0","result":[]}
    ;
const edit_not_applied_response =
    \\,"jsonrpc":"2.0","result":{"applied":false,"failureReason":"feature not implemented"}}
    ;
const no_completions_response =
    \\,"jsonrpc":"2.0","result":{"isIncomplete":false,"items":[]}}
    ;

fn processSource(uri: []const u8, version: usize, source: []const u8) !void {
    var parser = try ZigParser.init(std.heap.c_allocator);
    defer parser.deinit();

    if(try parser.run(source)) {
        // try debug.stream.print("parsed {} v.{}\n", uri, version);
        var buffer = try std.Buffer.initSize(std.heap.c_allocator, 0);
        defer buffer.deinit();

        var stream = &std.io.BufferOutStream.init(&buffer).stream;
        try stream.write(
            \\{"jsonrpc":"2.0","method":"textDocument/publishDiagnostics","params":{"uri":
        );
        try stream.print("\"{}\",\"diagnostics\":[", uri);

        if(parser.engine.errors.len > 0) {
            var eit = parser.engine.errors.iterator(0);
            // Diagnostic: { range, severity?: number, code?: number|string, source?: string, message: string, relatedInformation?: ... }
            while(eit.next()) |err| {
                try stream.write(
                    \\{"range":{"start":{
                );
                try stream.print("\"line\":{},\"character\":{}", err.line-1, err.start-1);
                try stream.write(
                    \\},"end":{
                );
                try stream.print("\"line\":{},\"character\":{}", err.line-1, err.end);
                try stream.write(
                    \\}},"severity":1,"source":"zig-lsp","message":
                );
                try stream.print("\"{}\",\"code\":\"{}\"", @tagName(err.info), @enumToInt(err.info));
                try stream.write(
                    \\,"relatedInformation":[]},
                );
                // try debug.stream.print("{}\n", err);
            }
            buffer.list.len -= 1;
        }

        try stream.write(
            \\]}}
        );

        try stdout.stream.print("Content-Length: {}\r\n\r\n", buffer.len());
        try stdout.stream.write(buffer.toSlice());
    }
}

fn sendGenericRpcResponse(rpc_id: usize, response: []const u8) !bool {
    const rpc_id_digits = blk: {
        if(rpc_id == 0) break :blk 1;
        var digits: usize = 1;
        var value = rpc_id / 10;
        while(value != 0) : (value /= 10) { digits += 1; }
        break :blk digits;
    };
    try stdout.stream.print("Content-Length: {}\r\n\r\n{}\"id\":{}", response.len+rpc_id_digits+6, "{", rpc_id);
    try stdout.stream.write(response);
    return true;
}

fn processJsonRpc(jsonrpc: Json) !bool {
    const root = jsonrpc.root;

    // Verify version
    const rpc_version = root.v("jsonrpc").s("").?;

    if(std.mem.compare(u8, "2.0", rpc_version) != .Equal)
        return error.WrongVersion;

    // Get method
    const rpc_method = root.v("method").s("").?;

    // Get ID
    const rpc_maybe_id = root.v("id").u(null);
    const rpc_id = rpc_maybe_id orelse 0;

    // Get Params
    const rpc_params = root.v("params");

    // Process some methods
    if(std.mem.compare(u8, "textDocument/didOpen", rpc_method) == .Equal) {
        // Notification
        // textDocument: TextDocumentItem{ uri: string, languageId: string, version: number, text: string }
        const document = rpc_params.v("textDocument");
        const uri = document.v("uri").s("").?;
        const lang = document.v("languageId").s("").?;
        const version = document.v("version").u(0).?;
        const text = document.v("text").s("").?;

        try processSource(uri, version, text);
        return true;
    }
    else if(std.mem.compare(u8, "textDocument/didChange", rpc_method) == .Equal) {
        // Notification
        // textDocument: VersionedTextDocumentIdentifier{ uri: string, version: number|null }
        // contentChanges[ { range?: { start: Position{ line: number, character:number }, end: Position{} }, rangeLength?: number, text: string } ]
        const document = rpc_params.v("textDocument");
        const uri = document.v("uri").s("").?;
        const version = document.v("version").u(0).?;

        const change = rpc_params.v("contentChanges").at(0);
        const text = change.v("text").s("").?;

        try processSource(uri, version, text);
        return true;
    }
    else if(std.mem.compare(u8, "textDocument/didSave", rpc_method) == .Equal) {
        // Notification
        // textDocument: TextDocumentIdentifier{ uri: string }
        // text?: string
        const uri = rpc_params.v("textDocument").v("uri").s("").?;
        const text = rpc_params.v("text").s("").?;

        // try processSource(uri, 0, text);
        return true;
    }
    else if(std.mem.compare(u8, "textDocument/didClose", rpc_method) == .Equal) {
        // Notification
        // textDocument: TextDocumentIdentifier{ uri: string }
        const uri = rpc_params.v("textDocument").v("uri").s("").?;

        return true;
    }
    else if(std.mem.compare(u8, "textDocument/completion", rpc_method) == .Equal) {
        // textDocument: TextDocumentIdentifier{ uri: string }
        // position: Position{ line: number, character:number }
        // context?: CompletionContext { not very important }
        const uri = rpc_params.v("textDocument").v("uri").s("").?;
        const position = rpc_params.v("position");
        const iline = position.v("line").i(-1).?;
        const icharacter = position.v("character").i(-1).?;

        if(uri.len > 0 and iline >= 0 and icharacter >= 0) {
            const line = @bitCast(u64, iline);
            const character = @bitCast(u64, icharacter);
        }
        return try sendGenericRpcResponse(rpc_id, no_completions_response);
    }
    else if(std.mem.compare(u8, "textDocument/signatureHelp", rpc_method) == .Equal) {
        // Request
        // textDocument: TextDocumentIdentifier{ uri: string }
        // position: Position{ line: number, character:number }
        return try sendGenericRpcResponse(rpc_id, empty_array_response);
    }
    else if(std.mem.compare(u8, "textDocument/willSave", rpc_method) == .Equal) {
        // Notification
        // textDocument: TextDocumentIdentifier{ uri: string }
        // reason: number (Manual=1, AfterDelay=2, FocusOut=3)
        return true;
    }
    else if(std.mem.compare(u8, "textDocument/willSaveWaitUntil", rpc_method) == .Equal) {
        // Request
        // textDocument: TextDocumentIdentifier{ uri: string }
        // reason: number (Manual=1, AfterDelay=2, FocusOut=3)
        return try sendGenericRpcResponse(rpc_id, empty_array_response);
    }
    else if(std.mem.compare(u8, "initialize", rpc_method) == .Equal) {
        // Request
        // processId: number|null
        // rootPath?: string|null (deprecated)
        // rootUri: DocumentUri{} | null
        // initializeOptions?: any
        // capabilities: ClientCapabilities{ ... }
        // trace: 'off'|'messages'|'verbose' (defaults to off)
        // workspaceFolders: WorkspaceFolder[]|null
        return try sendGenericRpcResponse(rpc_id, initialize_response);
    }
    else if(std.mem.compare(u8, "initialized", rpc_method) == .Equal) {
        // Notification
        // params: empty
        return true;
    }
    else if(std.mem.compare(u8, "shutdown", rpc_method) == .Equal) {
        // Request
        // params: void
        return try sendGenericRpcResponse(rpc_id, null_result_response);
    }
    else if(std.mem.compare(u8, "exit", rpc_method) == .Equal) {
        // Notification
        // params: void
        return false;
    }
    else if(std.mem.compare(u8, "$/cancelRequest", rpc_method) == .Equal) {
        // Notification
        // id: number|string
        return true;
    }
    else if(std.mem.compare(u8, "workspace/didChangeWorkspaceFolders", rpc_method) == .Equal) {
        // Notification
        return true;
    }
    else if(std.mem.compare(u8, "workspace/didChangeConfiguration", rpc_method) == .Equal) {
        // Notification
        return true;
    }
    else if(std.mem.compare(u8, "workspace/didChangeWatchedFiles", rpc_method) == .Equal) {
        // Notification
        return true;
    }
    else if(std.mem.compare(u8, "workspace/symbol", rpc_method) == .Equal) {
        // Request
        return try sendGenericRpcResponse(rpc_id, null_result_response);
    }
    else if(std.mem.compare(u8, "workspace/executeCommand", rpc_method) == .Equal) {
        // Request
        return try sendGenericRpcResponse(rpc_id, null_result_response);
    }
    else if(std.mem.compare(u8, "workspace/applyEdit", rpc_method) == .Equal) {
        // Request
        return try sendGenericRpcResponse(rpc_id, edit_not_applied_response);
    }
    // Only requests need a response
    if(rpc_maybe_id) |_| {
        _ = try sendGenericRpcResponse(rpc_id, error_response);
    }
    return true;
}

fn event_loop() !void {
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    try buffer.resize(4096);

    const stdin = try std.io.getStdIn();
    stdout_file = try std.io.getStdOut();
    stdout = stdout_file.outStream();

    var bytes_read: usize = 0;
    var offset: usize = 0;
    stdin_poll: while(true) {
        var body_len: usize = 0;
        var index: usize = 0;
        if(offset >= 21 and std.mem.compare(u8, "Content-Length: ", buffer.items[0..16]) == .Equal) {
            index = 16;
            while(index < offset-3) : (index += 1) {
                const c = buffer.items[index];
                if(c >= '0' and c <= '9')
                    body_len = body_len*10 + (c-'0');
                if(c == '\r' and buffer.items[index+1] == '\n') {
                    index += 4;
                    break;
                }
            }
            if(buffer.items[index-4] == '\r') {
                if(buffer.len < index+body_len)
                    try buffer.resize(index+body_len);

                body_poll: while(offset < body_len+index) {
                    bytes_read = stdin.read(buffer.items[offset..index+body_len]) catch return;
                    if(bytes_read == 0) return;

                    offset += bytes_read;
                }
                var json = (try Json.initWithString(allocator, buffer.items[index..index+body_len])) orelse return;
                defer json.deinit();

                if(!(try processJsonRpc(json)))
                    return;

                offset = 0;
                body_len = 0;
            }
        }
        else if(offset >= 21) {
            return;
        }

        if(offset < 21) {
            bytes_read = stdin.read(buffer.items[offset..21]) catch return;
        }
        else {
            if(offset == buffer.len)
                try buffer.resize(buffer.len*2);

            if(index+body_len > buffer.len) {
                bytes_read = stdin.read(buffer.items[offset..buffer.len]) catch return;
            }
            else {
                bytes_read = stdin.read(buffer.items[offset..index+body_len]) catch return;
            }
        }
        if(bytes_read == 0) return;

        offset += bytes_read;
    }
}

pub fn main() void {
    event_loop() catch return;
}
