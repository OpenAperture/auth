require Logger

defmodule CloudosAuth.Client do

  alias CloudosAuth.Client.Store
  alias CloudosAuth.Util
  @doc """
  Method to retrieve the an authentication token from cache, if available
  ## Options
  The `force_refresh` option will force a retrieval of the auth token
  ## Return values
  String
  """
  @spec get_token(String.t(), String.t(), String.t()) :: String.t()
  def get_token(url, client_id, client_secret, force_refresh \\ false) do
    stored_token = Store.get(CloudosAuth.Client.Store, url, client_id)

    cond do
      stored_token != nil && !force_refresh && Util.valid_token?(stored_token)-> 
        stored_token.token
      true ->
        {:ok, token} = get_token_raw(url, client_id, client_secret)
        Store.put(CloudosAuth.Client.Store, url, client_id, token)
        token.token
    end
  end

  @doc """
  Method to retrieve the an authentication token, directly from the provider
  """
  @spec get_token_raw(String.t(), String.t(), String.t()) :: {:ok, CloudosAuth.Token} | {:error, String.t()}
  def get_token_raw(url, client_id, client_secret) do
    body = '#{JSON.encode!(%{
      grant_type: "client_credentials", 
      client_id: client_id, 
      client_secret: client_secret
    })}'
    start_time = :os.timestamp()
    case :httpc.request(:post, {url, [{'Content-Type', 'application/json'}, {'Accept', 'application/json'}], 'application/json', body}, [], []) do
      {:ok, {{_,return_code, _}, _, body}} ->
        case return_code do
          200 -> 
            Logger.debug("Retrieved OAuth Token")
            token = JSON.decode!("#{body}")["access_token"]
            expiration = String.to_integer(JSON.decode!("#{body}")["expires_in"])
            timestamp = Util.timestamp_add_seconds(start_time, expiration)
            {:ok, %CloudosAuth.Token{token: token, expires_at: timestamp}}
          _   -> 
            Logger.error("OAuth returned status #{return_code} while authenticating:  #{inspect body}")
            {:error, "OAuth returned status #{return_code} while authenticating:  #{inspect body}"}
        end
      {:error, {failure_reason, _}} ->
        Logger.error("OAuth responded with an error while authenticating:  (#{inspect failure_reason})")
        {:error, "OAuth responded with an error while authenticating:  (#{inspect failure_reason})"}
    end
  end

  @doc """
  Method to retrieve the authentication header
  ## Options
  The `force_refresh` option will force a retrieval of the auth token
  ## Return values
  String
  """
  @spec get_auth_header(String.t(), String.t(), String.t(), term) :: String.t()
  def get_auth_header(url, client_id, client_secret, force_refresh \\ false) do
    "OAuth access_token=#{get_token(url, client_id, client_secret, force_refresh)}"
  end
end