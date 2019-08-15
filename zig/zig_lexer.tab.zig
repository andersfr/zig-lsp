const Lexer = @import("zig_lexer.zig").Lexer;
pub const Id = @import("zig_grammar.tokens.zig").Id;

pub const init_state align(64) = [128]u16{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 302, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 303, 3, 0, 4, 5, 304, 305, 306, 6, 8, 307, 10, 12, 14, 15, 21, 21, 21, 21, 21, 21, 21, 21, 21, 308, 309, 39, 41, 42, 310, 44, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 49, 52, 311, 53, 48, 0, 54, 77, 82, 107, 112, 137, 48, 48, 145, 48, 48, 152, 48, 163, 179, 185, 48, 199, 209, 233, 251, 286, 296, 48, 48, 48, 312, 301, 313, 314, 0 };

pub const accept_states = [347]u8{ 0, 118, 21, 0, 34, 2, 4, 7, 39, 42, 29, 32, 13, 16, 55, 109, 0, 111, 0, 0, 111, 109, 0, 0, 113, 0, 109, 0, 109, 0, 109, 0, 110, 0, 0, 110, 0, 0, 112, 23, 24, 18, 47, 48, 0, 0, 0, 116, 114, 27, 0, 0, 0, 9, 114, 114, 114, 114, 58, 114, 114, 114, 114, 114, 114, 59, 114, 60, 114, 61, 114, 114, 62, 114, 114, 114, 63, 114, 114, 114, 114, 64, 114, 0, 114, 114, 114, 114, 66, 114, 114, 65, 114, 114, 114, 114, 114, 114, 67, 114, 114, 68, 114, 114, 114, 114, 69, 114, 114, 114, 114, 70, 114, 114, 114, 71, 114, 114, 72, 114, 114, 114, 114, 114, 114, 73, 114, 74, 114, 114, 114, 114, 75, 114, 114, 114, 76, 114, 114, 114, 114, 77, 78, 114, 79, 114, 80, 114, 114, 114, 114, 81, 114, 114, 114, 114, 114, 114, 114, 114, 114, 114, 92, 114, 114, 114, 114, 114, 114, 82, 114, 114, 114, 114, 114, 83, 114, 114, 84, 114, 85, 114, 114, 114, 86, 114, 114, 114, 114, 114, 87, 114, 114, 114, 114, 114, 88, 114, 89, 114, 114, 114, 114, 114, 90, 114, 114, 114, 91, 114, 114, 114, 114, 114, 114, 114, 114, 93, 114, 114, 114, 94, 114, 114, 114, 114, 114, 95, 114, 114, 114, 114, 96, 114, 114, 114, 97, 114, 114, 114, 114, 114, 114, 114, 114, 114, 98, 114, 114, 99, 100, 114, 114, 114, 114, 114, 114, 114, 114, 101, 114, 114, 102, 114, 114, 114, 114, 114, 114, 114, 114, 103, 114, 104, 114, 114, 114, 114, 114, 114, 114, 114, 114, 114, 114, 105, 114, 114, 106, 114, 114, 114, 114, 114, 114, 107, 114, 114, 114, 114, 108, 36, 1, 123, 122, 28, 53, 12, 11, 54, 46, 52, 117, 51, 57, 22, 124, 35, 3, 5, 6, 8, 40, 41, 43, 30, 31, 33, 14, 15, 17, 119, 56, 26, 25, 19, 20, 50, 49, 115, 45, 44, 120, 10, 121, 38, 37 };

