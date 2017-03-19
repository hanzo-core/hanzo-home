require 'shortcake'

use 'cake-bundle'
use 'cake-outdated'
use 'cake-publish'
use 'cake-test'
use 'cake-version'

task 'clean', 'clean project', ->
  exec 'rm -rf dist'

task 'build', 'build project', ->
  handroll = require 'handroll'

  bundle = yield handroll.bundle
    entry: 'src/index.coffee'
    cache: false

  yield bundle.write format: 'es'

task 'watch', 'watch project', ->
  build = (filename) ->
    console.log filename, 'modified, rebuilding'
    invoke 'build' if not running 'build'

  watch 'src/css/*.styl',      build
  watch 'src/templates/*.pug', build
  watch 'src/*.coffee',        build
  watch 'node_modules/',       build, watchSymlink: true
