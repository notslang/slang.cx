autoprefixer = require 'autoprefixer-stylus'
cleanCSS = require 'gulp-clean-css'
gulp = require 'gulp'
jade = require 'gulp-jade'
stylus = require 'gulp-stylus'

paths =
  staticContent: 'assets/{img,*}'
  styles: 'assets/css/**/*.styl'
  markup: 'views/*'

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

gulp.task 'watch', ->
  gulp.watch paths.styles, ['stylus']
  gulp.watch '{views,content}/*', ['markup']

gulp.task 'compile', ['stylus', 'staticContent', 'markup']
gulp.task 'default', ['compile', 'watch']
