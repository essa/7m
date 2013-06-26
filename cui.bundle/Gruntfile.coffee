
module.exports = (grunt) ->
  pkg = grunt.file.readJSON 'package.json'
  grunt.initConfig
    watch:
      files: ['src/**/*.coffee', 'spec/javascript/**/*.coffee'],
      tasks: ['coffee']
 
    coffee:
      compile:
        options:
          sourceMap: true
        files: 
          'public/js/app.js': [ 'src/app.coffee', 'src/**/*.coffee']
          'public/js/app_spec.js': [ 'spec/javascript/**/*_spec.coffee']

      ios:
        options:
          sourceMap: true
        files: 
          '../ios/www/js/app.js': [ 'src/app.coffee', 'src/**/*.coffee']
          '../ios/www/js/app_spec.js': [ 'spec/javascript/**/*_spec.coffee']

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  # grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.registerTask 'default', ['coffee']
  # grunt.registerTask 'default', ['uglify']

