exports.project = (pm) ->
  {f, $} = pm

  toDist = f.tap (asset) ->
    asset.filename = asset.filename.replace(/^src/, 'dist')

  addHeader = f.addHeader text:"""
  /**
   * Copyright (c) 2013 Mario L Gutierrez
   */

  """


  all: ['clean', 'scripts', 'styles', 'statics']

  clean: -> $.rm '-rf', 'dist'

  scripts:
    files: "src/**/*.{coffee,js}"
    dev: [
      f.coffee bare:true, sourceMap: true
      toDist
      f.writeFile
    ]

  styles:
    files: "src/lib/tutdown/assets/*.less"
    dev: [
      f.less
      toDist
      f.writeFile
    ]

  statics: ->
    $.cp '-Rf', 'src/lib/tutdown/vendor', 'dist/lib/tutdown'
    $.cp '-Rf', 'src/lib/tutdown/templates', 'dist/lib/tutdown'
    $.cp 'src/lib/tutdown/assets/*.js', 'dist/lib/tutdown/assets'


  test:
    pre: ['all']
    dev: (done) ->
      $.pm '-f Projtest.coffee run example', done

