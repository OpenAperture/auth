defmodule OpenAperture.AuthTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Httpc

  test "get token - success" do
  	use_cassette "auth-get-token-success", custom: true do
  		{status, token} = OpenAperture.Auth.Client.get_token_raw("https://myurl.co/oauth/token", "abc", "def")
      assert status == :ok
      assert token.token == "abcdefg"
  	end
  end

  test "auth caching" do
  	use_cassette "auth-get-token-success", custom: true do
  		OpenAperture.Auth.Client.Store.remove("https://myurl.co/oauth/token", "abc")
      OpenAperture.Auth.Client.get_token("https://myurl.co/oauth/token", "abc", "def")
      token = OpenAperture.Auth.Client.Store.get("https://myurl.co/oauth/token", "abc")
      assert token.token == "abcdefg"
  	end
  end

  test "auth validate success" do
  	use_cassette "auth-validate-success", custom: true do
  		assert true == OpenAperture.Auth.Server.validate_token?("https://myurl.co/oauth/token", "12345")
  	end
  end

  test "auth validate failure" do
  	use_cassette "auth-validate-failure", custom: true do
  		OpenAperture.Auth.Server.Store.remove("https://myurl.co/oauth/token", "12345")
      assert false == OpenAperture.Auth.Server.validate_token?("https://myurl.co/oauth/token", "12345")
  	end
  end
end
