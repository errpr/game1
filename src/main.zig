usingnamespace @cImport({
    @cDefine("SDL_MAIN_HANDLED", "");
    @cInclude("SDL2/SDL.h");
    @cInclude("glad.h");
});

const std = @import("std");
const panic = std.debug.panic;
const builtin = @import("builtin");
const math = std.math;

usingnamespace @import("./shader.zig");

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

    var shader1 = try Shader.init("vertexShader.glsl", "fragmentShader.glsl");
    var shader2 = try Shader.init("vertexShader.glsl", "fragmentShader2.glsl");
    defer shader1.destroy();
    defer shader2.destroy();

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
        // pos              // color
        -0.5,  0.5,  0.0,   1.0, 0.0, 0.0,
         0.5,  0.5,  0.0,   0.0, 1.0, 0.0,
        -0.5,  0.0,  0.0,   0.0, 0.0, 1.0
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

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * @sizeOf(GLfloat), null);
    glEnableVertexAttribArray(0);
    const offset = 3 * @sizeOf(f32);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * @sizeOf(GLfloat), @intToPtr(*c_void, offset));
    glEnableVertexAttribArray(1);

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

        const seconds = @intToFloat(f32, SDL_GetTicks()) / 1000;
        const greenValue = (math.sin(seconds) / 2) + 0.5;

        glClearColor(clearColor[0], clearColor[1], clearColor[2], clearColor[3]);
        glClear(GL_COLOR_BUFFER_BIT);

        shader1.use();
        shader1.setFloat4("ourColor", 0.0, greenValue, 0.0, 1.0);
        glBindVertexArray(vao1);
        // glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);
        glDrawArrays(GL_TRIANGLES, 0, 3);

        shader2.use();
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