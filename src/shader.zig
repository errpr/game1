usingnamespace @cImport({
    @cInclude("glad.h");
});
const std = @import("std");
const c_allocator = std.heap.c_allocator;

pub const Shader = struct {
    programId: GLuint,

    pub fn init(comptime vertexPath: []const u8, comptime fragmentPath: []const u8) !Shader {
        // vertex
        const vertexShaderSource = @embedFile(vertexPath);
        const vertexShaderSourcePointer: ?[*]const u8 = getPointerBecauseZigIsWeird(vertexShaderSource);
        const vertexShaderSourceLen = @intCast(GLint, vertexShaderSource.len);
        const vertexShaderId = glCreateShader(GL_VERTEX_SHADER);
        glShaderSource(vertexShaderId, 1, &vertexShaderSourcePointer, &vertexShaderSourceLen);
        glCompileShader(vertexShaderId);

        {
            var success: i32 = 1;
            glGetShaderiv(vertexShaderId, GL_COMPILE_STATUS, &success);
            if (success == 0) {
                try logShaderProblem(vertexShaderId, "ERROR::SHADER::VERTEX::COMPILATION_FAILED");
            }
        }
        

        // fragment
        const fragmentShaderSource = @embedFile(fragmentPath);
        const fragmentShaderSourcePointer: ?[*]const u8 = getPointerBecauseZigIsWeird(fragmentShaderSource);
        const fragmentShaderSourceLen = @intCast(GLint, fragmentShaderSource.len);
        const fragmentShaderId = glCreateShader(GL_FRAGMENT_SHADER);
        glShaderSource(fragmentShaderId, 1, &fragmentShaderSourcePointer, &fragmentShaderSourceLen);
        glCompileShader(fragmentShaderId);
        
        {
            var success: i32 = 1;
            glGetShaderiv(fragmentShaderId, GL_COMPILE_STATUS, &success);
            if (success == 0) {
                try logShaderProblem(fragmentShaderId, "ERROR::SHADER::FRAGMENT::COMPILATION_FAILED");
            }
        }

        // shader program
        const shaderProgramId = glCreateProgram();
        glAttachShader(shaderProgramId, vertexShaderId);
        glAttachShader(shaderProgramId, fragmentShaderId);
        glLinkProgram(shaderProgramId);
        {
            var success: i32 = 1;
            glGetProgramiv(shaderProgramId, GL_LINK_STATUS, &success);
            if (success == 0) {
                var errorSize: GLint = undefined;
                glGetProgramiv(shaderProgramId, GL_INFO_LOG_LENGTH, &errorSize);
                const errorMessageBuffer = try c_allocator.alloc(u8, @intCast(usize, errorSize));
                defer c_allocator.free(errorMessageBuffer);
                glGetProgramInfoLog(shaderProgramId, errorSize, &errorSize, errorMessageBuffer.ptr);
                std.debug.warn("ERROR::SHADER::PROGRAM::LINK_FAILED\n{}", .{errorMessageBuffer.ptr});
            }
        }

        glDeleteShader(vertexShaderId);
        glDeleteShader(fragmentShaderId);

        return Shader { .programId = shaderProgramId };
    }

    pub fn use(self: *Shader) void {
        glUseProgram(self.programId);
    }

    pub fn setFloat4(self: *Shader, name: []const u8, value1: GLfloat, value2: GLfloat, value3: GLfloat, value4: GLfloat) void {
        const uniformLocation = glGetUniformLocation(self.programId, getPointerBecauseZigIsWeird(name));
        glUniform4f(uniformLocation, value1, value2, value3, value4);
    }

    pub fn setFloat(self: *Shader, name: []const u8, value: GLfloat) void {
        const uniformLocation = glGetUniformLocation(self.programId, getPointerBecauseZigIsWeird(name));
        glUniform1f(uniformLocation, value);
    }

    fn logShaderProblem(id: GLuint, comptime msg: []const u8) !void {
        var errorSize: GLint = undefined;
        glGetShaderiv(id, GL_INFO_LOG_LENGTH, &errorSize);
        const errorMessageBuffer = try c_allocator.alloc(u8, @intCast(usize, errorSize));
        defer c_allocator.free(errorMessageBuffer);
        glGetShaderInfoLog(id, errorSize, &errorSize, errorMessageBuffer.ptr);
        std.debug.warn("{}\n{}\n", .{msg, errorMessageBuffer});
    }

    pub fn destroy(self: *Shader) void {
        glDeleteProgram(self.programId);
    }
};

fn getPointerBecauseZigIsWeird(thing: []const u8) ?[*]const u8 {
    return thing.ptr;
}