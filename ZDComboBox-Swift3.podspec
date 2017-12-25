Pod::Spec.new do |s|

  s.name         = "ZDComboBox-Swift3"
  s.version      = "0.1.5"
  s.summary      = "Ready to use select control for object from a list or a tree of objects."
  s.description  = <<-DESC
                   The ZDComboBox provide easy to use control to select an object from for a list or a tree of objects.
                   All you need to do is drop the NSTextField into a NSView in Interface Builder, change the class to ZDComboBox, and specify 3 elements:
                     1) the attribute name to display in drop-down menu, 
                     2) the attribute name for child nodes,
                     3) and NSArrayController or NSTreeController to provide list of the elements,

                   You can bind to control's value as well and it works with NSManagedObject.. 

                   DESC
  s.homepage     = "https://github.com/zdima/ZDComboBox.git"
  s.screenshots  = "https://raw.githubusercontent.com/zdima/ZDComboBox/master/screen.png"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Dmitriy Zakharkin" => "mail@zdima.net" }
  s.platform     = :osx
  s.osx.deployment_target = "10.10"
  s.source       = { :git => "https://github.com/zdima/ZDComboBox.git", :tag => "SW3.#{s.version}" }
  s.source_files = "ZDComboBox/*.{swift}"
  s.resource     = "ZDComboBox/**/*.{xib,strings}"
end
