Pod::Spec.new do |s|

  s.name         = "ZDComboBox"
  s.version      = "0.0.1"
  s.summary      = "Ready to use select control for object from a list or a tree of objects."
  s.description  = <<-DESC
                   The ZDComboBox provide easy to use control to select an object from for a list or a tree of objects.
                   All you need to do is drop the NSTextField into a NSView in Interface Builder, change the class to ZDComboBox, and specify 3 elements:
                     1) the attribute name to display in drop-down menu, 
                     2) the attribute name for child nodes,
                     3) and NSArrayController or NSTreeController to provide list of the elements,

                   You can bind to control's value as well. 

                   DESC
  s.homepage     = "zdima.net/ZDComboBox"
  s.screenshots  = "zdima.net/ZDComboBox/screen.png"
  s.license      = { :type => "MIT", :file => "LICENSE.MIT" }
  s.author             = { "Dmitriy Zakharkin" => "mail@zdima.net" }
  s.platform     = :osx
  s.osx.deployment_target = "10.10"
  s.source       = { :git => "http://github.com/zdima/ZDComboBox.git", :tag => "0.0.1" }
  s.source_files  = "ZDComboBox/*.{swift}"
  s.resource  = "ZDComboBox/**/*.{xib,strings}"
end