pub const rle_states = [_]u16{ 32, 32, 1, 65535, 61, 61, 315, 65535, 33, 33, 316, 65535, 61, 61, 317, 65535, 61, 61, 318, 65535, 37, 37, 7, 42, 42, 319, 61, 61, 320, 65535, 37, 37, 0, 42, 42, 0, 61, 61, 321, 65535, 37, 37, 9, 43, 43, 322, 61, 61, 323, 65535, 37, 37, 0, 43, 43, 0, 61, 61, 324, 65535, 37, 37, 11, 61, 61, 325, 62, 62, 326, 65535, 37, 37, 0, 61, 61, 327, 62, 62, 0, 65535, 42, 42, 328, 46, 46, 13, 63, 63, 329, 65535, 42, 42, 0, 46, 46, 330, 63, 63, 0, 65535, 47, 47, 331, 61, 61, 332, 65535, 46, 46, 16, 48, 57, 21, 80, 80, 22, 98, 98, 25, 111, 111, 27, 112, 112, 22, 120, 120, 29, 65535, 46, 46, 0, 48, 57, 17, 80, 80, 0, 98, 98, 0, 111, 112, 0, 120, 120, 0, 65535, 80, 80, 18, 112, 112, 18, 65535, 43, 43, 19, 45, 45, 19, 48, 57, 20, 80, 80, 0, 112, 112, 0, 65535, 43, 43, 0, 45, 45, 0, 65535, 43, 43, 0, 45, 45, 0, 65535, 46, 46, 16, 48, 57, 21, 80, 80, 22, 98, 98, 0, 111, 111, 0, 112, 112, 22, 120, 120, 0, 65535, 43, 43, 23, 45, 45, 23, 46, 46, 0, 48, 57, 24, 80, 80, 0, 98, 98, 0, 111, 112, 0, 120, 120, 0, 65535, 43, 43, 0, 45, 45, 0, 65535, 43, 43, 0, 45, 45, 0, 65535, 46, 46, 0, 48, 49, 26, 50, 57, 0, 80, 80, 0, 98, 98, 0, 111, 112, 0, 120, 120, 0, 65535, 65535, 46, 46, 0, 48, 55, 28, 56, 57, 0, 80, 80, 0, 98, 98, 0, 111, 112, 0, 120, 120, 0, 65535, 65535, 46, 46, 0, 48, 57, 30, 65, 70, 30, 80, 80, 0, 97, 102, 30, 111, 112, 0, 120, 120, 0, 65535, 46, 46, 31, 80, 80, 36, 112, 112, 36, 65535, 46, 46, 0, 48, 57, 32, 65, 70, 32, 80, 80, 0, 97, 102, 32, 112, 112, 0, 65535, 80, 80, 33, 112, 112, 33, 65535, 43, 43, 34, 45, 45, 34, 48, 57, 35, 65, 70, 35, 80, 80, 0, 97, 102, 35, 112, 112, 0, 65535, 43, 43, 0, 45, 45, 0, 65535, 43, 43, 0, 45, 45, 0, 65535, 43, 43, 37, 45, 45, 37, 46, 46, 0, 48, 57, 38, 65, 70, 38, 80, 80, 0, 97, 102, 38, 112, 112, 0, 65535, 43, 43, 0, 45, 45, 0, 65535, 43, 43, 0, 45, 45, 0, 65535, 60, 60, 40, 61, 61, 333, 65535, 60, 60, 0, 61, 61, 334, 65535, 61, 61, 335, 62, 62, 336, 65535, 61, 61, 337, 62, 62, 43, 65535, 61, 61, 338, 62, 62, 0, 65535, 34, 34, 45, 65, 90, 47, 95, 95, 47, 97, 122, 47, 65535, 34, 34, 0, 65, 90, 46, 95, 95, 46, 97, 122, 46, 65535, 34, 34, 339, 48, 57, 46, 65535, 34, 34, 0, 48, 57, 47, 65535, 48, 57, 48, 65, 90, 48, 92, 92, 0, 95, 95, 48, 97, 122, 48, 65535, 42, 42, 50, 65535, 42, 42, 0, 93, 93, 340, 99, 99, 51, 65535, 93, 93, 341, 99, 99, 0, 65535, 92, 92, 342, 65535, 61, 61, 343, 65535, 48, 57, 48, 65, 90, 48, 95, 95, 48, 97, 107, 48, 108, 108, 55, 109, 109, 48, 110, 110, 66, 111, 114, 48, 115, 115, 68, 116, 118, 48, 119, 119, 73, 120, 122, 48, 65535, 105, 105, 56, 108, 108, 59, 110, 110, 48, 115, 115, 48, 119, 119, 48, 65535, 103, 103, 57, 105, 105, 48, 108, 108, 48, 65535, 103, 103, 48, 110, 110, 58, 65535, 110, 110, 48, 65535, 105, 105, 48, 108, 108, 48, 111, 111, 60, 65535, 111, 111, 48, 119, 119, 61, 65535, 119, 119, 48, 122, 122, 62, 65535, 101, 101, 63, 122, 122, 48, 65535, 101, 101, 48, 114, 114, 64, 65535, 111, 111, 65, 114, 114, 48, 65535, 111, 111, 48, 65535, 100, 100, 67, 108, 108, 48, 110, 110, 48, 115, 115, 48, 119, 119, 48, 65535, 100, 100, 48, 65535, 108, 108, 48, 109, 109, 69, 110, 110, 48, 115, 115, 48, 119, 119, 48, 121, 121, 70, 65535, 109, 109, 48, 121, 121, 48, 65535, 109, 109, 48, 110, 110, 71, 121, 121, 48, 65535, 99, 99, 72, 110, 110, 48, 65535, 99, 99, 48, 65535, 97, 97, 74, 108, 108, 48, 110, 110, 48, 115, 115, 48, 119, 119, 48, 65535, 97, 97, 48, 105, 105, 75, 65535, 105, 105, 48, 116, 116, 76, 65535, 116, 116, 48, 65535, 48, 57, 48, 65, 90, 48, 95, 95, 48, 97, 113, 48, 114, 114, 78, 115, 122, 48, 65535, 101, 101, 79, 114, 114, 48, 65535, 97, 97, 80, 101, 101, 48, 65535, 97, 97, 48, 107, 107, 81, 65535, 107, 107, 48, 65535, 48, 57, 48, 65, 90, 48, 92, 92, 83, 95, 95, 48, 97, 97, 84, 98, 110, 48, 111, 111, 92, 112, 122, 48, 65535, 48, 57, 0, 65, 90, 0, 92, 92, 344, 95, 95, 0, 97, 122, 0, 65535, 92, 92, 0, 97, 97, 48, 110, 110, 85, 111, 111, 48, 116, 116, 89, 65535, 99, 99, 86, 110, 110, 48, 116, 116, 48, 65535, 99, 99, 48, 101, 101, 87, 65535, 101, 101, 48, 108, 108, 88, 65535, 108, 108, 48, 65535, 99, 99, 90, 110, 110, 48, 116, 116, 48, 65535, 99, 99, 48, 104, 104, 91, 65535, 104, 104, 48, 65535, 92, 92, 0, 97, 97, 48, 109, 109, 93, 110, 110, 99, 111, 111, 48, 65535, 109, 110, 48, 112, 112, 94, 65535, 112, 112, 48, 116, 116, 95, 65535, 105, 105, 96, 116, 116, 48, 65535, 105, 105, 48, 109, 109, 97, 65535, 101, 101, 98, 109, 109, 48, 65535, 101, 101, 48, 65535, 109, 110, 48, 115, 115, 100, 116, 116, 102, 65535, 115, 115, 48, 116, 116, 101, 65535, 116, 116, 48, 65535, 105, 105, 103, 115, 116, 48, 65535, 105, 105, 48, 110, 110, 104, 65535, 110, 110, 48, 117, 117, 105, 65535, 101, 101, 106, 117, 117, 48, 65535, 101, 101, 48, 65535, 48, 57, 48, 65, 90, 48, 95, 95, 48, 97, 100, 48, 101, 101, 108, 102, 122, 48, 65535, 101, 101, 48, 102, 102, 109, 65535, 101, 101, 110, 102, 102, 48, 65535, 101, 101, 48, 114, 114, 111, 65535, 114, 114, 48, 65535, 48, 57, 48, 65, 90, 48, 95, 95, 48, 97, 107, 48, 108, 108, 113, 109, 109, 48, 110, 110, 116, 111, 113, 48, 114, 114, 119, 115, 119, 48, 120, 120, 128, 121, 122, 48, 65535, 108, 108, 48, 110, 110, 48, 114, 114, 48, 115, 115, 114, 120, 120, 48, 65535, 101, 101, 115, 115, 115, 48, 65535, 101, 101, 48, 65535, 108, 108, 48, 110, 110, 48, 114, 114, 48, 117, 117, 117, 120, 120, 48, 65535, 109, 109, 118, 117, 117, 48, 65535, 109, 109, 48, 65535, 108, 108, 48, 110, 110, 48, 114, 114, 120, 120, 120, 48, 65535, 100, 100, 121, 111, 111, 126, 114, 114, 48, 65535, 100, 100, 48, 101, 101, 122, 111, 111, 48, 65535, 101, 101, 48, 102, 102, 123, 65535, 101, 101, 124, 102, 102, 48, 65535, 101, 101, 48, 114, 114, 125, 65535, 114, 114, 48, 65535, 100, 100, 48, 111, 111, 48, 114, 114, 127, 65535, 114, 114, 48, 65535, 108, 108, 48, 110, 110, 48, 112, 112, 129, 114, 114, 48, 116, 116, 133, 120, 120, 48, 65535, 111, 111, 130, 112, 112, 48, 116, 116, 48, 65535, 111, 111, 48, 114, 114, 131, 65535, 114, 114, 48, 116, 116, 132, 65535, 116, 116, 48, 65535, 101, 101, 134, 112, 112, 48, 116, 116, 48, 65535, 101, 101, 48, 114, 114, 135, 65535, 110, 110, 136, 114, 114, 48, 65535, 110, 110, 48, 65535, 48, 57, 48, 65, 90, 48, 95, 95, 48, 97, 97, 138, 98, 109, 48, 110, 110, 142, 111, 111, 143, 112, 122, 48, 65535, 97, 97, 48, 108, 108, 139, 110, 111, 48, 65535, 108, 108, 48, 115, 115, 140, 65535, 101, 101, 141, 115, 115, 48, 65535, 101, 101, 48, 65535, 97, 97, 48, 110, 111, 48, 65535, 97, 97, 48, 110, 111, 48, 114, 114, 144, 65535, 114, 114, 48, 65535, 48, 57, 48, 65, 90, 48, 95, 95, 48, 97, 101, 48, 102, 102, 146, 103, 109, 48, 110, 110, 147, 111, 122, 48, 65535, 102, 102, 48, 110, 110, 48, 65535, 102, 102, 48, 108, 108, 148, 110, 110, 48, 65535, 105, 105, 149, 108, 108, 48, 65535, 105, 105, 48, 110, 110, 150, 65535, 101, 101, 151, 110, 110, 48, 65535, 101, 101, 48, 65535, 48, 57, 48, 65, 90, 48, 95, 95, 48, 97, 104, 48, 105, 105, 153, 106, 122, 48, 65535, 105, 105, 48, 110, 110, 154, 65535, 107, 107, 155, 110, 110, 48, 65535, 107, 107, 48, 115, 115, 156, 65535, 101, 101, 157, 115, 115, 48, 65535, 99, 99, 158, 101, 101, 48, 65535, 99, 99, 48, 116, 116, 159, 65535, 105, 105, 160, 116, 116, 48, 65535, 105, 105, 48, 111, 111, 161, 65535, 110, 110, 162, 111, 111, 48, 65535, 110, 110, 48, 65535, 48, 57, 48, 65, 90, 48, 95, 95, 48, 97, 97, 164, 98, 110, 48, 111, 111, 170, 112, 116, 48, 117, 117, 176, 118, 122, 48, 65535, 97, 97, 48, 107, 107, 165, 111, 111, 48, 117, 117, 48, 65535, 101, 101, 166, 107, 107, 48, 65535, 100, 100, 167, 101, 101, 48, 65535, 99, 99, 168, 100, 100, 48, 65535, 99, 99, 169, 65535, 99, 99, 48, 65535, 97, 97, 171, 111, 111, 48, 117, 117, 48, 65535, 97, 97, 48, 108, 108, 172, 65535, 105, 105, 173, 108, 108, 48, 65535, 97, 97, 174, 105, 105, 48, 65535, 97, 97, 48, 115, 115, 175, 65535, 115, 115, 48, 65535, 97, 97, 48, 108, 108, 177, 111, 111, 48, 117, 117, 48, 65535, 108, 108, 178, 65535, 108, 108, 48, 65535, 48, 57, 48, 65, 90, 48, 95, 95, 48, 97, 113, 48, 114, 114, 180, 115, 122, 48, 65535, 101, 101, 181, 114, 114, 48, 65535, 101, 101, 48, 108, 108, 182, 65535, 108, 108, 48, 115, 115, 183, 65535, 101, 101, 184, 115, 115, 48, 65535, 101, 101, 48, 65535, 48, 57, 48, 65, 90, 48, 95, 95, 48, 97, 97, 186, 98, 113, 48, 114, 114, 191, 115, 116, 48, 117, 117, 197, 118, 122, 48, 65535, 97, 97, 48, 99, 99, 187, 114, 114, 48, 117, 117, 48, 65535, 99, 99, 48, 107, 107, 188, 65535, 101, 101, 189, 107, 107, 48, 65535, 100, 100, 190, 101, 101, 48, 65535, 100, 100, 48, 65535, 97, 97, 48, 111, 111, 192, 114, 114, 48, 117, 117, 48, 65535, 109, 109, 193, 111, 111, 48, 65535, 105, 105, 194, 109, 109, 48, 65535, 105, 105, 48, 115, 115, 195, 65535, 101, 101, 196, 115, 115, 48, 65535, 101, 101, 48, 65535, 97, 97, 48, 98, 98, 198, 114, 114, 48, 117, 117, 48, 65535, 98, 98, 48, 65535, 48, 57, 48, 65, 90, 48, 95, 95, 48, 97, 100, 48, 101, 101, 200, 102, 122, 48, 65535, 101, 101, 48, 115, 115, 201, 116, 116, 205, 65535, 115, 116, 48, 117, 117, 202, 65535, 109, 109, 203, 117, 117, 48, 65535, 101, 101, 204, 109, 109, 48, 65535, 101, 101, 48, 65535, 115, 116, 48, 117, 117, 206, 65535, 114, 114, 207, 117, 117, 48, 65535, 110, 110, 208, 114, 114, 48, 65535, 110, 110, 48, 65535, 48, 57, 48, 65, 90, 48, 95, 95, 48, 97, 115, 48, 116, 116, 210, 117, 117, 222, 118, 118, 48, 119, 119, 228, 120, 122, 48, 65535, 100, 100, 211, 114, 114, 218, 116, 117, 48, 119, 119, 48, 65535, 99, 99, 212, 100, 100, 48, 114, 114, 48, 65535, 97, 97, 213, 99, 99, 48, 65535, 97, 97, 48, 108, 108, 214, 65535, 108, 108, 215, 65535, 99, 99, 216, 108, 108, 48, 65535, 99, 99, 217, 65535, 99, 99, 48, 65535, 100, 100, 48, 114, 114, 48, 117, 117, 219, 65535, 99, 99, 220, 117, 117, 48, 65535, 99, 99, 48, 116, 116, 221, 65535, 116, 116, 48, 65535, 115, 115, 223, 116, 117, 48, 119, 119, 48, 65535, 112, 112, 224, 115, 115, 48, 65535, 101, 101, 225, 112, 112, 48, 65535, 101, 101, 48, 110, 110, 226, 65535, 100, 100, 227, 110, 110, 48, 65535, 100, 100, 48, 65535, 105, 105, 229, 116, 117, 48, 119, 119, 48, 65535, 105, 105, 48, 116, 116, 230, 65535, 99, 99, 231, 116, 116, 48, 65535, 99, 99, 48, 104, 104, 232, 65535, 104, 104, 48, 65535, 48, 57, 48, 65, 90, 48, 95, 95, 48, 97, 100, 48, 101, 101, 234, 102, 103, 48, 104, 104, 237, 105, 113, 48, 114, 114, 247, 115, 122, 48, 65535, 101, 101, 48, 104, 104, 48, 114, 114, 48, 115, 115, 235, 65535, 115, 115, 48, 116, 116, 236, 65535, 116, 116, 48, 65535, 101, 101, 48, 104, 104, 48, 114, 114, 238, 65535, 101, 101, 239, 114, 114, 48, 65535, 97, 97, 240, 101, 101, 48, 65535, 97, 97, 48, 100, 100, 241, 65535, 100, 100, 48, 108, 108, 242, 65535, 108, 108, 48, 111, 111, 243, 65535, 99, 99, 244, 111, 111, 48, 65535, 97, 97, 245, 99, 99, 48, 65535, 97, 97, 48, 108, 108, 246, 65535, 108, 108, 48, 65535, 101, 101, 48, 104, 104, 48, 114, 114, 48, 117, 117, 248, 121, 121, 250, 65535, 101, 101, 249, 117, 117, 48, 121, 121, 48, 65535, 101, 101, 48, 65535, 117, 117, 48, 121, 121, 48, 65535, 48, 57, 48, 65, 90, 48, 95, 95, 48, 97, 109, 48, 110, 110, 252, 111, 114, 48, 115, 115, 272, 116, 122, 48, 65535, 100, 100, 253, 105, 105, 260, 110, 110, 48, 114, 114, 263, 115, 115, 48, 65535, 100, 100, 48, 101, 101, 254, 105, 105, 48, 114, 114, 48, 65535, 101, 101, 48, 102, 102, 255, 65535, 102, 102, 48, 105, 105, 256, 65535, 105, 105, 48, 110, 110, 257, 65535, 101, 101, 258, 110, 110, 48, 65535, 100, 100, 259, 101, 101, 48, 65535, 100, 100, 48, 65535, 100, 100, 48, 105, 105, 48, 111, 111, 261, 114, 114, 48, 65535, 110, 110, 262, 111, 111, 48, 65535, 110, 110, 48, 65535, 100, 100, 48, 101, 101, 264, 105, 105, 48, 114, 114, 48, 65535, 97, 97, 265, 101, 101, 48, 65535, 97, 97, 48, 99, 99, 266, 65535, 99, 99, 48, 104, 104, 267, 65535, 97, 97, 268, 104, 104, 48, 65535, 97, 97, 48, 98, 98, 269, 65535, 98, 98, 48, 108, 108, 270, 65535, 101, 101, 271, 108, 108, 48, 65535, 101, 101, 48, 65535, 101, 101, 273, 105, 105, 274, 110, 110, 48, 115, 115, 48, 65535, 101, 101, 48, 105, 105, 48, 65535, 101, 101, 48, 105, 105, 48, 110, 110, 275, 65535, 103, 103, 276, 110, 110, 48, 65535, 103, 103, 48, 110, 110, 277, 65535, 97, 97, 278, 110, 110, 48, 65535, 97, 97, 48, 109, 109, 279, 65535, 101, 101, 280, 109, 109, 48, 65535, 101, 101, 48, 115, 115, 281, 65535, 112, 112, 282, 115, 115, 48, 65535, 97, 97, 283, 112, 112, 48, 65535, 97, 97, 48, 99, 99, 284, 65535, 99, 99, 48, 101, 101, 285, 65535, 101, 101, 48, 65535, 48, 57, 48, 65, 90, 48, 95, 95, 48, 97, 97, 287, 98, 110, 48, 111, 111, 289, 112, 122, 48, 65535, 97, 97, 48, 111, 111, 48, 114, 114, 288, 65535, 114, 114, 48, 65535, 97, 97, 48, 108, 108, 290, 111, 111, 48, 65535, 97, 97, 291, 108, 108, 48, 65535, 97, 97, 48, 116, 116, 292, 65535, 105, 105, 293, 116, 116, 48, 65535, 105, 105, 48, 108, 108, 294, 65535, 101, 101, 295, 108, 108, 48, 65535, 101, 101, 48, 65535, 48, 57, 48, 65, 90, 48, 95, 95, 48, 97, 103, 48, 104, 104, 297, 105, 122, 48, 65535, 104, 104, 48, 105, 105, 298, 65535, 105, 105, 48, 108, 108, 299, 65535, 101, 101, 300, 108, 108, 48, 65535, 101, 101, 48, 65535, 61, 61, 345, 124, 124, 346, 65535, 0, 127, 0, 65535, 0, 0 };

