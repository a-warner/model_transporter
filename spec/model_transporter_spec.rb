RSpec.describe ModelTransporter do
  it "has a version number" do
    expect(ModelTransporter::VERSION).not_to be nil
  end

  it "has a test app" do
    expect(TestApp).not_to be nil
  end
end
