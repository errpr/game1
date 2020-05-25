usingnamespace @cImport({
    @cDefine("SDL_MAIN_HANDLED", "");
    @cInclude("SDL2/SDL.h");
    @cInclude("glad.h");
    @cDefine("STBI_NO_STDIO", "");
    @cInclude("stb_image.h");
});

const std = @import("std");
const panic = std.debug.panic;
const builtin = @import("builtin");
const math = std.math;

usingnamespace @import("./shader.zig");

// most people have at least a 720p monitor so this size window will fit on everyones screen.
const DEFAULT_HEIGHT = 648;
const DEFAULT_WIDTH = 1152;

var COUNTER_FREQUENCY: u64 = undefined;
var COUNTER_FREQUENCY_F64: f64 = undefined;

pub fn main() !u8 {

    SDL_SetMainReady();
    defer SDL_Quit();

    COUNTER_FREQUENCY = SDL_GetPerformanceFrequency();
    COUNTER_FREQUENCY_F64 = @intToFloat(f64, COUNTER_FREQUENCY);

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

    // Texture

    var textureId: GLuint = undefined;
    {        
        glGenTextures(1, &textureId);
        glBindTexture(GL_TEXTURE_2D, textureId);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

        const textureBytes = @embedFile("../assets/container.jpg");

        var width: i32 = 0; 
        var height: i32 = 0; 
        var comp: i32 = 0;
        if (stbi_info_from_memory(textureBytes, @intCast(c_int, textureBytes.len), &width, &height, &comp) == 0) {
            std.debug.warn("Problem reading texture", .{});
            return 5;
        }


        var data = stbi_load_from_memory(textureBytes,  @intCast(c_int, textureBytes.len), &width, &height, &comp, 0);
        defer stbi_image_free(data);

        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
        glGenerateMipmap(GL_TEXTURE_2D);
    }

    // Triangle One
    
    var tri1vertices = [_]GLfloat {
        // pos                  // tex coords
         0.25,  0.5,  0.0,      1.0, 0.0,
         0.0,   0.0,  0.0,      0.5, 1.0,
         0.5,   0.0,  0.0,      0.0, 0.0,
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

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * @sizeOf(GLfloat), null);
    glEnableVertexAttribArray(0); 

    const textureOffset2 = 3 * @sizeOf(GLfloat);
    glVertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, 5 * @sizeOf(GLfloat), @intToPtr(*c_void, textureOffset2));
    glEnableVertexAttribArray(2);

    // Triangle Two
    
    var tri2vertices = [_]GLfloat {
        // pos              // color         // texture coords
        -0.5,  0.5,  0.0,   1.0, 0.0, 0.0,   1.0, 0.0,
         0.5,  0.5,  0.0,   0.0, 1.0, 0.0,   0.5, 1.0,
        -0.5,  0.0,  0.0,   0.0, 0.0, 1.0,   0.0, 0.0,
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

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 8 * @sizeOf(GLfloat), null);
    glEnableVertexAttribArray(0);

    const colorOffset = 3 * @sizeOf(f32);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 8 * @sizeOf(GLfloat), @intToPtr(*c_void, colorOffset));
    glEnableVertexAttribArray(1);

    const textureOffset = 6 * @sizeOf(f32);
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 8 * @sizeOf(GLfloat), @intToPtr(*c_void, textureOffset));
    glEnableVertexAttribArray(2);
    
    // Commence the gamering

    var running = true;
    var wireframeMode = false;
    var clearColor = [_]GLfloat { 0, 0, 0, 0 };
    var lastCounter = SDL_GetPerformanceCounter();
    
    const monitorHertz = 60;
    const targetGameHertz = monitorHertz / 2;
    var targetSecondsPerFrame = 1.0 / @intToFloat(f64, targetGameHertz);

    assertNoGLError();

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
        shader2.setFloat("offset", greenValue);
        glBindTexture(GL_TEXTURE_2D, textureId);
        glBindVertexArray(vao2);

        glDrawArrays(GL_TRIANGLES, 0, 3);

        glBindVertexArray(0);

        // timing
        const workCounter = SDL_GetPerformanceCounter();
        const workSecondsElapsed = getSecondsElapsed(workCounter, lastCounter);
        var frameCounter = workCounter;
        var frameSecondsElapsed = workSecondsElapsed;
        if (frameSecondsElapsed < targetSecondsPerFrame) {
            const sleepMillis = @floatToInt(i64, 1000 * (targetSecondsPerFrame - frameSecondsElapsed)) - 1;
            if (sleepMillis > 0) {
                SDL_Delay(@intCast(u32, sleepMillis));
            }

            while (frameSecondsElapsed < targetSecondsPerFrame) {
                frameCounter = SDL_GetPerformanceCounter();
                frameSecondsElapsed = getSecondsElapsed(frameCounter, lastCounter);
            }
        } else {
            std.debug.warn("Missed frame flip\n", .{});
        }

        lastCounter = SDL_GetPerformanceCounter();
        SDL_GL_SwapWindow(mainWindow);
    }

    return 0;
}

fn getSecondsElapsed(newCounter: u64, oldCounter: u64) f64 {
    return @intToFloat(f64, newCounter - oldCounter) / COUNTER_FREQUENCY_F64;
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