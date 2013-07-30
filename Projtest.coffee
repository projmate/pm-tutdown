{readFileSync} = require('fs')

exports.project = (pm) ->
  {$} = pm

  f = pm.filters(require("."))

  toc = null

  toTmp = f.tap (asset) ->
    asset.filename = asset.filename.replace(/^example/, 'tmp')

  all: ['clean', 'scripts', 'stylesheets', 'statics']

  clean: -> $.rm '-rf', 'tmp'


  scripts:
    files: 'example/**/*.coffee'
    dev: [
      f.coffee bare:true, sourceMap: true
      toTmp
      f.writeFile
    ]

  statics: ->
    $.mkdir '-p', 'tmp'
    $.cp '-Rf', 'example/examples', 'tmp'
    $.cp '-Rf', 'example/img', 'tmp'

  toc:
    files: 'example/toc.md'
    dev: [
      f.tutdown assetsDirname: 'tmp/examples'
      f.writeFile _filename: 'tmp/toc.html'
    ]

  stylesheets:
    files: 'example/css/*.less'
    dev: [
      f.less
      toTmp
      f.writeFile
    ]


  example:
    files: 'example/*.md'
    deps: ['all', 'toc']
    dev: [
      f.tutdown
        templates:
          example: readFileSync('example/support/_example.mustache', 'utf8')
          uml: readFileSync('example/support/_uml.mustache', 'utf8')
        assetsDirname: 'tmp/examples'
      f.tap (asset) ->
        toc ?= readFileSync('tmp/toc.html')
        asset.nav = toc
        asset.filename = asset.filename.replace(/^example/, 'tmp')
      f.template
        delimiters: 'mustache'
        filename: 'example/support/_layout.mustache'
        navHeader: ''
      f.writeFile
    ]

