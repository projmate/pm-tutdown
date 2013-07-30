_ = require("underscore")
str = require("underscore.string")
async = require("async")
utils = require("./utils")
codeFilter = require("./codeFilter")
marked = require("marked")
fs = require("fs")
beautifyJs = require('js-beautify')
beautifyCss = require('js-beautify').css
beautifyHtml = require('js-beautify').html
npath = require('path')

# Render assets
#
# TODO output as separate files for server side testing
#renderAssets = (id, assets, layout, iframeAttributes, cb) ->
renderAssets = (id, assets, options, cb) ->
  layout = options.templates.example
  iframeAttributes = options.exampleAttributes
  userAssets = options.userAssets
  outDirname = npath.basename(options.assetsDirname)

  idOrig = id
  id = id.toLowerCase()
  assetId = 0
  tabLinks = ""
  tabDivs = ""
  assetsTemplate = """
     <div id="{{{id}}}_tabs" class="tabs">
       <ul>
         {{{tabLinks}}}
       </ul>
     </div>
     <div id="{{{id}}}_tabs_content" class="tabs_content">
       {{{tabDivs}}}
     </div>
   """

  linkFirstTemplate = """
    <li class="active">
      <a href="\#{{{idname}}}-tab" rel="{{{idname}}}-tab">
        {{{name}}}
      </a>
    </li>
  """
  linkTemplate = """
    <li>
      <a href="\#{{{idname}}}-tab" rel="{{{idname}}}-tab">
        {{{name}}}
      </a>
    </li>
  """
  tabTemplate = """
    <div id="{{{idname}}}-tab" class="tab_content">
      {{{content}}}
    </div>
  """


  # prepend result tab
  tabLinks = _.template(linkFirstTemplate, id: id, name: "result", idname: id + "result")
  tabDivs =  _.template(tabTemplate, {
    id: id
    name: "result"
    idname: str.slugify(id + "result")
    content: """<iframe id="#{id}" src="#{outDirname}/#{idOrig}.html" class="result" #{iframeAttributes}></iframe>"""
  })

  codeTemplate = """<pre><code class="language-{{{lang}}}">{{{code}}}</code></pre>"""

  processAsset = (assets, name, cb) ->
    idname = str.slugify(id + name)
    tabLinkTemplate = if tabLinks.length is 0 then linkFirstTemplate else linkTemplate
    tabLinks += _.template(tabLinkTemplate, {id, name, idname})
    content = assets[name]

    saveResult = (lang) ->
      return (err, result) ->
        return cb(err) if err
        code = _.template(codeTemplate, {code:result, lang})
        tabDivs += _.template(tabTemplate, {id, content: code, name, idname})
        cb()

    if name is "code" or str.endsWith(name, ".js")
      content = beautifyJs(content, indent_size: 2)
      content = codeFilter(content, {language: "js"}, saveResult('js'))
    else if name  is "markup" or str.endsWith(name, ".html")
      content = renderMarkup(layout, id, assets)
      # HTML beautify has problems
      #content = beautifyHtml(content, indent_size: 2)
      content = codeFilter(content, {language: "html"}, saveResult('html'))
    else if name is "style" or str.endsWith(name, ".css")
      content = beautifyCss(content, indent_size: 2)
      content = codeFilter(content, {language: "css"}, saveResult("css"))
    else
      lang = npath.extname(name).slice(1)
      content = codeFilter(content, {language: lang}, saveResult(lang))



  processCapturedAsset = (name, cb) ->
    processAsset assets, name, cb

  processUserAsset = (name, cb) ->
    return cb() unless name?
    processAsset userAssets, name, cb


  async.forEach Object.keys(assets), processCapturedAsset, (err) ->
    return cb(err) if err

    async.forEach Object.keys(userAssets), processUserAsset, (err) ->
      return cb(err) if err

      result = _.template(assetsTemplate, {id, tabLinks, tabDivs})
      cb null, result


renderMarkup = (layout, id, assets) ->
  stylesheets = ""
  scripts = ""
  for name of assets
    if str.endsWith(name, ".css")
      stylesheets += "<link rel='stylesheet' type='text/css' href='#{id}-#{name}' />"
    else if str.endsWith(name, ".js")
      scripts += "<script type='text/javascript' src='#{id}-#{name}'></script>"

  page = _.template(layout, {markup: assets['markup.html'], stylesheets, scripts})


# Returns an iframe token to be inserted into documented.  Iframe's do not load without a 'src' element.
# The return script must be executed by the main page to load the iframe.
#exports.renderExample = (section, layout, cb) ->
exports.renderExample = (section, options, cb) ->
  options = _.clone(options)

  {id, assets} = section
  exampleRegex = /^{{{EXAMPLE([^}]*)}}}/
  attributes = ""

  # replace {{{EXAMPLE}}} token or append it
  _.find section.tokens, (tok) ->
    result = false
    if tok.type != 'code'
      matches = tok.text?.match(exampleRegex)
      if matches
        attributes = matches[1]
        result = true
    result

  options.exampleAttributes = attributes

  #renderAssets id, assets, layout, attributes, (err, html) ->
  renderAssets id, assets, options, (err, html) ->
    return cb(err) if (err)

    token = utils.rawToken(html)
    page = renderMarkup(options.templates.example, id, assets )
    cb null, [token, page]


parse = (tokens) ->
  options =
    gfm: true
    tables: true
    breaks: false
    pedantic: false
    sanitize: false
    smartLists: true
    langPrefix: ""

  marked.Parser.parse(tokens, options)


#exports.renderTokens = (tokens, cb) ->
exports.renderTokens = (tokens, options, cb) ->
  options = _.clone(options)

  # Satisfies marked interface
  if not tokens.links
    tokens.links = []

  codeTokens = _.filter tokens, (token) ->
    token?.type == "code"

  filterCode = (token, cb) ->
    lang = token.lang
    opts = language: lang
    opts.template = options.templates[lang] if options.templates[lang]?

    codeFilter token.text, opts, (err, result) ->
      return cb(err) if err

      if _.isString(result)
        token.text = result
        token.escaped = true
      else if _.isObject(result)
        _.extend token, result
        token.escaped = true

      # drops extra arguments "js --hide", keeping only "js"
      if token.lang
        token.lang = token.lang.split(/\s/)[0]

      cb()

  async.forEach codeTokens, filterCode, (err) ->
    return cb(err) if err
    cb null, parse(tokens)

