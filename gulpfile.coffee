# Requirements
del = require 'del'
gulp = require 'gulp'
gutil = require 'gulp-util'
connect = require 'gulp-connect'
sass = require 'gulp-sass'
coffee = require 'gulp-coffee'
concat = require 'gulp-concat'
uglify = require 'gulp-uglify'

# Config
sources =
  styles: 'src/styles/**/*.scss'
  scripts: 'src/app/**/*.coffee'
  templates: 'src/templates/**/*.html'
  index: 'src/index.html'
  favicon: 'src/img/favicon.ico'
  img: 'src/img/**/*.png'
  data: 'src/data/**/*'
  fonts: 'src/fonts/**'

destinations =
  styles: 'public/styles'
  scripts: 'public/scripts'
  templates: 'public/templates'
  index: 'public'
  favicon: 'public'
  img: 'public/img'
  data: 'public/data'
  fonts: 'public/fonts'

vendors =
  scripts: [
    'bower_components/jquery/dist/jquery.js'
    'bower_components/angular/angular.js'
    'bower_components/angular-route/angular-route.js'
    'bower_components/d3/d3.js'
    'bower_components/queue-async/queue.js'
    'bower_components/topojson/topojson.js'
    'bower_components/lodash/lodash.js'
    'bower_components/moment/moment.js'
    'external_libs/ilya-birman-likely-2.0/likely.js'
    'external_libs/angular-selectbox/angular-selectbox.js'
  ]
  styles: [
    'external_libs/ilya-birman-likely-2.0/likely.css'
    'external_libs/angular-selectbox/angular-selectbox.css'
  ]

# Tasks
gulp.task 'clean', ->
  del 'public'
  return

gulp.task 'connect', ->
  connect.server
    root: 'public'
    livereload: true
  return

gulp.task 'index', ->
  gulp.src sources.index
  .pipe gulp.dest destinations.index
  return

gulp.task 'favicon', ->
  gulp.src sources.favicon
  .pipe gulp.dest destinations.favicon
  return

gulp.task 'img', ->
  gulp.src sources.img
  .pipe gulp.dest destinations.img
  return

gulp.task 'data', ->
  gulp.src sources.data
  .pipe gulp.dest destinations.data
  return

gulp.task 'fonts', ->
  gulp.src sources.fonts
  .pipe gulp.dest destinations.fonts
  return

gulp.task 'styles:vendor', ->
  gulp.src vendors.styles
  .pipe concat 'vendor.css'
  .pipe gulp.dest destinations.styles
  return

gulp.task 'scripts:vendor', ->
  gulp.src vendors.scripts
  .pipe concat 'vendor.js'
  .pipe uglify()
  .pipe gulp.dest destinations.scripts
  return

gulp.task 'styles', ->
  gulp.src sources.styles
  .pipe sass {outputStyle: 'compressed', errLogToConsole: true}
  .pipe concat 'app.css'
  .pipe gulp.dest destinations.styles
  .pipe connect.reload()
  return

gulp.task 'scripts', ->
  gulp.src sources.scripts
  .pipe coffee {bare: true}
  .on 'error', gutil.log
  .pipe concat 'app.js'
  .pipe gulp.dest destinations.scripts
  .pipe connect.reload()
  return

gulp.task 'templates', ->
  gulp.src sources.templates
  .pipe gulp.dest destinations.templates
  .pipe connect.reload()
  return

gulp.task 'watch', ->
  gulp.watch sources.styles, ['styles']
  gulp.watch sources.scripts, ['scripts']
  gulp.watch sources.templates, ['templates']
  return

gulp.task 'build', ['index', 'favicon', 'img', 'data', 'fonts', 'styles:vendor', 'scripts:vendor', 'styles', 'scripts', 'templates']

gulp.task 'dev', ['styles', 'scripts', 'templates', 'watch', 'connect']
