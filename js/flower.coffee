class FlowerEffect
  FLOWER_FS = """
#ifdef GL_ES
precision mediump float;
#endif
varying vec4 v_color;
void main(void) {
  gl_FragColor = v_color;
}
  """
  FLOWER_VS = """
attribute vec3 position;
attribute vec2 texCoord;

uniform vec4 u_color;
uniform vec4 u_color2;
uniform mat4 u_worldviewproj;
uniform float u_time;
varying vec4 v_color;
varying vec2 v_texCoord;

vec3 rotateX(vec3 v, float angle) {
  float s = sin(angle);
  float c = cos(angle);
  return vec3(v.x, c * v.y + s * v.z, -s * v.y + c * v.z);
}
vec3 rotateY(vec3 v, float angle) {
  float s = sin(angle);
  float c = cos(angle);
  return vec3(c * v.x + s * v.z, v.y, -s * v.x + c * v.z);
}
vec3 rotateZ(vec3 v, float angle) {
  float s = sin(angle);
  float c = cos(angle);
  return vec3(c * v.x + s * v.y, -s * v.x + c * v.y, v.z);
}

void main(void) {
  vec2 tc = texCoord;
  v_texCoord = tc;
  v_color = mix(u_color, u_color2, tc.x);
  v_color *= v_color.w;
  vec3 pos = rotateZ(rotateX(rotateY(position,
     -u_time + tc.x*6.1), -u_time * 0.6 + tc.x*8.1), -u_time * 0.7 + tc.x*7.12);
  // pos.x += sin(u_time - tc.x*3.0);
  gl_Position = u_worldviewproj * vec4(pos, 1.0);
}
  """
  UP = new Float32Array([0, 1, 0])
  # Returns RGBA quad as array.
  hsv2rgb: (h, s, v, a) ->
    h *= 6
    i = Math.floor(h)
    f = h - i
    f = 1 - f  unless i & 1 # if i is even
    m = v * (1 - s)
    n = v * (1 - s * f)
    switch i
      when 6, 0
        [v, n, m, a]
      when 1
        [n, v, m, a]
      when 2
        [m, v, n, a]
      when 3
        [m, n, v, a]
      when 4
        [n, m, v, a]
      when 5
        [v, m, n, a]

  constructor: ->
    arrays = tdl.primitives.createFlaredCube(0.01, 3.0, 1400)
    program = tdl.programs.loadProgram(FLOWER_VS, FLOWER_FS)
    @proj = new Float32Array(16)
    @view = new Float32Array(16)
    @world = new Float32Array(16)
    @viewproj = new Float32Array(16)
    @worldviewproj = new Float32Array(16)
    @model = new tdl.models.Model(program, arrays, [])
    eyePosition = new Float32Array([0, 0, 3])
    target = new Float32Array([-0.3, 0, 0])
    @m4 = tdl.fast.matrix4
    @m4.lookAt @view, eyePosition, target, UP

  render: (framebuffer, time, aspect, post) ->
    @m4.perspective @proj,          tdl.math.degToRad(60), aspect,  0.1, 500
    @m4.rotationY   @world,         time * 0.2
    @m4.mul         @viewproj,      @view,                 @proj
    @m4.mul         @worldviewproj, @world,                @viewproj
    post.begin()
    gl.clearColor 0.1, 0.2, 0.3, 1
    gl.clear gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT
    gl.disable gl.CULL_FACE
    gl.disable gl.DEPTH_TEST
    gl.enable gl.BLEND
    gl.blendFunc gl.ONE, gl.ONE
    boom = 0.0 #0.5 + Math.sin(time)*0.5
    uniformsConst =
      u_time: time
      u_color: @hsv2rgb((time * 0.1) % 1.0, 0.8, 0.1, 1)
      u_color2: @hsv2rgb((time * 0.22124) % 1.0, 0.7, 0.1, 0)

    uniformsPer = u_worldviewproj: @worldviewproj
    @model.drawPrep uniformsConst
    @model.draw uniformsPer
    gl.disable gl.BLEND
    post.end framebuffer, post.focusBlur.bind(post),
      x: 2
      y: 2
