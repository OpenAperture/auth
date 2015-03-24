defmodule CloudosAuthTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Httpc

  test "get token - success" do
  	use_cassette "auth-get-token-success", custom: true do
  		assert CloudosAuth.Client.get_token_raw("https://myurl.co/oauth/token", "abc", "def") == "abcdefg"
  	end
  end

  test "auth caching" do
  	use_cassette "auth-get-token-success", custom: true do
  		{:ok, pid} = CloudosAuth.Client.start_link("https://myurl.co/oauth/token", "abc", "def")
  		options = Agent.get(pid, fn options -> options end)
  		assert options[:url] == "https://myurl.co/oauth/token"
  		assert options[:client_id] == "abc"
  		assert options[:client_secret] == "def"
  		assert options[:auth_token] == "abcdefg"
  	end
  end

  test "auth validate success" do
  	use_cassette "auth-validate-success", custom: true do
  		assert true == CloudosAuth.Server.validate_token("https://myurl.co/oauth/token", "12345")
  	end
  end

  test "auth validate failure" do
  	use_cassette "auth-validate-failure", custom: true do
  		assert false == CloudosAuth.Server.validate_token("https://myurl.co/oauth/token", "12345")
  	end
  end
end
