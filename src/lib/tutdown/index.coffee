DefaultRenderer = require("./defaultRenderer")
Doxdown = require("./doxdown")
Path = require("path")
Fs = require("fs")
Str = require('underscore.string')

between = (s, startToken, endToken) ->
  startPos = s.indexOf(startToken)
  return "" if startPos < 0
  endPos = s.indexOf(endToken, startPos)
  start = startPos + startToken.length
  if endPos > startPos then s.slice(start, endPos) else ""

langMarkers =
  js: ['//{{{ Content ', '//}}}']
  coffee: ['#{{{ Content ', '#}}}']

removeLangMarkers = (s) ->
  # remove preceding new line so it compacts the removed line
  s.replace(/\n?^.*{{{ Content.*$/mg, '').replace(/\n^.*}}}.*$/mg, '')


updatePartials = (assets, markdown, root) ->


  # Comments
  if markdown.indexOf(':::#') >= 0
    markdown = markdown.replace(/\s*:::#.*/g, '')

  # extracts content blocks from source
  # :::< content.js --block main --no-capture
  #
  # --block CONTENT_ID
  # --clean removes {{{ Content }}} markers
  # --as-tab creates an asset tab from file
  if markdown.indexOf(':::<') >= 0
    markdown = markdown.replace /:::< (.*)/g, (found) ->
      args = found.substring(4).trim().split(' ')
      filename = args[0]

      # "examples/script.js#main" => filename=examples-script.js block=main
      if filename.indexOf('#')
        [filename, block] = filename.split('#')

      noCapture = false
      for arg, i in args
        switch arg
          when '--no-capture' then noCapture = true
          when '--block' then block = args[i+1]
          when '--lang' then lang = args[i + 1]
          when '--as-tab' then tabName = args[i + 1]
          when '--raw' then raw = true
          when '--hide' then hide = true
          when '--clean' then clean = true
          when '--as-asset'
            clean = true
            noCapture = true
            assetName = Path.basename(args[i+1])
          else
            if arg.indexOf('--') is 0
              throw new Error("Unrecognized :::< option: #{arg}")
            else
              continue

      if !lang
        lang = Path.extname(filename)
        if lang[0] is '.'
          lang = lang.slice(1)
        else
          console.log 'Cannot determine lang from extension and `--lang` not used'
          return found

      file = Path.resolve(Path.join(root, filename))

      if Fs.existsSync(file)
        text = Fs.readFileSync(file, 'utf8')

        if raw
          return text

        if clean
          text = removeLangMarkers(text)

        if assetName
          assets[assetName] = text

        if tabName
          assets[tabName] = text
          return ""

        else
          if block
            [leftMarker, rightMarker] = langMarkers[lang]
            if text.indexOf(leftMarker + block) >= 0
              text = between(text, leftMarker + block, rightMarker)
              text = Str.trim(text, '\r\n')

          result = ""

          argv = []
          if noCapture
            argv.push '--no-capture'

          if hide
            argv.push '--hide'

          if argv.length > 0
            result += ":::@ #{argv.join(' ')}\n\n"

          if assetName
            result +=
             """
              :::@ --hide

              ```html
              <script src='#{assetName}'></script>
              ```
              """

          else
            result +=
              """
              ```#{lang}
              #{text}
              ```
              """
          return result
      else
        found

  markdown


module.exports =
  ###
  * Renders markdown to HTML.
  * @param  {String}   markdown The markdown to convert.
  * @param  {Object}   options  = {
  *   {String} assetsDirname       Where to write assets.
  *   {String} docStylesheetFile   Stylesheet file path.
  *   {String} docScriptFile       Script file path.
  *   {String} docLayoutFile       Layout file path.
  *   {String} exampleLayoutFile   Example layout path.
  * }
  * @param  {Function} cb       function(err, html)
  ###
  render: (markdown, options, cb) ->
    options.userAssets = {}
    renderer = new DefaultRenderer(options)
    markdown = updatePartials(options.userAssets, markdown, Path.dirname(options.filename))
    renderer.render markdown, cb


  ###
  * Renders javascript/coffee to HTML API docs.
  ###
  renderApi: (source, options, cb) ->
    Doxdown.render source, options, cb
