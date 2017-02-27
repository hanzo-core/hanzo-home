require 'shortcake'

use 'cake-test'
use 'cake-publish'
use 'cake-version'

coffee      = require 'rollup-plugin-coffee-script'
commonjs    = require 'rollup-plugin-commonjs'
json        = require 'rollup-plugin-json'
nodeResolve = require 'rollup-plugin-node-resolve'
pug         = require 'rollup-plugin-pug'
rollup      = require 'rollup'
stylus      = require 'rollup-plugin-stylus'

postcss      = require 'poststylus'
autoprefixer = require 'autoprefixer'
comments     = require 'postcss-discard-comments'
lost         = require 'lost-stylus'

pkg         = require './package'

option '-b', '--browser [browser]', 'browser to use for tests'
option '-g', '--grep [filter]',     'test filter'
option '-t', '--test [test]',       'specify test to run'
option '-v', '--verbose',           'enable verbose test logging'

task 'clean', 'clean project', ->
  exec 'rm -rf dist'

task 'build', 'build project', ->
  plugins = [
    coffee()
    pug
      pretty:                 true
      compileDebug:           true
      sourceMap:              true
      inlineRuntimeFunctions: false
      staticPattern:          /\S/
    stylus
      sourceMap: true
      fn: (style) ->
        style.use lost()
        style.use postcss [
          autoprefixer browsers: '> 1%'
          'lost'
          'css-mqpacker'
          comments removeAll: true
        ]
    json()
    nodeResolve
      browser: true
      extensions: ['.js', '.coffee', '.pug', '.styl']
      module:  true
    commonjs
      extensions: ['.js', '.coffee']
      sourceMap: true
  ]

  bundle = yield rollup.rollup
    entry:    'src/index.coffee'
    external: Object.keys pkg.dependencies
    plugins:  plugins

  # CommonJS
  bundle.write
    dest:       pkg.main
    format:     'cjs'
    sourceMap:  false

  # ES module bundle
  bundle.write
    dest:      pkg.module
    format:    'es'
    sourceMap: false
