defmodule CloudosAuthTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Httpc

  test "get token - success" do
  	use_cassette "auth-get-token-success", custom: true do
  		{status, token} = CloudosAuth.Client.get_token_raw("https://myurl.co/oauth/token", "abc", "def")
      assert status == :ok
      assert token.token == "abcdefg"
  	end
  end

  test "auth caching" do
  	use_cassette "auth-get-token-success", custom: true do
  		CloudosAuth.Client.Store.start_link()
      CloudosAuth.Client.Store.remove(CloudosAuth.Client.Store, "https://myurl.co/oauth/token", "abc")
      CloudosAuth.Client.get_token("https://myurl.co/oauth/token", "abc", "def")
      token = CloudosAuth.Client.Store.get(CloudosAuth.Client.Store, "https://myurl.co/oauth/token", "abc")
      assert token.token == "abcdefg"
  	end
  end

  test "auth validate success" do
  	use_cassette "auth-validate-success", custom: true do
  		CloudosAuth.Server.Store.start_link()
      assert true == CloudosAuth.Server.validate_token("https://myurl.co/oauth/token", "12345")
  	end
  end

  test "auth validate failure" do
  	use_cassette "auth-validate-failure", custom: true do
  		CloudosAuth.Server.Store.start_link()
      assert false == CloudosAuth.Server.validate_token("https://myurl.co/oauth/token", "12345")
  	end
  end
end
