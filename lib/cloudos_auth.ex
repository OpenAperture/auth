require Logger

defmodule CloudosAuth.Client do

  @spec start_link() :: {:ok, pid} | {:error, String.t()}
  def start_link() do
    create()
  end

  @spec create() :: {:ok, pid} | {:error, String.t()} 
  def create() do
    case Agent.start_link(fn -> %{} end) do
      {:ok, pid} -> 
        get_token(true)
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
  @spec get_token(pid, term) :: String.t()
  def get_token(pid, force_refresh \\ false) do
    options = Agent.get(pid, fn options -> options end)

    cond do
      options[:auth_token] != nil && !force_refresh -> options[:auth_token]
      true ->
        options = Map.put(options, :auth_token, get_token_raw())
        Agent.update(pid, fn _ -> options end)
        options[:auth_token]
    end
  end

  @doc """
  Method to retrieve the an authentication token, directly from the provider
  ## Return values
  String
  """
  @spec get_token_raw() :: String.t()
  def get_token_raw() do
    body = '#{JSON.encode!(%{
      grant_type: "client_credentials", 
      client_id: Application.get_env(:cloudos_auth, :client_id), 
      client_secret: Application.get_env(:cloudos_auth, :client_secret)
    })}'
    case :httpc.request(:post, {'#{Application.get_env(:cloudos_auth, :login_url)}', [{'Content-Type', 'application/json'}, {'Accept', 'application/json'}], 'application/json', body}, [], []) do
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
  @spec get_auth_header(term) :: String.t()
  def get_auth_header(force_refresh \\ false) do
    "OAuth access_token=#{get_token(force_refresh)}"
  end
end
