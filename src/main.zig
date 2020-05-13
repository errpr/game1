usingnamespace @cImport({
    @cDefine("SDL_MAIN_HANDLED", "");
    @cInclude("SDL2/SDL.h");
    @cInclude("glad/glad.h");
});

const std = @import("std");

pub fn main() !u8 {

    SDL_SetMainReady();
    defer SDL_Quit();
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) != 0) {
        std.debug.warn("Failed to initialize SDL: {}\n", .{SDL_GetError()});
        return 1;
    }

    const mainWindow = SDL_CreateWindow("test", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 512, 512, SDL_WINDOW_OPENGL) orelse {
        std.debug.warn("Failed to create window: {}\n", .{SDL_GetError()});
        return 2;
    };

    const mainContext = SDL_GL_CreateContext(mainWindow) orelse {
        std.debug.warn("Failed to create OpenGL context: {}\n", .{SDL_GetError()});
        return 3;
    };
    
    if (SDL_GL_SetAttribute(.SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE) != 0
        or SDL_GL_SetAttribute(.SDL_GL_CONTEXT_MAJOR_VERSION, 3) != 0
        or SDL_GL_SetAttribute(.SDL_GL_CONTEXT_MINOR_VERSION, 2) != 0
        or SDL_GL_SetAttribute(.SDL_GL_DOUBLEBUFFER, 1) != 0) 
    {
        std.debug.warn("Failed to set initial GL attribute(s): {}\n", .{SDL_GetError()});
        return 4;
    }

    if (gladLoadGL() == 0)
        return error.GladLoadGLFailed;

    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    SDL_GL_SwapWindow(mainWindow);

    var running = true;
    while (running) {
        var event: SDL_Event = undefined;
        while (SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                SDL_QUIT => running = false,
                SDL_KEYDOWN => {
                    switch (event.key.keysym.sym) {
                        SDLK_ESCAPE => running = false,
                        SDLK_r => {
                            glClearColor(1, 0, 0, 1);
                            glClear(GL_COLOR_BUFFER_BIT);
                            SDL_GL_SwapWindow(mainWindow);
                        },
                        SDLK_g => {
                            glClearColor(1, 0, 0, 1);
                            glClear(GL_COLOR_BUFFER_BIT);
                            SDL_GL_SwapWindow(mainWindow);
                        },
                        SDLK_b => {
                            glClearColor(1, 0, 0, 1);
                            glClear(GL_COLOR_BUFFER_BIT);
                            SDL_GL_SwapWindow(mainWindow);
                        },
                        else => {},
                    }
                },
                else => {},
            }
        }
    }

    return 0;
}