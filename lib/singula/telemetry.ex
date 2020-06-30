defmodule Singula.Telemetry do
  require Logger

  def log([:singula, :respons], %{response: response}, _meta_data, _config) do
    Logger.debug("Singula response: #{inspect(response)}")
  end

  def log(_event, _measurement, _meta_data, _config), do: nil

  def librato([:singula, :response, :time], %{time: time}, %{name: name}, _config) do
    Logger.info("measure#singula.#{name}=#{time}ms")
  end

  def librato(_event, _measurement, _meta_data, _config), do: nil
end
