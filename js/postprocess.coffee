class QuadDrawer
  constructor: ()->
    quadVerts = new Float32Array([-1.0, -1.0, 0.0, 1.0, -1.0, 0.0, -1.0, 1.0, 0.0, 1.0, 1.0, 0.0])
    @quadPosBuf = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, @quadPosBuf
    gl.bufferData gl.ARRAY_BUFFER, quadVerts, gl.STATIC_DRAW
    return
  draw : (program) ->
    gl.bindBuffer gl.ARRAY_BUFFER, @quadPosBuf
    gl.enableVertexAttribArray program.attribLoc["position"]
    gl.vertexAttribPointer program.attribLoc["position"], 3, gl.FLOAT, false, 0, 0
    gl.drawArrays gl.TRIANGLE_STRIP, 0, 4
    return
class PostProcessor
  QUAD_VS = """
attribute vec4 position;
varying vec4 v_position;
varying vec2 v_texCoord;
void main() {
  vec2 tc = (position.xy + vec2(1.0, 1.0)) / 2.0;
  v_texCoord = tc;
  gl_Position = position;
}
"""
  BLUR_FS = """
#ifdef GL_ES
precision mediump float;
#endif
varying vec2 v_texCoord;
uniform vec2 blurSize;
uniform vec4 subtract;
uniform sampler2D mainSampler;
void main() {
   vec4 sum = vec4(0.0);
   sum += texture2D(mainSampler, v_texCoord - 4.0 * blurSize) * 0.05;
   sum += texture2D(mainSampler, v_texCoord - 3.0 * blurSize) * 0.09;
   sum += texture2D(mainSampler, v_texCoord - 2.0 * blurSize) * 0.12;
   sum += texture2D(mainSampler, v_texCoord - 1.0 * blurSize) * 0.15;
   sum += texture2D(mainSampler, v_texCoord                 ) * 0.16;
   sum += texture2D(mainSampler, v_texCoord + 1.0 * blurSize) * 0.15;
   sum += texture2D(mainSampler, v_texCoord + 2.0 * blurSize) * 0.12;
   sum += texture2D(mainSampler, v_texCoord + 3.0 * blurSize) * 0.09;
   sum += texture2D(mainSampler, v_texCoord + 4.0 * blurSize) * 0.05;
   gl_FragColor = sum - subtract;
}
"""
  COPY_FS = """
#ifdef GL_ES
precision mediump float;
#endif
varying vec2 v_texCoord;
uniform sampler2D mainSampler;
void main() {
  gl_FragColor = texture2D(mainSampler, v_texCoord);
}
"""
  constructor: (backbuffer, w, h) ->
    @w = w
    @h = h
    @render_fb = tdl.framebuffers.createFramebuffer(w, h, true)
    @bounce_fb = tdl.framebuffers.createFramebuffer(w, h, true)
    @qw_fb = tdl.framebuffers.createFramebuffer(w / 4, h, true)
    @qw_qh_fb = tdl.framebuffers.createFramebuffer(w / 4, h, true)
    @quad = new QuadDrawer()
    backbuffer.bind()
    @blurQuadProgram = tdl.programs.loadProgram(QUAD_VS, BLUR_FS)
    @copyQuadProgram = tdl.programs.loadProgram(QUAD_VS, COPY_FS)
  focusBlur : (framebuffer, params, quad) ->
    @blurQuadProgram.use()
    @blurQuadProgram.setUniform "mainSampler", @render_fb.texture
    @qw_fb.bind()
    @blurQuadProgram.setUniform "blurSize", [params.x / @w, 0.0 / @h]
    @blurQuadProgram.setUniform "subtract", [0, 0, 0, 0]
    @quad.draw @blurQuadProgram
    @qw_qh_fb.bind()
    @blurQuadProgram.setUniform "mainSampler", @qw_fb.texture
    @blurQuadProgram.setUniform "blurSize", [0.0 / @w, params.y / @h]
    @blurQuadProgram.setUniform "subtract", [0, 0, 0, 0]
    @quad.draw @blurQuadProgram
    @copyQuadProgram.use()
    @copyQuadProgram.setUniform "mainSampler", @qw_qh_fb.texture
    framebuffer.bind()
    @quad.draw @copyQuadProgram

  begin : ->
    @render_fb.bind()

  end : (framebuffer, func, params) ->
    gl.disable gl.DEPTH_TEST
    gl.disable gl.CULL_FACE
    gl.disable gl.BLEND
    gl.activeTexture gl.TEXTURE0
    func framebuffer, params
