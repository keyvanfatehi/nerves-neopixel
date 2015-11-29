defmodule Codelock.Router do
  use Plug.Router

  plug Plug.Logger
  plug :match
  plug Plug.Parsers, parsers: [:urlencoded, :json], json_decoder: Poison
  plug :dispatch

  def start_link do
    {:ok, _} = Plug.Adapters.Cowboy.http Codelock.Router, []
  end

  post "/activate" do
    %{"pin" => pin} = conn.params
    if Codelock.unlock(pin) do
      send_resp(conn, 200, "")
    else
      send_resp(conn, 401, "")
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end

defmodule Codelock do
  require Gpio

  @pin Application.get_env :codelock, :pin, "0000"

  def unlock(@pin) do
    {:ok, pid} = Gpio.start_link(18, :output)
    Gpio.write(pid, 1)
    IO.puts "Opened"
    :timer.sleep 1000
    Gpio.write(pid, 0)
    IO.puts "Closed"
    Process.exit(pid, :kill)
    true
  end

  def unlock(_) do
    IO.puts "Wrong PIN"
    false
  end
end

defmodule Neopixel.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [
      worker(Ethernet, []),
      worker(Codelock.Router, [])
    ]
    supervise(children, strategy: :one_for_one)
  end
end

defmodule Neopixel do
  use Application
  require Logger

  def start(_type, _args) do
    IO.puts "Hello Nerves"
    Neopixel.Supervisor.start_link
  end

end
