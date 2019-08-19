const std = @import("std");
const os = std.os;
const warn = std.debug.warn;

const Allocator = std.mem.Allocator;

pub const DirectArena = struct {
    next: *DirectArena,
    offset: usize,
    allocator: Allocator = Allocator{
        .reallocFn = DirectArena.realloc,
        .shrinkFn = DirectArena.shrink,
    },

    pub fn init() !*DirectArena {
        const slice = os.mmap(
            null,
            std.mem.page_size,
            os.PROT_READ | os.PROT_WRITE,
            os.MAP_PRIVATE | os.MAP_ANONYMOUS,
            -1,
            0,
        ) catch return error.OutOfMemory;

        const arena = @ptrCast(*DirectArena, slice.ptr);
        arena.* = DirectArena{
            .next = @alignCast(@alignOf(DirectArena), arena),
            .offset = std.mem.alignForward(@sizeOf(DirectArena), 16),
        };

        return arena.next;
    }

    pub fn deinit(self: *DirectArena) void {
        var ptr = self.next;
        while(ptr != self) {
            var cur = ptr;
            ptr = ptr.next;
            os.munmap(@intToPtr([*]align(std.mem.page_size) u8, @ptrToInt(cur))[0..std.mem.page_size]);
        }
        os.munmap(@intToPtr([*]align(std.mem.page_size) u8, @ptrToInt(self))[0..std.mem.page_size]);
    }

    fn shrink(allocator: *Allocator, old_mem_unaligned: []u8, old_align: u29, new_size: usize, new_align: u29) []u8 {
        return old_mem_unaligned[0..new_size];
    }

    fn realloc(allocator: *Allocator, old_mem_unaligned: []u8, old_align: u29, new_size: usize, new_align: u29) error{OutOfMemory}![]u8 {
        if (new_size == 0)
            return (([*]u8)(undefined))[0..0];

        std.debug.assert(new_size <= std.mem.page_size - @sizeOf(DirectArena));

        const arena = @fieldParentPtr(DirectArena, "allocator", allocator).next;

        arena.offset = std.mem.alignForward(arena.offset, new_align);

        if(arena.offset + new_size <= std.mem.page_size) {
            const slice = @intToPtr([*]u8, @ptrToInt(arena) + arena.offset)[0..new_size];
            arena.offset += new_size;
            if(old_mem_unaligned.len > 0)
                @memcpy(slice.ptr, old_mem_unaligned.ptr, old_mem_unaligned.len);
            return slice;
        }

        const next_slice = os.mmap(
            null,
            std.mem.page_size,
            os.PROT_READ | os.PROT_WRITE,
            os.MAP_PRIVATE | os.MAP_ANONYMOUS,
            -1,
            0,
        ) catch return error.OutOfMemory;
        const next = @ptrCast(*DirectArena, next_slice.ptr);
        next.offset = std.mem.alignForward(@sizeOf(DirectArena), new_align);
        next.next = arena;
        @fieldParentPtr(DirectArena, "allocator", allocator).next = next;

        if(next.offset + new_size <= std.mem.page_size) {
            const slice = @intToPtr([*]u8, @ptrToInt(next) + next.offset)[0..new_size];
            next.offset += new_size;
            if(old_mem_unaligned.len > 0)
                @memcpy(slice.ptr, old_mem_unaligned.ptr, old_mem_unaligned.len);
            return slice;
        }

        return error.OutOfMemory;
    }
};
