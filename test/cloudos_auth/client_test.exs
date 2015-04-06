defmodule CloudosAuth.ClientTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Httpc

  setup do
  	Agent.update(CloudosAuth.Client.Store, fn _ -> HashDict.new end)
  	:ok
  end

  test "get_token - success" do
  	use_cassette "auth-get-token-success", custom: true do
  		token = CloudosAuth.Client.get_token("https://myurl.co/oauth/token", "abc", "def")
      assert token == "abcdefg"
  	end
  end

  test "get_token - failure" do
  	use_cassette "auth-get-token-failure", custom: true do
  		token = CloudosAuth.Client.get_token("https://myurl.co/oauth/token", "abc", "def")
      assert token == ""
  	end
  end  

  test "get_token_raw - success" do
  	use_cassette "auth-get-token-success", custom: true do
  		{status, token} = CloudosAuth.Client.get_token_raw("https://myurl.co/oauth/token", "abc", "def")
      assert status == :ok
      assert token.token == "abcdefg"
  	end
  end

  test "get_token_raw - failure" do
  	use_cassette "auth-get-token-failure", custom: true do
  		{status, reason} = CloudosAuth.Client.get_token_raw("https://myurl.co/oauth/token", "abc", "def")
      assert status == :error
      assert reason != nil
  	end
  end
end