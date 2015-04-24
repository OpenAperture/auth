defmodule OpenAperture.Auth do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
	def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(PswAuthex.Worker, [arg1, arg2, arg3])
      worker(OpenAperture.Auth.Client.Store, []),
      worker(OpenAperture.Auth.Server.Store, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OpenAperture.Auth.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def get_token() do
    OpenAperture.Auth.Client.get_token(Application.get_env(:openaperture_auth, :oauth_login_url),
                                       Application.get_env(:openaperture_auth, :oauth_client_id),
                                       Application.get_env(:openaperture_auth, :oauth_client_secret))
  end

end