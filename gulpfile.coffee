autoprefixer = require 'autoprefixer-stylus'
cleanCSS = require 'gulp-clean-css'
data = require 'gulp-data'
frontMatter = require 'gulp-front-matter'
gulp = require 'gulp'
jade = require 'pug'
map = require 'through2'
marked = require 'gulp-marked'
rename = require 'gulp-rename'
stylus = require 'gulp-stylus'
fs = require 'fs'

paths =
  staticContent: 'assets/{img,*}'
  styles: 'assets/css/**/*.styl'
  markup: 'content/*'

gulp.task 'stylus', ->
  gulp.src(
    'assets/css/index.styl'
  ).pipe(stylus
    use: [
      autoprefixer(
        browsers: ['> 1%', 'last 2 versions', 'Firefox >= 16', 'Opera 12.1']
      )
    ]
  ).pipe(
    cleanCSS({compatibility: 'ie8'})
  ).pipe(
    gulp.dest 'public/css/'
  )

gulp.task 'staticContent', ->
  gulp.src(
    paths.staticContent
  ).pipe(
    gulp.dest 'public'
  )

gulp.task 'markup', ->
  gulp.src(
    paths.markup
  ).pipe(
    jade()
  ).pipe(
    gulp.dest 'public'
  )

getTemplate = ->
  jade.compile(fs.readFileSync('./views/layout.jade'))

gulp.task 'markup', ->
  template = getTemplate()
  gulp.src(
    paths.markup
  ).pipe(frontMatter(
    property: 'frontMatter'
    remove: true
  )).pipe(
    marked()
  ).pipe(map(objectMode:true, (file, enc, cb) ->
    file.contents = new Buffer(template(content: file.contents.toString()))
    cb(null, file)
  )).pipe(
    gulp.dest('./public')
  )

gulp.task 'watch', ->
  gulp.watch paths.styles, ['stylus']
  gulp.watch '{views,content}/*', ['markup']

gulp.task 'compile', ['stylus', 'staticContent', 'markup']
gulp.task 'default', ['compile', 'watch']
