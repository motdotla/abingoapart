require 'rubygems'
require 'sinatra'
require 'haml'
require 'dm-sqlite-adapter'
require 'dm-postgres-adapter'
require 'data_mapper'

configure :development do
  DataMapper.setup(:default, "sqlite3://#{File.expand_path(File.dirname(__FILE__))}/db/bingapp_development.db")
end

configure :production do
  DataMapper.setup(:default, ENV['DATABASE_URL'])
end

DataMapper::Model.raise_on_save_failure = true

class Game
  include DataMapper::Resource
  include DataMapper::Timestamp
  
  # Schema
  property :id,                       Serial
  property :title,                    String
  property :created_at,               DateTime
  property :updated_at,               DateTime
  
  # Relationships/Associations
  has n, :calls
  has n, :cards
  
  def allowed_columns
    ["B", "I", "N", "G", "O"]
  end
  
  def allowed_numbers
    allowed_numbers = []
    (1..30).each {|i| allowed_numbers << "#{i}"}
    allowed_numbers
  end
end

class Card
  include DataMapper::Resource
  include DataMapper::Timestamp
  include DataMapper::Serialize
  
  # Schema
  property :id,                       Serial
  property :numbers,                  Object
  property :created_at,               DateTime
  property :updated_at,               DateTime
  
  # Relationships/Associations
  belongs_to :game
  
  # Callbacks
  before :save, :generate_numbers
  
  def generate_numbers
    the_numbers = []
    25.times do
      the_numbers << allowed_numbers[rand(allowed_numbers.length-1)]
    end
    self.numbers = the_numbers
  end
  
  def allowed_columns
    ["B", "I", "N", "G", "O"]
  end
  
  def allowed_numbers
    allowed_numbers = []
    (1..30).each {|i| allowed_numbers << "#{i}"}
    allowed_numbers
  end
  
end

class Call
  include DataMapper::Resource
  include DataMapper::Timestamp
  
  # Schema
  property :id,                       Serial
  property :column,                   String
  property :number,                   String
  property :column_number,            String
  property :created_at,               DateTime
  property :updated_at,               DateTime
  
  # Relationships/Associations
  belongs_to :game
  
  # Validations
  # validates_presence_of :column
  # validates_presence_of :number
  # validates_with_method :check_column
  # validates_with_method :check_number
  
  # Hooks/Callbacks
  before  :valid?,  :generate_column_and_number
  before  :save,    :generate_column_number
  
  def generate_column_and_number
    self.column = allowed_columns[rand(allowed_columns.length-1)]
    self.number = allowed_numbers[rand(allowed_numbers.length-1)]
  end
  
  def generate_column_number
    self.column_number = "#{column}#{number}"
  end
  
  def allowed_columns
    ["B", "I", "N", "G", "O"]
  end
  
  def allowed_numbers
    allowed_numbers = []
    (1..30).each {|i| allowed_numbers << "#{i}"}
    allowed_numbers
  end
  
  private
  def check_column
    if allowed_columns.include?(column)
      true
    else
      [false, "Column #{column} is not allowed."]
    end
  end
  
  def check_number    
    if allowed_numbers.include?(number)
      true
    else
      [false, "Number #{number} is not allowed."]
    end
  end
end

get "/" do
  @games = Game.all
  haml :index
end

get "/games/:id" do
  @game = Game.get(params[:id])
  @card = @game.cards.new
  @card.save
  redirect "/card/#{@card.id}"
end

get "/card/:id" do
  @card = Card.get(params[:id])
  @game = @card.game
  haml :card
end



# CREATING A GAME - KEEP IT SECRET
get "/games/:id/call" do
  @game = Game.get(params[:id])
  @call = @game.calls.new
  @call.save
  haml :call
end

get "/new/game" do
  haml :new_game
end

post "/create/a/new/game" do
  @game = Game.new(params[:game])
  @game.save
  @game = Game.get(@game.id)
  @call = @game.calls.new
  @call.save
  redirect "/"
end
