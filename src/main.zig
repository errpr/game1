usingnamespace @cImport({
    @cDefine("SDL_MAIN_HANDLED", "");
    @cInclude("SDL2/SDL.h");
    @cInclude("glad.h");
});

const std = @import("std");
const panic = std.debug.panic;
const builtin = @import("builtin");
const c_allocator = std.heap.c_allocator;

// most people have at least a 720p monitor so this size window will fit on everyones screen.
const DEFAULT_HEIGHT = 648;
const DEFAULT_WIDTH = 1152;

pub fn main() !u8 {

    SDL_SetMainReady();
    defer SDL_Quit();

    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) != 0) {
        std.debug.warn("Failed to initialize SDL: {}\n", .{SDL_GetError()});
        return 1;
    }

    const mainWindow = SDL_CreateWindow("test", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, DEFAULT_WIDTH, DEFAULT_HEIGHT, SDL_WINDOW_OPENGL) 
        orelse {
            std.debug.warn("Failed to create window: {}\n", .{SDL_GetError()});
            return 2;
        };

    const mainContext = SDL_GL_CreateContext(mainWindow) 
        orelse {
            std.debug.warn("Failed to create OpenGL context: {}\n", .{SDL_GetError()});
            return 3;
        };
    
    {
        const errCode = SDL_GL_MakeCurrent(mainWindow, mainContext);
        if (errCode != 0) {
            std.debug.warn("Failed to make window & context current.", .{});
            return 4;
        }
    }

    if (SDL_GL_SetAttribute(.SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE) != 0
        or SDL_GL_SetAttribute(.SDL_GL_CONTEXT_MAJOR_VERSION, 3) != 0
        or SDL_GL_SetAttribute(.SDL_GL_CONTEXT_MINOR_VERSION, 3) != 0
        or SDL_GL_SetAttribute(.SDL_GL_DOUBLEBUFFER, 1) != 0) 
    {
        std.debug.warn("Failed to set initial GL attribute(s): {}\n", .{SDL_GetError()});
        return 4;
    }

    if (gladLoadGL() == 0)
        return error.GladLoadGLFailed;

    glViewport(0, 0, DEFAULT_WIDTH, DEFAULT_HEIGHT);
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    SDL_GL_SwapWindow(mainWindow);
    
    const vertexShaderSource = @embedFile("vertexShader.glsl");
    const vertexShaderSourcePointer: ?[*]const u8 = getPointerBecauseZigIsWeird(vertexShaderSource);
    const vertexShaderSourceLen = @intCast(GLint, vertexShaderSource.len);
    const vertexShaderId = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShaderId, 1, &vertexShaderSourcePointer, &vertexShaderSourceLen);
    glCompileShader(vertexShaderId);

    {
        var success: i32 = 1;
        glGetShaderiv(vertexShaderId, GL_COMPILE_STATUS, &success);
        if (success == 0) {
            var errorSize: GLint = undefined;
            glGetShaderiv(vertexShaderId, GL_INFO_LOG_LENGTH, &errorSize);

            const errorMessageBuffer = try c_allocator.alloc(u8, @intCast(usize, errorSize));
            defer c_allocator.free(errorMessageBuffer);
            glGetShaderInfoLog(vertexShaderId, errorSize, &errorSize, errorMessageBuffer.ptr);
            std.debug.warn("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n{}", .{errorMessageBuffer.ptr});
        }
    }
    
    const fragmentShaderSource = @embedFile("fragmentShader.glsl");
    const fragmentShaderSourcePointer: ?[*]const u8 = getPointerBecauseZigIsWeird(fragmentShaderSource);
    const fragmentShaderSourceLen = @intCast(GLint, fragmentShaderSource.len);
    const fragmentShaderId = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShaderId, 1, &fragmentShaderSourcePointer, &fragmentShaderSourceLen);
    glCompileShader(fragmentShaderId);
    
    {
        var success: i32 = 1;
        glGetShaderiv(fragmentShaderId, GL_COMPILE_STATUS, &success);
        if (success == 0) {
            var errorSize: GLint = undefined;
            glGetShaderiv(fragmentShaderId, GL_INFO_LOG_LENGTH, &errorSize);

            const errorMessageBuffer = try c_allocator.alloc(u8, @intCast(usize, errorSize));
            defer c_allocator.free(errorMessageBuffer);
            glGetShaderInfoLog(fragmentShaderId, errorSize, &errorSize, errorMessageBuffer.ptr);
            std.debug.warn("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{}", .{errorMessageBuffer.ptr});
        }
    }    
    const fragmentShaderSource2 = @embedFile("fragmentShader2.glsl");
    const fragmentShaderSourcePointer2: ?[*]const u8 = getPointerBecauseZigIsWeird(fragmentShaderSource2);
    const fragmentShaderSourceLen2 = @intCast(GLint, fragmentShaderSource2.len);
    const fragmentShaderId2 = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShaderId2, 1, &fragmentShaderSourcePointer2, &fragmentShaderSourceLen2);
    glCompileShader(fragmentShaderId2);
    
    {
        var success: i32 = 1;
        glGetShaderiv(fragmentShaderId2, GL_COMPILE_STATUS, &success);
        if (success == 0) {
            var errorSize: GLint = undefined;
            glGetShaderiv(fragmentShaderId2, GL_INFO_LOG_LENGTH, &errorSize);

            const errorMessageBuffer = try c_allocator.alloc(u8, @intCast(usize, errorSize));
            defer c_allocator.free(errorMessageBuffer);
            glGetShaderInfoLog(fragmentShaderId2, errorSize, &errorSize, errorMessageBuffer.ptr);
            std.debug.warn("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{}", .{errorMessageBuffer.ptr});
        }
    }

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
    defer glDeleteProgram(shaderProgramId);

    const shaderProgramId2 = glCreateProgram();
    glAttachShader(shaderProgramId2, vertexShaderId);
    glAttachShader(shaderProgramId2, fragmentShaderId2);
    glLinkProgram(shaderProgramId2);
    {
        var success: i32 = 1;
        glGetProgramiv(shaderProgramId2, GL_LINK_STATUS, &success);
        if (success == 0) {
            var errorSize: GLint = undefined;
            glGetProgramiv(shaderProgramId2, GL_INFO_LOG_LENGTH, &errorSize);
            const errorMessageBuffer = try c_allocator.alloc(u8, @intCast(usize, errorSize));
            defer c_allocator.free(errorMessageBuffer);
            glGetProgramInfoLog(shaderProgramId2, errorSize, &errorSize, errorMessageBuffer.ptr);
            std.debug.warn("ERROR::SHADER::PROGRAM::LINK_FAILED\n{}", .{errorMessageBuffer.ptr});
        }
    }
    defer glDeleteProgram(shaderProgramId2);

    glDeleteShader(vertexShaderId);
    glDeleteShader(fragmentShaderId);
    glDeleteShader(fragmentShaderId2);

    // var indices = [_]GLuint {
    //     0, 1, 3,
    //     1, 2, 3
    // };

    // var ebo: u32 = undefined;
    // glGenBuffers(1, &ebo);
    // defer glDeleteBuffers(1, &ebo);

    // glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
    // glBufferData(GL_ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(indices)), &indices, GL_STATIC_DRAW);   
    
    var tri1vertices = [_]GLfloat {
         0.25,  0.25, 0.0,
         0.0,   0.0,  0.0,
         0.5,   0.0,  0.0,
    };

    var vbo1: u32 = undefined;
    glGenBuffers(1, &vbo1);
    defer glDeleteBuffers(1, &vbo1);

    var vao1: u32 = undefined;
    glGenVertexArrays(1, &vao1);
    defer glDeleteVertexArrays(1, &vao1);

    glBindVertexArray(vao1);

    glBindBuffer(GL_ARRAY_BUFFER, vbo1);
    glBufferData(GL_ARRAY_BUFFER, @sizeOf(@TypeOf(tri1vertices)), &tri1vertices, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * @sizeOf(GLfloat), null);
    glEnableVertexAttribArray(0); 
    
    var tri2vertices = [_]GLfloat {
        -0.5,  0.5, 0.0,
         0.5,   0.5,  0.0,
        -0.5,   0.0,  0.0
    };

    var vbo2: u32 = undefined;
    glGenBuffers(1, &vbo2);
    defer glDeleteBuffers(1, &vbo2);

    var vao2: u32 = undefined;
    glGenVertexArrays(1, &vao2);
    defer glDeleteVertexArrays(1, &vao2);

    glBindVertexArray(vao2);

    glBindBuffer(GL_ARRAY_BUFFER, vbo2);
    glBufferData(GL_ARRAY_BUFFER, @sizeOf(@TypeOf(tri2vertices)), &tri2vertices, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * @sizeOf(GLfloat), null);
    glEnableVertexAttribArray(0); 

    var running = true;
    var wireframeMode = false;
    var clearColor = [_]GLfloat { 0, 0, 0, 0 };
    while (running) {
        var event: SDL_Event = undefined;
        while (SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                SDL_QUIT => running = false,
                SDL_KEYDOWN => handleKeyDowns(event.key.keysym.sym, &running, &clearColor, &wireframeMode),
                else => {},
            }
        }
        glClearColor(clearColor[0], clearColor[1], clearColor[2], clearColor[3]);
        glClear(GL_COLOR_BUFFER_BIT);

        glUseProgram(shaderProgramId);
        glBindVertexArray(vao1);
        // glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);
        glDrawArrays(GL_TRIANGLES, 0, 3);

        glUseProgram(shaderProgramId2);
        glBindVertexArray(vao2);
        glDrawArrays(GL_TRIANGLES, 0, 3);
        
        glBindVertexArray(0);

        SDL_GL_SwapWindow(mainWindow);
    }

    return 0;
}

