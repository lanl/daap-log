# encoding: utf-8

$LOAD_PATH.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = 'fluent-plugin-daap'
  gem.description = 'output split for daap logs sent through telegraf'
  gem.homepage    = 'https://git.lanl.gov/'
  gem.summary     = gem.description
  gem.version     = File.read('VERSION').strip
  gem.authors     = ['Hugh Greenberg']
  gem.email       = 'hng@lanl.gov'
  gem.has_rdoc    = false
  gem.license     = 'MIT'
  gem.files       = `git ls-files`.split("\n")
  gem.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  gem.require_paths = ['lib']

  gem.add_dependency 'fluentd', ['>= 0.14.0', '< 2']
  gem.add_dependency 'fluent-mixin-config-placeholders', '>= 0.3.0'
  gem.add_dependency 'fluent-mixin-rewrite-tag-name'
  gem.add_development_dependency 'rake', '>= 0.9.2'
  gem.add_development_dependency 'test-unit'
end
