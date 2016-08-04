# calculateAndSetNewPosition = (start, element) ->
#   newTopPosition = start - $(window).scrollTop()
#   if newTopPosition < 0
#     newTopPosition = 0
#   $(element).css('top', newTopPosition)
#
# $.fn.affix = () ->
#   $(this).each (idx, ele) ->
#     startingTopPosition = $(ele).position().top
#     calculateAndSetNewPosition(startingTopPosition, ele)
#     $(window).on 'scroll', () ->
#       calculateAndSetNewPosition(startingTopPosition, ele)

###!
# Stickyfill -- `position: sticky` polyfill
# v. 1.1.4 | https://github.com/wilddeer/stickyfill
# Copyright Oleg Korsunsky | http://wd.dizaina.net/
#
# MIT License
###

((window) ->
  watchArray = []
  scroll = undefined
  initialized = false

  # noop = ->

  checkTimer = undefined
  hiddenPropertyName = 'hidden'
  visibilityChangeEventName = 'visibilitychange'
  #fallback to prefixed names in old webkit browsers
  #commit seppuku!
  # seppuku = ->
  #   init = add = rebuild = pause = stop = kill = noop
  #   return

  parseNumeric = (val) ->
    parseFloat(val) or 0

  updateScrollPos = ->
    scroll =
      top: window.pageYOffset
      left: window.pageXOffset

  onScroll = ->
    if window.pageXOffset != scroll.left
      updateScrollPos()
      rebuild()
    if window.pageYOffset != scroll.top
      updateScrollPos()
      recalcAllPos()

  #fixes flickering

  onWheel = (event) ->
    setTimeout (->
      if window.pageYOffset != scroll.top
        scroll.top = window.pageYOffset
        recalcAllPos()
      return
    ), 0

  recalcAllPos = ->
    for watchedItem in watchArray
      recalcElementPos watchedItem

  recalcElementPos = (el) ->
    if !el.inited
      return
    currentMode = if scroll.top <= el.limit.start then 0 else if scroll.top >= el.limit.end then 2 else 1
    if el.mode != currentMode
      switchElementMode el, currentMode

  #checks whether stickies start or stop positions have changed

  fastCheck = ->
    for watchedItem in watchArray
      continue if watchedItem.inited
      deltaTop = Math.abs(getDocOffsetTop(watchedItem.clone) - watchedItem.docOffsetTop)
      deltaHeight = Math.abs(watchedItem.parent.node.offsetHeight - watchedItem.parent.height)
      if deltaTop >= 2 or deltaHeight >= 2
        return false
    true

  initElement = (el) ->
    if isNaN(parseFloat(el.computed.top)) or el.isCell or el.computed.display == 'none'
      return
    el.inited = true
    if !el.clone
      clone el
    if el.parent.computed.position != 'absolute' and el.parent.computed.position != 'relative'
      el.parent.node.style.position = 'relative'
    recalcElementPos el
    el.parent.height = el.parent.node.offsetHeight
    el.docOffsetTop = getDocOffsetTop(el.clone)

  deinitElement = (el) ->
    deinitParent = true
    el.clone and killClone(el)
    $.extend(el.node.style, el.css)
    #check whether element's parent is used by other stickies
    for watchedItem in watchArray
      if watchedItem.node != el.node and watchedItem.parent.node == el.parent.node
        deinitParent = false
        break
    if deinitParent
      el.parent.node.style.position = el.parent.css.position
    el.mode = -1

  initAll = ->
    for watchedItem in watchArray
      initElement watchedItem

  deinitAll = ->
    for watchedItem in watchArray
      deinitElement watchedItem[i]

  switchElementMode = (el, mode) ->
    nodeStyle = el.node.style
    switch mode
      when 0
        nodeStyle.position = 'absolute'
        nodeStyle.left = el.offset.left + 'px'
        nodeStyle.right = el.offset.right + 'px'
        nodeStyle.top = el.offset.top + 'px'
        nodeStyle.bottom = 'auto'
        nodeStyle.width = 'auto'
        nodeStyle.marginLeft = 0
        nodeStyle.marginRight = 0
        nodeStyle.marginTop = 0
      when 1
        nodeStyle.position = 'fixed'
        nodeStyle.left = el.box.left + 'px'
        nodeStyle.right = el.box.right + 'px'
        nodeStyle.top = el.css.top
        nodeStyle.bottom = 'auto'
        nodeStyle.width = 'auto'
        nodeStyle.marginLeft = 0
        nodeStyle.marginRight = 0
        nodeStyle.marginTop = 0
      when 2
        nodeStyle.position = 'absolute'
        nodeStyle.left = el.offset.left + 'px'
        nodeStyle.right = el.offset.right + 'px'
        nodeStyle.top = 'auto'
        nodeStyle.bottom = 0
        nodeStyle.width = 'auto'
        nodeStyle.marginLeft = 0
        nodeStyle.marginRight = 0
    el.mode = mode

  clone = (el) ->
    el.clone = window.document.createElement('div')
    refElement = el.node.nextSibling or el.node
    cloneStyle = el.clone.style
    cloneStyle.height = el.height + 'px'
    cloneStyle.width = el.width + 'px'
    cloneStyle.marginTop = el.computed.marginTop
    cloneStyle.marginBottom = el.computed.marginBottom
    cloneStyle.marginLeft = el.computed.marginLeft
    cloneStyle.marginRight = el.computed.marginRight
    cloneStyle.padding = cloneStyle.border = cloneStyle.borderSpacing = 0
    # cloneStyle.fontSize = '1em'
    cloneStyle.position = 'static'
    cloneStyle.cssFloat = el.computed.cssFloat
    el.node.parentNode.insertBefore el.clone, refElement

  killClone = (el) ->
    el.clone.parentNode.removeChild el.clone
    el.clone = undefined

  getElementParams = (node) ->
    computedStyle = getComputedStyle(node)
    parentNode = node.parentNode
    parentComputedStyle = getComputedStyle(parentNode)
    cachedPosition = node.style.position
    node.style.position = 'relative'
    computed =
      top: computedStyle.top
      marginTop: computedStyle.marginTop
      marginBottom: computedStyle.marginBottom
      marginLeft: computedStyle.marginLeft
      marginRight: computedStyle.marginRight
      cssFloat: computedStyle.cssFloat
      display: computedStyle.display
    numeric =
      top: parseNumeric(computedStyle.top)
      marginBottom: parseNumeric(computedStyle.marginBottom)
      paddingLeft: parseNumeric(computedStyle.paddingLeft)
      paddingRight: parseNumeric(computedStyle.paddingRight)
      borderLeftWidth: parseNumeric(computedStyle.borderLeftWidth)
      borderRightWidth: parseNumeric(computedStyle.borderRightWidth)
    node.style.position = cachedPosition
    css =
      position: node.style.position
      top: node.style.top
      bottom: node.style.bottom
      left: node.style.left
      right: node.style.right
      width: node.style.width
      marginTop: node.style.marginTop
      marginLeft: node.style.marginLeft
      marginRight: node.style.marginRight
    nodeOffset = getElementOffset(node)
    parentOffset = getElementOffset(parentNode)
    parent =
      node: parentNode
      css: position: parentNode.style.position
      computed: position: parentComputedStyle.position
      numeric:
        borderLeftWidth: parseNumeric(parentComputedStyle.borderLeftWidth)
        borderRightWidth: parseNumeric(parentComputedStyle.borderRightWidth)
        borderTopWidth: parseNumeric(parentComputedStyle.borderTopWidth)
        borderBottomWidth: parseNumeric(parentComputedStyle.borderBottomWidth)
    el =
      node: node
      box:
        left: nodeOffset.win.left
        right: window.document.documentElement.clientWidth - (nodeOffset.win.right)
      offset:
        top: nodeOffset.win.top - (parentOffset.win.top) - (parent.numeric.borderTopWidth)
        left: nodeOffset.win.left - (parentOffset.win.left) - (parent.numeric.borderLeftWidth)
        right: -nodeOffset.win.right + parentOffset.win.right - (parent.numeric.borderRightWidth)
      css: css
      isCell: computedStyle.display == 'table-cell'
      computed: computed
      numeric: numeric
      width: nodeOffset.win.right - (nodeOffset.win.left)
      height: nodeOffset.win.bottom - (nodeOffset.win.top)
      mode: -1
      inited: false
      parent: parent
      limit:
        start: nodeOffset.doc.top - (numeric.top)
        end: parentOffset.doc.top + parentNode.offsetHeight - (parent.numeric.borderBottomWidth) - (node.offsetHeight) - (numeric.top) - (numeric.marginBottom)
    el

  getDocOffsetTop = (node) ->
    $(node).offset().top

  getElementOffset = (node) ->
    doc: $(node).offset()
    win: node.getBoundingClientRect()

  startFastCheckTimer = ->
    checkTimer = setInterval((->
      !fastCheck() and rebuild()
    ), 500)

  stopFastCheckTimer = ->
    clearInterval checkTimer

  handlePageVisibilityChange = ->
    return unless initialized
    if window.document[hiddenPropertyName]
      stopFastCheckTimer()
    else
      startFastCheckTimer()

  init = ->
    return if initialized
    updateScrollPos()
    initAll()
    window.addEventListener 'scroll', onScroll
    window.addEventListener 'wheel', onWheel
    #watch for width changes
    window.addEventListener 'resize', rebuild
    window.addEventListener 'orientationchange', rebuild
    #watch for page visibility
    window.document.addEventListener visibilityChangeEventName, handlePageVisibilityChange
    startFastCheckTimer()
    initialized = true

  rebuild = ->
    return unless initialized
    deinitAll()
    for watchedItem in watchArray
      watchedItem = getElementParams(watchedItem.node)
    initAll()

  pause = ->
    window.removeEventListener 'scroll', onScroll
    window.removeEventListener 'wheel', onWheel
    window.removeEventListener 'resize', rebuild
    window.removeEventListener 'orientationchange', rebuild
    window.document.removeEventListener visibilityChangeEventName, handlePageVisibilityChange
    stopFastCheckTimer()
    initialized = false

  stop = ->
    pause()
    deinitAll()

  kill = ->
    stop()
    #empty the array without loosing the references,
    #the most performant method according to http://jsperf.com/empty-javascript-array
    while watchArray.length
      watchArray.pop()

  add = (node) ->
    #check if Stickyfill is already applied to the node
    for watchedItem in watchArray
      return if watchedItem.node == node
    el = getElementParams(node)
    watchArray.push el
    if initialized
      initElement el
    else
      init()

  remove = (node) ->
    i = watchArray.length - 1
    while i >= 0
      if watchArray[i].node == node
        deinitElement watchArray[i]
        watchArray.splice i, 1
      i--

  if window.document.webkitHidden != undefined
    hiddenPropertyName = 'webkitHidden'
    visibilityChangeEventName = 'webkitvisibilitychange'

  #
  # Tests for native "position: sticky" support.
  #
  isSupportedNatively = ->
    testElement = window.document.createElement('div')
    for prefix in [ '', '-webkit-', '-moz-', '-ms-' ]
      testElement.style.position = prefix + 'sticky'
      testElement.style.position
      # try
      #   testElement.style.position = prefix + 'sticky'
      # catch e
      #   console.log(e)
      #   return false
    # true


  console.log('isSupportedNatively?', isSupportedNatively())

  updateScrollPos()

  #expose Stickyfill
  window.Stickyfill =
    stickies: watchArray
    add: add
    remove: remove
    init: init
    rebuild: rebuild
    pause: pause
    stop: stop
    kill: kill
) window

#if jQuery is available -- create a plugin
if window.jQuery
  (($) ->

    $.fn.Stickyfill = (options) ->
      @each ->
        Stickyfill.add this
      #   return
      # this

    # $.fn.affix = () ->
    #   @each ->
    #     Stickyfill.add this
    #   #   return
    #   # this
  ) window.jQuery
