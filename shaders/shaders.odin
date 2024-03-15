package shaders

import "core:fmt"
import "core:strings"
import gl "vendor:OpenGL"
import "core:os"

//Note: value are being implicity return 
CreateShader :: proc(vertex_shader_path: string, fragment_shader_path: string) -> (id: u32, status: bool) {
    id = gl.CreateProgram()
    status = true

	success: i32
	infolog := make([^]u8, 512)

    //---------Vertex Shader----------
    vertex_shader_code, vs_ok := os.read_entire_file_from_filename(vertex_shader_path)
	if !vs_ok {
		fmt.println("ERROR::SHADER::VERTEX::UNABLE_TO_LOAD_SHADER_FILE")
        id = 0
        status = false
		return
	}
	defer delete(vertex_shader_code)

	vertex_shader_source := cstring(raw_data(vertex_shader_code))
	vertex_shader: u32 = gl.CreateShader(gl.VERTEX_SHADER)
	gl.ShaderSource(vertex_shader, 1, &vertex_shader_source, nil)
	gl.CompileShader(vertex_shader)
	gl.GetShaderiv(vertex_shader, gl.COMPILE_STATUS, &success)
	if !bool(success) {
		gl.GetShaderInfoLog(vertex_shader, 512, nil, infolog)
		fmt.println("ERROR:SHADER::VERTEX::COMPILATION_FAILED")
		fmt.println(strings.string_from_ptr(infolog, 512))
	    free(infolog)
        id = 0
        status = false
        return 
	}

    //---------Fragment Shader----------
    fragment_shader_code, fs_ok := os.read_entire_file_from_filename(fragment_shader_path)
	if !fs_ok {
		fmt.println("ERROR::SHADER::FRAGMENT::UNABLE_TO_LOAD_SHADER_FILE")
        id = 0
        status = false
		return
	}
	defer delete(fragment_shader_code)

	fragment_shader_source := cstring(raw_data(fragment_shader_code))
	fragment_shader: u32 = gl.CreateShader(gl.FRAGMENT_SHADER)
	gl.ShaderSource(fragment_shader, 1, &fragment_shader_source, nil)
	gl.CompileShader(fragment_shader)
	gl.GetShaderiv(fragment_shader, gl.COMPILE_STATUS, &success)
	if !bool(success) {
		gl.GetShaderInfoLog(fragment_shader, 512, nil, infolog)
		fmt.println("ERROR:SHADER::FRAGMENT::COMPILATION_FAILED")
		fmt.println(strings.string_from_ptr(infolog, 512))
	    free(infolog)
        id = 0
        status = false
        return 
	}
    
    //---------Shader Program----------
	gl.AttachShader(id, vertex_shader)
	gl.AttachShader(id, fragment_shader)
	gl.LinkProgram(id)
	gl.GetProgramiv(id, gl.LINK_STATUS, &success)
	if !bool(success) {
		gl.GetProgramInfoLog(id, 512, nil, infolog)
		fmt.println("ERROR::SHADER::PROGRAM::LINKING_FAILED")
		fmt.println(strings.string_from_ptr(infolog, 512))
	    free(infolog)
        id = 0
        status = false
        return 
	}

	free(infolog)
	gl.DeleteShader(fragment_shader)
	gl.DeleteShader(vertex_shader)
    return
}

//Helper functions for uniforms
SetBool :: proc(name: cstring, value: bool, shader_program_id: u32) {
	gl.Uniform1i(gl.GetUniformLocation(shader_program_id, name), i32(value))	
}

SetInt :: proc(name: cstring, value: i32, shader_program_id: u32) {
	gl.Uniform1i(gl.GetUniformLocation(shader_program_id, name), value)	
}

SetFloat :: proc(name: cstring, value: f32, shader_program_id: u32) {
	gl.Uniform1f(gl.GetUniformLocation(shader_program_id, name), value)	
}