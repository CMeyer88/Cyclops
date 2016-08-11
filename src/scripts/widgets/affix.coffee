#
# Affix - A Polyfill for Sticky Positioning (i.e. `position: sticky`)
#
# Atttempts to emulate sticky positioning in user agents that do not yet support
# the specification. For user agents that do support `position: sticky`, calling
# affix on the element will make the element sticky positioned if it has not
# already been styled that way.
#
# Originally based on Stickyfill (https://github.com/wilddeer/stickyfill), but
# has been completely reimplemented in CoffeeScript and jQuery.
#
class Affix

  element: undefined
  clonedElement: undefined
  parentElement: undefined

  state: undefined
  currentScrollPosition: {}
  currentMode: undefined
  checkTimer: undefined

  isEnabled: false

  # ----------------------------------------------------------------------------

  constructor: (element) ->

    #
    # Don't attempt to initialize the polyfill if the browser supports sticky
    # positioning natively.
    #
    # TODO: Perhaps we should set position: sticky on these elements if they
    #       are being called for affix but aren't sticky positioned?
    #
    if @isSupportedNatively()
      console.info('Skipping Affix Polyfill')
      return
    else
      console.info('Affix Polyfill')

    #
    # Validate the the element that is being affixed is actually capable of
    # being affixed.
    #
    return unless @validateElement(element)

    @updateCurrentScrollPosition()

    @element = element
    @parentElement = ($ element).parent()[0]
    # console.log('parentElement', @parentElement)

    # TODO: Nuke.
    @state = @getElementParams()

    @enable()

  #
  # Validates that the passed element is able to be affixed. Returns true or
  # false.
  #
  validateElement: (element) ->

    #
    # Affix is not compatible with table cells, so don't even try to affix it.
    #
    if element.style.display == 'table-cell'
      console.error('Affix is not compatible with table cells!')
      return false

    #
    # TODO: Ensure that the element is not already affixed.
    #
    # return if @element

    #
    # TODO: Ensure that the element is visible.
    #
    # if isNaN(parseFloat(@state.computed.top)) or @state.computed.display == 'none'
    #   return

    true

  #
  # Enables the element for affixing.
  #
  enable: ->
    @isEnabled = true
    @clone() unless @clonedElement

    #
    # Ensure that the parent element is either positioned absolutely or
    # relatively. If not, set the parent element to relative positioning.
    #
    parentElementPosition = ($ @parentElement).css('position')
    unless parentElementPosition == 'absolute' or parentElementPosition == 'relative'
      ($ @parentElement).css('position', 'relative')

    @recalculateElementPosition()
    @state.parent.height = @parentElement.offsetHeight
    @addObservers()
    @startFastCheckTimer()

  #
  # Disables affixing on the element by removing the observers, relevant styles
  # and the cloned element.
  #
  disable: ->
    @removeObservers()
    @stopFastCheckTimer()
    @removeClone()
    $.extend(@element.style, @state.css)
    @currentMode = -1
    @isEnabled = false

  reset: =>
    @disable()
    @state = @getElementParams()
    @enable()

  # Events & Event Handlers ----------------------------------------------------

  addObservers: ->
    $(window).on('scroll', @handleScrollEvents)
    $(window).on('resize orientationchange', @reset)
    $(document).on('visibilitychange', @handlePageVisibilityChange)

  removeObservers: ->
    $(window).off('scroll', @handleScrollEvents)
    $(window).off('resize orientationchange', @reset)
    $(document).off('visibilitychange', @handlePageVisibilityChange)

  handleScrollEvents: =>
    if window.pageXOffset != @currentScrollPosition.left
      @updateCurrentScrollPosition()
      @reset()
    if window.pageYOffset != @currentScrollPosition.top
      @updateCurrentScrollPosition()
      @recalculateElementPosition()

  handlePageVisibilityChange: =>
    if document.hidden
      @stopFastCheckTimer()
    else
      @startFastCheckTimer()

  # ----------------------------------------------------------------------------

  parseNumeric: (val) ->
    parseFloat(val) or 0

  updateCurrentScrollPosition: ->
    @currentScrollPosition =
      top: window.pageYOffset
      left: window.pageXOffset

  recalculateElementPosition: ->
    return unless @isEnabled
    newMode = if @currentScrollPosition.top <= @state.limit.start
      0
    else if @currentScrollPosition.top >= @state.limit.end
      2
    else
      1
    if @currentMode != newMode
      @switchElementMode(newMode)

  #checks whether stickies start or stop positions have changed

  fastCheck: ->
    deltaTop = Math.abs(($ @clonedElement).offset().top - ($ @element).offset().top)
    deltaHeight = Math.abs(@parentElement.offsetHeight - @state.parent.height)
    return false if deltaTop >= 2 or deltaHeight >= 2
    true

  startFastCheckTimer: ->
    @checkTimer = setInterval((=>
      !@fastCheck() and @reset()
    ), 500)

  stopFastCheckTimer: ->
    clearInterval(@checkTimer)

  switchElementMode: (newMode) ->
    switch newMode
      when 0
        ($ @element).css
          position: 'absolute'
          left: "#{@state.offset.left}px"
          right: "#{@state.offset.right}px"
          top: "#{@state.offset.top}px"
          bottom: 'auto'
          width: 'auto'
          marginLeft: 0
          marginRight: 0
          marginTop: 0
      when 1
        # console.log('1', "#{@state.box.right}px", ($ @element).css('right'), ($ @element).css('top'))
        ($ @element).css
          position: 'fixed'
          left: "#{@state.box.left}px"
          right: "#{@state.box.right}px"
          top: ($ @element).css('top')
          bottom: 'auto'
          width: 'auto'
          marginLeft: 0
          marginRight: 0
          marginTop: 0

      when 2
        ($ @element).css
          position: 'absolute'
          left: "#{@state.offset.left}px"
          right: "#{@state.offset.right}px"
          top: 'auto'
          bottom: 0
          width: 'auto'
          marginLeft: 0
          marginRight: 0
    @currentMode = newMode

  clone: ->
    @clonedElement = document.createElement('div')
    ($ @clonedElement).css
      height: @state.height + 'px'
      width: @state.width + 'px'
      marginTop: ($ @element).css('marginTop')
      marginBottom: ($ @element).css('marginBottom')
      marginLeft: ($ @element).css('marginLeft')
      marginRight: ($ @element).css('marginRight')
      padding: 0
      border: 0
      borderSpacing: 0
      position: 'static'
      float: ($ @element).css('float')
    ($ @clonedElement).insertBefore(@element.nextSibling or @element)

  removeClone: ->
    return unless @clonedElement
    ($ @clonedElement).remove()
    @clonedElement = undefined

  getElementParams: ->
    numeric =
      top: @parseNumeric(($ @element).css('top'))
      marginBottom: @parseNumeric(($ @element).css('marginBottom'))
      paddingLeft: @parseNumeric(($ @element).css('paddingLeft'))
      paddingRight: @parseNumeric(($ @element).css('paddingRight'))
      borderLeftWidth: @parseNumeric(($ @element).css('borderLeftWidth'))
      borderRightWidth: @parseNumeric(($ @element).css('borderRightWidth'))

    css =
      position: @element.style.position
      top: @element.style.top
      bottom: @element.style.bottom
      left: @element.style.left
      right: @element.style.right
      width: @element.style.width
      marginTop: @element.style.marginTop
      marginLeft: @element.style.marginLeft
      marginRight: @element.style.marginRight

    nodeOffset = @getElementOffset(@element)
    parentOffset = @getElementOffset(@parentElement)

    parent =
      numeric:
        borderLeftWidth: @parseNumeric(($ @parentElement).css('borderLeftWidth'))
        borderRightWidth: @parseNumeric(($ @parentElement).css('borderRightWidth'))
        borderTopWidth: @parseNumeric(($ @parentElement).css('borderTopWidth'))
        borderBottomWidth: @parseNumeric(($ @parentElement).css('borderBottomWidth'))

    el =
      box:
        left: nodeOffset.win.left
        right: document.documentElement.clientWidth - (nodeOffset.win.right)
      offset:
        top: nodeOffset.win.top - (parentOffset.win.top) - (parent.numeric.borderTopWidth)
        left: nodeOffset.win.left - (parentOffset.win.left) - (parent.numeric.borderLeftWidth)
        right: -nodeOffset.win.right + parentOffset.win.right - (parent.numeric.borderRightWidth)
      css: css
      numeric: numeric
      width: nodeOffset.win.right - (nodeOffset.win.left)
      height: nodeOffset.win.bottom - (nodeOffset.win.top)
      parent: parent
      limit:
        start: nodeOffset.doc.top - (numeric.top)
        end: parentOffset.doc.top + @parentElement.offsetHeight - (parent.numeric.borderBottomWidth) - (@element.offsetHeight) - (numeric.top) - (numeric.marginBottom)

  getElementOffset: (node) ->
    doc: $(node).offset()
    win: node.getBoundingClientRect()

  #
  # Tests for native "position: sticky" support. Returns true if the browser
  # supports "position: sticky" and false for all other browsers.
  #
  isSupportedNatively: ->
    testElement = document.createElement('test')
    for prefix in [ '', '-webkit-', '-moz-', '-ms-' ]
      testElement.style.position = prefix + 'sticky'
      return true if testElement.style.position.indexOf('sticky') != -1
    false

#
# Create a jQuery function for affix.
#
$.fn.affix = () ->
  instances = []
  this.each (idx, element) ->
    instances.push new Affix(element)
