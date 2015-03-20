require Logger

defmodule CloudosAuth.Client do

  @spec start_link() :: {:ok, pid} | {:error, String.t()}
  def start_link() do
    create()
  end

  @spec create() :: {:ok, pid} | {:error, String.t()} 
  def create() do
    case Agent.start_link(__MODULE__, fn -> %{} end) do
      {:ok, pid} -> 
        {:ok, pid}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Method to retrieve the an authentication token from cache, if available
  ## Options
  The `force_refresh` option will force a retrieval of the auth token
  ## Return values
  String
  """
  @spec get_token(String.t(), String.t(), String.t(), term) :: String.t()
  def get_token(url, client_id, client_secret, force_refresh \\ false) do
    options = Agent.get(__MODULE__, fn options -> options end)

    cond do
      options[url] != nil && !force_refresh -> options[url]
      true ->
        options = Map.put(options, url, get_token_raw(url, client_id, client_secret))
        Agent.update(__MODULE__, fn _ -> options end)
        options[url]
    end
  end

  @doc """
  Method to retrieve the an authentication token, directly from the provider
  ## Return values
  String
  """
  @spec get_token_raw(String.t(), String.t(), String.t()) :: String.t()
  def get_token_raw(url, client_id, client_secret) do
    body = '#{JSON.encode!(%{
      grant_type: "client_credentials", 
      client_id: client_id, 
      client_secret: client_secret
    })}'
    case :httpc.request(:post, {url, [{'Content-Type', 'application/json'}, {'Accept', 'application/json'}], 'application/json', body}, [], []) do
      {:ok, {{_,return_code, _}, _, body}} ->
        case return_code do
          200 -> 
            Logger.debug("Retrieved OAuth Token")
            JSON.decode!("#{body}")["access_token"]
          _   -> 
            Logger.error("OAuth returned status #{return_code} while authenticating:  #{inspect body}")
            ""
        end
      {:error, {failure_reason, _}} ->
        Logger.error("OAuth responded with an error while authenticating:  (#{inspect failure_reason})")
        ""
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
