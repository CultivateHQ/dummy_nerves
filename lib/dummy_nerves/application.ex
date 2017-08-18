defmodule DummyNerves.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Registry, [:duplicate,  Nerves.Udhcpc]),
    ]

    opts = [strategy: :one_for_one, name: DummyNerves.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
