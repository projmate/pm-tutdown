###
# Copyright (c) 2013 Mario Gutierrez <mario@projmate.com>
#
# See the file LICENSE for copying permission.
###

Path = require("path")
Fs = require("fs")
Tutdown = require("./tutdown")


module.exports = (Projmate) ->

  schema =
    title: 'Creates awesome docuementation from Coffee, JS, and Markdown'
    type: 'object'
    properties:
      assetsDirname:
        type: 'string'
        description: 'Directory to write assets'
      commentFiller:
        type: 'string'
        description: 'Comment filler in CoffeeScript, usually `# ` or `* `'
      debug:
        type: 'boolean'
        description: 'Dumps dox.json'
    required: ['assetsDirname']

    __:
      extnames: ['.md', '.js', '.coffee']
      outExtname: '.html'


  # Compiles markdown to HTML, optionally inserting the
  # file into a layout.
  class Markdown extends Projmate.Filter
    @schema: schema

    # Process the markdown, optionally inserting it into a layout.
    process: (asset, options, cb) ->

      if asset.extname == ".md"
        return cb('options.assetsDirname is required') if !options.assetsDirname
        options.filename = asset.filename
        options.assetPrefix = Path.basename(asset.basename, asset.extname)
        if options.layout
          options.docLayoutFile = options.layout
        Tutdown.render asset.text, options, cb

      else
        if asset.extname == ".coffee"
          options.coffeeScript = true

        Tutdown.renderApi asset.text, options, (err, result) ->
          return cb(err) if err
          {content, nav} = result
          asset.nav = nav
          cb null, text: content, extname: ".html"