pub const rle_indices = [347]u16{ 65535, 0, 4, 8, 12, 16, 20, 30, 40, 50, 60, 70, 80, 90, 100, 107, 129, 148, 155, 171, 178, 185, 207, 232, 239, 246, 268, 269, 291, 292, 314, 324, 343, 350, 372, 379, 386, 411, 418, 425, 432, 439, 446, 453, 460, 473, 486, 493, 500, 516, 520, 530, 537, 541, 545, 582, 598, 608, 615, 619, 629, 636, 643, 650, 657, 664, 668, 684, 688, 707, 714, 724, 731, 735, 751, 758, 765, 769, 788, 795, 802, 809, 813, 838, 854, 870, 880, 887, 894, 898, 908, 915, 919, 935, 942, 949, 956, 963, 970, 974, 984, 991, 995, 1002, 1009, 1016, 1023, 1027, 1046, 1053, 1060, 1067, 1071, 1108, 1124, 1131, 1135, 1151, 1158, 1162, 1175, 1185, 1195, 1202, 1209, 1216, 1220, 1230, 1234, 1253, 1263, 1270, 1277, 1281, 1291, 1298, 1305, 1309, 1334, 1344, 1351, 1358, 1362, 1369, 1379, 1383, 1408, 1415, 1425, 1432, 1439, 1446, 1450, 1469, 1476, 1483, 1490, 1497, 1504, 1511, 1518, 1525, 1532, 1536, 1564, 1577, 1584, 1591, 1598, 1602, 1606, 1616, 1623, 1630, 1637, 1644, 1648, 1661, 1665, 1669, 1688, 1695, 1702, 1709, 1716, 1720, 1748, 1761, 1768, 1775, 1782, 1786, 1799, 1806, 1813, 1820, 1827, 1831, 1844, 1848, 1867, 1877, 1884, 1891, 1898, 1902, 1909, 1916, 1923, 1927, 1955, 1968, 1978, 1985, 1992, 1996, 2003, 2007, 2011, 2021, 2028, 2035, 2039, 2049, 2056, 2063, 2070, 2077, 2081, 2091, 2098, 2105, 2112, 2116, 2147, 2160, 2167, 2171, 2181, 2188, 2195, 2202, 2209, 2216, 2223, 2230, 2237, 2241, 2257, 2267, 2271, 2278, 2303, 2319, 2332, 2339, 2346, 2353, 2360, 2367, 2371, 2384, 2391, 2395, 2408, 2415, 2422, 2429, 2436, 2443, 2450, 2457, 2461, 2474, 2481, 2491, 2498, 2505, 2512, 2519, 2526, 2533, 2540, 2547, 2554, 2561, 2565, 2587, 2597, 2601, 2611, 2618, 2625, 2632, 2639, 2646, 2650, 2669, 2676, 2683, 2690, 2694, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2701, 2704, 2704, 2704, 2704, 2704, 2704, 2704, 2704, 2704, 2704, 2704, 2704, 2704 };

