$ ->
  new Background()
class Background
  constructor: ()->
    # Check Float32Array
    window.Float32Array = (->) unless window.Float32Array

    do @addElements
    canvas = @render_area[0]
    window.tdl.webgl.registerContextLostHandler canvas, => do @handleContextLost
    window.tdl.webgl.registerContextRestoredHandler canvas, => do @handleContextRestored
    gl = window.tdl.webgl.setupWebGL(canvas)
    @bootTime = (new Date()).getTime()
    @timer = new tdl.fps.FPSTimer()
    @diff = 0
    @zoom = 1
    @scale_time = 0
    @singleEffect = new FlowerEffect()
    do @mainloop if @initializeGraphics()
    return false  unless gl
  addElements: ->
    @container = $("<div>")
    @render_area = $("<canvas width=\"1024\" height=\"512\" />")
    @render_area.css
      width    : "100%"
      height   : "100%"
      position : "fixed"
      top      : "0"
      left     : "0"
      "z-index"  : "-100000"
    @container.append @render_area
    $(document.body).append @container
  mainloop: ()->
    time = (new Date()).getTime()
    @timer.update (time - @diff)/1000
    @diff = time
    @now = (time - @bootTime) * 0.001
    @scale(1) if @now - @scale_time > 2 && @timer.averageFPS < 50
    music_time = @now
    canvas = @render_area[0]
    aspect = canvas.clientWidth / canvas.clientHeight
    framebuffer = @backbuffer
    @singleEffect.render framebuffer, music_time, aspect, @post
    @requestId = window.tdl.webgl.requestAnimationFrame((=>do @mainloop), canvas)

  scale: (s)->
    @scale_time = @now
    @zoom += s
    canvas = @render_area[0]
    @post = new PostProcessor(@backbuffer, canvas.width/@zoom, canvas.height/@zoom)
  initializeGraphics: ->
    canvas = @render_area[0]
    @backbuffer = window.tdl.framebuffers.getBackBuffer(canvas)
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    @post = new PostProcessor(@backbuffer, canvas.width, canvas.height)
    
    gl.disable gl.BLEND
    gl.depthFunc gl.LEQUAL
    gl.blendFunc gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA
    true

  handleContextLost: ->
    window.tdl.webgl.cancelRequestAnimationFrame @requestId
  handleContextRestored: ->
    setup()
