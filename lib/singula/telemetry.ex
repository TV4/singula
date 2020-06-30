defmodule Singula.Telemetry do
  require Logger

  def attach_singula_response_logging do
    :telemetry.attach("singula-response-logging", [:singula, :response], &handle_event/4, nil)
  end

  def attach_librato_response_time do
    :telemetry.attach("librato-response-time", [:singula, :response, :time], &handle_event/4, nil)
  end

  def emit_response_event(response) do
    :telemetry.execute([:singula, :response], %{response: response})
  end

  def emit_response_time(name, time) do
    :telemetry.execute([:singula, :response, :time], %{time: time}, %{name: name})
  end

  def handle_event([:singula, :response], %{response: response}, _meta_data, _config) do
    Logger.debug("Singula response: #{inspect(response)}")
  end

  def handle_event([:singula, :response, :time], %{time: time}, %{name: name}, _config) do
    Logger.info("measure#singula.#{name}=#{time}ms count#singula.#{name}=1")
  end

  def handle_event(_event, _measurement, _meta_data, _config), do: nil
end
