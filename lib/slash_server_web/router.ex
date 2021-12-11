defmodule SlashServerWeb.Router do
  use SlashServerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {SlashServerWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :session_auth do
    plug SlashServerWeb.Plugs.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SlashServerWeb do
    pipe_through :browser

    get "/", AuthController, :show
    post "/", AuthController, :login
  end

  scope "/commands", SlashServerWeb do
    pipe_through :browser
    pipe_through :session_auth

    #Command Group
    get "/", CommandGroupController, :show
    get "/new", CommandGroupController, :new
    get "/:name/edit", CommandGroupController, :edit

    post "/delete/:name", CommandGroupController, :delete
    post "/new", CommandGroupController, :create_or_update

    #Command
    get "/:command_group", CommandController, :show
    get "/:command_group/new", CommandController, :new
    get "/:command_group/:name/edit", CommandController, :edit

    post "/:command_group/new", CommandController, :create_or_update
    post "/:command_group/delete/:name", CommandController, :delete
  end

  scope "/slash", SlashServerWeb do
    pipe_through :api

    post "/", SlashController, :slash
  end

  # Other scopes may use custom stacks.
  # scope "/api", SlashServerWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: SlashServerWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
