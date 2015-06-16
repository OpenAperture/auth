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

  test "token_info - valid token" do
    use_cassette "auth-validate-success", custom: true do
      info = OpenAperture.Auth.Server.token_info("https://myurl.co/oauth/token", "12345")

      assert info != nil
      assert info["token"] == "d4110b1ab6afc7e5cdf5881718385376f11dafeb3a1126215e5ed5b5b01958db"
      assert info["expires_in_seconds"] == 6808
    end
  end

  test "token_info - invalid token" do
    use_cassette "auth-validate-failure", custom: true do
      assert nil == OpenAperture.Auth.Server.token_info("https://myurl.co/oauth/token", "12345")
    end
  end
end