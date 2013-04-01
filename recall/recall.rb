require 'rubygems'
require 'sinatra'
require 'shotgun'
require 'thin'
require 'slim'
require 'socket'
require 'dm-core'
require 'data_mapper'
require 'dm-is-reflective'
require 'dm-validations'
# require 'thin'
# require 'spencer'

set :port, 80

DataMapper::Logger.new($stdout, :debug)
dm = DataMapper::setup :default, "mysql://root@localhost/seanslist"
dm.resource_naming_convention = DataMapper::NamingConventions::Resource::Underscored

	class Post
		include DataMapper::Resource
		property :post_id, Serial
		property :long_description, Text, :required => true
		property :short_description, Text, :required => true
		property :complete, Boolean, :required => true, :default => false
		property :posted_date, DateTime
		property :updated_date, DateTime
		property :user, Text
		property :contact, Text, :required => true
		property :price, Float, :required => true
	end

DataMapper.finalize.auto_upgrade!

helpers do 
	include Rack::Utils
	alias_method :h, :escape_html
end


get '/' do 
	@posts = Post.all :order =>:post_id.desc
	@title = "All Posts"
	erb :home	
end

post '/' do
	n = Post.new
	n.long_description = params[:long_description]
	n.short_description = params[:short_description]
	n.contact = params[:contact]
	n.price = params[:price]
	n.posted_date = Time.now
	n.updated_date = Time.now
	n.user = Socket.gethostbyaddr(request.ip.split(".").map {|x| Integer(x)}.pack("CCCC"))[0].to_s[0..-17].capitalize
	n.save
	redirect '/'	
end

get '/:post_id' do
	@post = Post.get params[:post_id]
	@title = "Edit Post ##{params[:post_id]}"
	erb :Edit
end

put '/:post_id' do
	n = Post.get params[:post_id]
	n.long_description = params[:long_description]
	n.short_description = params[:short_description]
	n.contact = params[:contact]
	n.complete = params[:complete] ? 1 : 0
	n.updated_date = Time.now
	n.save
	redirect '/'
end

get '/:post_id/delete' do
	@post = Post.get params[:post_id]
	@title = "Confirm deletion of Post ##{params[:post_id]}"
	erb :delete
end

delete '/:post_id' do
	n = Post.get params[:post_id]
	n.destroy
	redirect '/'
end

get '/:post_id/complete' do 
	n = Post.get params[:post_id]
	n.complete = n.complete ? 0 : 1
	n.updated_date = Time.now
	n.save
	redirect '/'
end