pub const accept_tokens = [_]Id{ .Invalid, .Newline, .Ampersand, .AmpersandEqual, .Asterisk, .AsteriskAsterisk, .AsteriskEqual, .AsteriskPercent, .AsteriskPercentEqual, .Caret, .CaretEqual, .Colon, .Comma, .Period, .PeriodAsterisk, .PeriodQuestionMark, .Ellipsis2, .Ellipsis3, .Equal, .EqualEqual, .EqualAngleBracketRight, .Bang, .BangEqual, .AngleBracketLeft, .AngleBracketAngleBracketLeft, .AngleBracketAngleBracketLeftEqual, .AngleBracketLeftEqual, .LBracket, .LParen, .Minus, .MinusEqual, .MinusAngleBracketRight, .MinusPercent, .MinusPercentEqual, .Percent, .PercentEqual, .Pipe, .PipePipe, .PipeEqual, .Plus, .PlusPlus, .PlusEqual, .PlusPercent, .PlusPercentEqual, .BracketStarCBracket, .BracketStarBracket, .QuestionMark, .AngleBracketRight, .AngleBracketAngleBracketRight, .AngleBracketAngleBracketRightEqual, .AngleBracketRightEqual, .RBrace, .RBracket, .RParen, .Semicolon, .Slash, .SlashEqual, .Tilde, .Keyword_align, .Keyword_allowzero, .Keyword_and, .Keyword_asm, .Keyword_async, .Keyword_await, .Keyword_break, .Keyword_catch, .Keyword_cancel, .Keyword_comptime, .Keyword_const, .Keyword_continue, .Keyword_defer, .Keyword_else, .Keyword_enum, .Keyword_errdefer, .Keyword_error, .Keyword_export, .Keyword_extern, .Keyword_false, .Keyword_fn, .Keyword_for, .Keyword_if, .Keyword_inline, .Keyword_nakedcc, .Keyword_noalias, .Keyword_null, .Keyword_or, .Keyword_orelse, .Keyword_packed, .Keyword_promise, .Keyword_pub, .Keyword_resume, .Keyword_return, .Keyword_linksection, .Keyword_stdcallcc, .Keyword_struct, .Keyword_suspend, .Keyword_switch, .Keyword_test, .Keyword_threadlocal, .Keyword_true, .Keyword_try, .Keyword_undefined, .Keyword_union, .Keyword_unreachable, .Keyword_use, .Keyword_usingnamespace, .Keyword_var, .Keyword_volatile, .Keyword_while, .IntegerLiteral, .FloatLiteral, .FloatLiteral, .FloatLiteral, .FloatLiteral, .Identifier, .Identifier, .Builtin };