fn getPointerBecauseZigIsWeird(thing: []const u8) ?[*]const u8 {
    return thing.ptr;
}

fn handleKeyDowns(key: SDL_Keycode, running: *bool, clearColor: []GLfloat, wireframeMode: *bool) void {
    switch (key) {
        SDLK_ESCAPE => running.* = false,
        SDLK_r => {
            clearColor[0] = 1;
            clearColor[1] = 0;
            clearColor[2] = 0;
            clearColor[3] = 1;
        },
        SDLK_g => {
            clearColor[0] = 0;
            clearColor[1] = 1;
            clearColor[2] = 0;
            clearColor[3] = 1;
        },
        SDLK_b => {
            clearColor[0] = 0;
            clearColor[1] = 0;
            clearColor[2] = 1;
            clearColor[3] = 1;
        },
        SDLK_p => {
            // toggle wireframe
            if (wireframeMode.*) {
                glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
                wireframeMode.* = false;
            } else {
                glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
                wireframeMode.* = true;
            }
        },
        else => {},
    }
}

fn assertNoGLError() void {
    if (builtin.mode != builtin.Mode.ReleaseFast) {
        const err = glGetError();
        if (err != GL_NO_ERROR) {
            panic("GL error: {}\n", .{err});
        }
    }
}