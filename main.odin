package main

//Core Libs
import "core:fmt"
import "core:strings"
import libc "core:c"
import glm "core:math/linalg/glsl"
import linalg "core:math/linalg"

//Vendor Libs
import gl "vendor:OpenGL"
import "vendor:glfw"
import stb_image "vendor:stb/image"

//Custom Includes
import "shaders"

//Globals
PROGRAMNAME :: "Rotating Cube"
GL_MAJOR_VERSION :: 3
GL_MINOR_VERSION :: 3
running: b32 = true


//Main Entry Points
main :: proc() {	
	//Initialize GLFW
	if (glfw.Init() != true) {
		fmt.println("Failed to initialize GLFW")
		return
	}
	defer glfw.Terminate()

	//Setup OpenGL version to 3.3 and Profile to Core Profile
	glfw.WindowHint(glfw.RESIZABLE, 1)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	//Create a window
	window := glfw.CreateWindow(800, 600, PROGRAMNAME, nil, nil)
	if window == nil {
		fmt.println("Unable to create window")
		return
	}
	glfw.MakeContextCurrent(window)
	defer glfw.DestroyWindow(window)

	//GLFW Settings
	glfw.SwapInterval(1) //Enable VSYNC

	//Callback Functions
	glfw.SetKeyCallback(window, key_callback)
	glfw.SetFramebufferSizeCallback(window, size_callback)

	//Load opengl Function Pointers
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)

	//Viewport size
	gl.Viewport(0, 0, 800, 600)

	//Cube Data	
	vertices := [?]f32 {
		//Vertices        //Texture Coordinates
		-0.5, -0.5, -0.5, 	0.0, 0.0,
		 0.5, -0.5, -0.5,   1.0, 0.0,
		 0.5,  0.5, -0.5,   1.0, 1.0,
		 0.5,  0.5, -0.5,   1.0, 1.0,
		-0.5,  0.5, -0.5,   0.0, 1.0,
		-0.5, -0.5, -0.5,   0.0, 0.0,
		-0.5, -0.5,  0.5,   0.0, 0.0,
		 0.5, -0.5,  0.5,   1.0, 0.0,
		 0.5,  0.5,  0.5,   1.0, 1.0,
		 0.5,  0.5,  0.5,   1.0, 1.0,
		-0.5,  0.5,  0.5,   0.0, 1.0,
		-0.5, -0.5,  0.5,   0.0, 0.0,
		-0.5,  0.5,  0.5,   1.0, 0.0,
		-0.5,  0.5, -0.5,   1.0, 1.0,
		-0.5, -0.5, -0.5,   0.0, 1.0,
		-0.5, -0.5, -0.5,   0.0, 1.0,
		-0.5, -0.5,  0.5,   0.0, 0.0,
		-0.5,  0.5,  0.5,   1.0, 0.0,
		 0.5,  0.5,  0.5,   1.0, 0.0,
		 0.5,  0.5, -0.5,   1.0, 1.0,
		 0.5, -0.5, -0.5,   0.0, 1.0,
		 0.5, -0.5, -0.5,   0.0, 1.0,
		 0.5, -0.5,  0.5,   0.0, 0.0,
		 0.5,  0.5,  0.5,   1.0, 0.0,
		-0.5, -0.5, -0.5,   0.0, 1.0,
		 0.5, -0.5, -0.5,   1.0, 1.0,
		 0.5, -0.5,  0.5,   1.0, 0.0,
		 0.5, -0.5,  0.5,   1.0, 0.0,
		-0.5, -0.5,  0.5,   0.0, 0.0,
		-0.5, -0.5, -0.5,   0.0, 1.0,
		-0.5,  0.5, -0.5,   0.0, 1.0,
		 0.5,  0.5, -0.5,   1.0, 1.0,
		 0.5,  0.5,  0.5,   1.0, 0.0,
		 0.5,  0.5,  0.5,   1.0, 0.0,
		-0.5,  0.5,  0.5,   0.0, 0.0,
		-0.5,  0.5, -0.5,   0.0, 1.0
	};
	
	//Vertex Array
	vao: u32
	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	//Vertex Buffer
	vbo: u32
	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

	//Vertex Attributes
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 5 * size_of(f32), uintptr(0) )
	gl.EnableVertexAttribArray(0)

	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 5 * size_of(f32), uintptr(3 * size_of(f32)))
	gl.EnableVertexAttribArray(1)

	//Shaders
	//Shaders Map
	shaders_map := make(map[string]u32)
	defer delete(shaders_map)

	shader_id, shader_status := shaders.CreateShader("./res/shaders/simple.vert", "./res/shaders/simple.frag")
	if !shader_status {
		fmt.println("ERROR::SHADER::PROGRAM::FAILED_TO_CREATE_SHADER_PROGRAM")
		return
	} else {
		shaders_map["simple"] = shader_id
		gl.UseProgram(shaders_map["simple"])
	}
	
	//Textures
	//Texture 1
	width, height, channels : libc.int 
	texture1_data := stb_image.load("./res/textures/container.jpg", &width, &height, &channels, 0)
	if texture1_data == nil {
		fmt.println("ERROR::IMAGE::LOADING_FAILED")
		return
	}
	defer stb_image.image_free(texture1_data)

	texture1: u32
	gl.GenTextures(1, &texture1)
	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, texture1)
	gl.TexImage2D(gl.TEXTURE_2D, 0,	gl.RGB,	width, height, 0, gl.RGB, gl.UNSIGNED_BYTE, texture1_data)
	gl.GenerateMipmap(gl.TEXTURE_2D)

	//Set Fragment Shader Texture Uniform
	shaders.SetInt("texture1", 0, shaders_map["simple"])

	//Texture 2
	stb_image.set_flip_vertically_on_load(libc.int(1))
	texture2_data := stb_image.load("./res/textures/awesomeface.png", &width, &height, &channels, 0)
	if texture1_data == nil {
		fmt.println("ERROR::IMAGE::LOADING_FAILED")
		return
	}
	defer stb_image.image_free(texture2_data)
	
	texture2: u32
	gl.GenTextures(1, &texture2)
	gl.ActiveTexture(gl.TEXTURE1)
	gl.BindTexture(gl.TEXTURE_2D, texture2)
	gl.TexImage2D( gl.TEXTURE_2D, 0, gl.RGB, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, texture2_data)
	gl.GenerateMipmap(gl.TEXTURE_2D)
	shaders.SetInt("texture2", 1, shaders_map["simple"])

	//Gl Settings
	gl.Enable(gl.DEPTH_TEST)

	//View Matrix
	view_mat := glm.identity(glm.mat4)
	view_mat = glm.mat4Translate(glm.vec3{0.0, 0.0, -3.0}) 	
	gl.UniformMatrix4fv(gl.GetUniformLocation(shaders_map["simple"], "view_mat"), 1, gl.FALSE, linalg.to_ptr(&view_mat))

	//Projection Matrix
	projection_mat := glm.mat4Perspective(glm.radians_f32(45.0), 800.0 / 600.0, 0.1, 100.0)
	gl.UniformMatrix4fv(gl.GetUniformLocation(shaders_map["simple"], "projection_mat"), 1, 	gl.FALSE, linalg.to_ptr(&projection_mat))

	//Main Loop
	for (!glfw.WindowShouldClose(window) && running) {
		//Handle Events
		glfw.PollEvents()

		//DrawCalls
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		//Update model matrix over time
		model_mat := glm.identity(glm.mat4)
		model_mat *= glm.mat4Rotate(glm.vec3 {0.5, 1.0, 0.0}, f32(glfw.GetTime()) * glm.radians_f32(50.0))	
		
		//Set Matrices uniforms
		gl.UniformMatrix4fv(gl.GetUniformLocation(shaders_map["simple"], "model_mat"), 1, gl.FALSE, linalg.to_ptr(&model_mat))

		//Render
		gl.DrawArrays(gl.TRIANGLES, 0, 36)		

		//Display
		glfw.SwapBuffers(window)
	}


}

// Called when glfw keystate changes
key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	// Exit program on escape pressed
	if key == glfw.KEY_ESCAPE {
		running = false
	}

}

// Called when glfw window changes size
size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	// Set the OpenGL viewport size
	gl.Viewport(0, 0, width, height)
}