pub fn lexer_switch(self: *Lexer, accept: u8) Id {
    switch (accept) {
        0 =>
        // LBrace
        // %dfa {
        {
            if (self.index == 1) return Id.LBrace;
            switch (self.source[self.index - 2]) {
                ':', ' ', '\t', '\r', '\n' => return Id.LBrace,
                else => return Id.LCurly,
            }
        },
        1 =>
        // Space
        // %dfa ( )+
        {
            return Id.Ignore;
        },
        2 =>
        // Comments
        // %dfa //
        {
            var comment_id = Id.LineComment;

            if (self.peek == '/') {
                _ = self.getc();
                if (self.peek != '/') {
                    comment_id = Id.DocComment;
                }
            }

            while (true) {
                switch (self.peek) {
                    '\n', -1 => return comment_id,
                    else => {},
                }
                _ = self.getc();
            }
        },
        3 =>
        // LineString
        // %dfa \\\\
        {
            while (true) {
                switch (self.peek) {
                    '\n', -1 => return Id.LineString,
                    else => {},
                }
                _ = self.getc();
            }
        },
        4 =>
        // LineCString
        // %dfa c\\\\
        {
            while (true) {
                switch (self.peek) {
                    '\n', -1 => return Id.LineCString,
                    else => {},
                }
                _ = self.getc();
            }
        },
        5 =>
        // CharLiteral
        // %dfa '
        {
            while (true) {
                switch (self.peek) {
                    '\n', -1 => return Id.Invalid,
                    '\\' => {
                        _ = self.getc();
                    },
                    '\'' => {
                        _ = self.getc();
                        return Id.CharLiteral;
                    },
                    else => {},
                }
                _ = self.getc();
            }
        },
        6 =>
        // StringLiteral
        // %dfa "
        {
            while (true) {
                switch (self.peek) {
                    '\n', -1 => {
                        // TODO: error
                        return Id.StringLiteral;
                    },
                    '\\' => {
                        _ = self.getc();
                    },
                    '"' => {
                        _ = self.getc();
                        return Id.StringLiteral;
                    },
                    else => {},
                }
                _ = self.getc();
            }
        },
        7 =>
        // ShebangLine
        // %dfa #!
        {
            if (self.index != 2)
                return Id.Invalid;

            while (true) {
                switch (self.peek) {
                    '\n', -1 => return Id.ShebangLine,
                    else => {},
                }
                _ = self.getc();
            }
        },
        else => unreachable,
    }
    return .Invalid;
}