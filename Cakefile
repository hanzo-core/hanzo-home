require 'shortcake'

use 'cake-bundle'
use 'cake-outdated'
use 'cake-publish'
use 'cake-test'
use 'cake-version'

task 'clean', 'clean project', ->
  exec 'rm -rf dist'

task 'build', 'build project', ->
  bundle.write
    entry: 'src/index.coffee'
    format: 'es'
    cache: false
    compilers:
      coffee:
        version: 1

task 'watch', 'watch project', ->
  build = (filename) ->
    console.log filename, 'modified, rebuilding'
    invoke 'build' if not running 'build'

  watch 'src/css/*.styl',      build
  watch 'src/templates/*.pug', build
  watch 'src/*.coffee',        build
  watch 'node_modules/',       build, watchSymlink: true
