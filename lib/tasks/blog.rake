namespace :blog do

  def jekyll(*args)
    jekyll = `gem which jekyll -q`.strip.sub(/lib\/jekyll\.rb$/, 'bin/jekyll')
    raise "You must install the mojombo-jekyll gem!" unless File.exist? jekyll
    system(jekyll, "blog", "public/blog", "--pygments", *args)
  end

  desc "Continuously regenerate blog from template"
  task :auto do
    jekyll "--auto"
  end

  desc "Build blog from template once"
  task :build do
    jekyll
  end
end
