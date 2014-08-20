class SessionsController < Devise::SessionsController
  def create
    puts '!'*100
    puts params.inspect
    super
  end
end
