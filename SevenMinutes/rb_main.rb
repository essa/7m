#
#  rb_main.rb
#  TokyoTower
#
#  Created by Nakajima Taku on 2013/04/25.
#  Copyright (c) 2013年 Nakajima Taku. All rights reserved.
#

# Loading the Cocoa framework. If you need to load more frameworks, you can
# do that here too.
framework 'Cocoa'

# $stdout = File.open("/tmp/tt.stdout", "w")
# $stderr = File.open("/tmp/tt.stderr", "w")

# Loading all the Ruby project files.
main = File.basename(__FILE__, File.extname(__FILE__))
dir_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation
p main, dir_path
# Dir.chdir dir_path + "/../../.."
Dir.glob(File.join(dir_path, '*.{rb,rbo}')).map { |x| File.basename(x, File.extname(x)) }.uniq.each do |path|
  if path != main
    require(path)
  end
end

$: << dir_path
$: << NSBundle.mainBundle.resourcePath.fileSystemRepresentation + '/cui.bundle'
p $:

# Starting the Cocoa main loop.
NSApplicationMain(0, nil)
