defmodule OpenAperture.Auth.ServerTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Httpc

  setup do
  	Agent.update(OpenAperture.Auth.Server.Store, fn _ -> HashDict.new end)
  	:ok
  end

  test "validate_token? - success" do
  	use_cassette "auth-validate-success", custom: true do
  		assert true == OpenAperture.Auth.Server.validate_token?("https://myurl.co/oauth/token", "12345")
  	end
  end

  test "validate_token? - failure" do
  	use_cassette "auth-validate-failure", custom: true do
  		assert false == OpenAperture.Auth.Server.validate_token?("https://myurl.co/oauth/token", "12345")
  	end
  end

  test "validate_token? - success cached" do
  	use_cassette "auth-validate-success", custom: true do
  		assert true == OpenAperture.Auth.Server.validate_token?("https://myurl.co/oauth/token", "12345")
  	end

  	assert true == OpenAperture.Auth.Server.validate_token?("https://myurl.co/oauth/token", "12345")
  end   
end