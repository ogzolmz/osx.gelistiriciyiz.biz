require 'stringex'
require 'time'
require 'active_support/all'

$USER_CAN_DEPLOY = true
begin
  require './creds'
rescue Exception => e
  $USER_CAN_DEPLOY = false
  puts "== Dikkat !"
  puts "== Lütfen deploy yapacaksanız `creds.rb` dosyasını oluşturun!"
  puts "== Detaylar `readme.md` dosyasında ..."
end

page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

Time.zone = "Europe/Istanbul"
helpers ActiveSupport::NumberHelper

activate :livereload
activate :i18n, :mount_at_root => :tr

set :css_dir,    'public/css'
set :js_dir,     'public/js'
set :images_dir, 'public/images'

activate :syntax
set :markdown_engine, :redcarpet
set :markdown, :fenced_code_blocks => true, :smartypants => true

config_data = YAML.load(File.read("config.yaml"))

convert_hash = lambda do |h|
  Hash === h ? 
    Hash[
      h.map do |k, v| 
        [k.respond_to?(:to_sym) ? k.to_sym : k, convert_hash[v]] 
      end 
    ] : h
end
config[:site] = convert_hash[config_data][:site]

begin
  custom_config = YAML.load(File.read("config_custom.yaml"))
  custom_config["main_author"].each{|k,v| config[:site][:main_author][k.to_sym] = v}
rescue Exception => e
end

configure :build do
  activate :minify_css
  activate :minify_javascript
end

activate :blog do |blog|
  blog.sources = 'posts/{year}-{month}-{day}-{title}.html'
  blog.paginate = true
  blog.layout = "blog_layout"
  blog.summary_length = nil
  blog.summary_separator = /READ_MORE/
  # blog.summary_generator = Proc.new do |article, body, length, ellipsis|
  #   article.default_summary_generator("<pre>#{text}</pre>", length, ellipsis)
  # end
  blog.taglink = "etiket/{tag}.html"
  blog.tag_template = "pages/tag.html"
  blog.calendar_template = "pages/calendar.html"
  blog.page_link = "sayfa/{num}"
  blog.year_link = "arsiv/{year}/index.html"
  blog.month_link = "arsiv/{year}/{month}.html"
end
activate :directory_indexes

proxy "/arsiv/index.html", "/pages/archive.html"
proxy "/hakkinda/index.html", "/pages/about.html"

if $USER_CAN_DEPLOY
  activate :deploy do |deploy|
    deploy.build_before = true
    deploy.method   = :rsync
    deploy.user     = DEPLOY_USER
    deploy.host     = DEPLOY_HOST
    deploy.path     = DEPLOY_PATH
  end
end
