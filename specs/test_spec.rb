require './require_roth.rb'

describe Roth do
  before do
    @roth = Roth.new
  end

  it "should say hello" do
    @roth.hello("bob") == 'Hello bob'
  end
end
