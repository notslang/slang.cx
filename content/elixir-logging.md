# Elixir Logging

Elixir comes with a powerful and well-designed log system out of the box, but it's often underutilized. These are some of my favorite features.

If you [generate](https://hexdocs.pm/phoenix/up_and_running.html) a new Elixir/Phoenix project, your logs will look like this by default:

```
[info] Running HelloWeb.Endpoint with Bandit 1.6.3 at 127.0.0.1:4000 (http)
[info] Access HelloWeb.Endpoint at http://localhost:4000
[info] GET /
[info] Sent 200 in 3ms
[info] GET /
[info] Sent 200 in 406µs
```

That's plenty for new project, but with a little customization, it is able to do so much more.

## Metadata

Elixir's Logger module has a clean interface for [attaching metadata](https://hexdocs.pm/logger/Logger.html#module-metadata). You can attach metadata to an individual log message:

```elixir
Logger.info("something happened", my_error_code: 42)
```

Or attach metadata to all future logs that a process will emit:

```elixir
Logger.metadata(batch_job_id: 1234)
```

This works well with Telemetry events too. Telemetry events are handled within the process that emitted them, so content from Telemetry events can be used to setup Logger metadata.

For example, when I'm working on a project that uses [Oban](https://oban.pro/), I like to register a telemetry handler for the `[:oban, :plugin, :stop]` event that registers the job ID as Logger metadata for the duration of the job execution:

```elixir
def handle_event([:oban, :job, :start], _measure, %{job: job}, _) do
  Logger.metadata(job_id: job.id)
end
```

This way I can group all the logs that came from a given instance of a job. Additional Logger metadata can be pulled out of the job args too.

## Default Metadata

By default, each log message is tagged with the file name, line number, module, and function where the logger call occurred. This means that even in a large code base with not-quite-unique (copy pasted) log messages, you can track down exactly where an error log was produced.

This is also a good reason to call the `Logger` module functions directly in your code. If you attempt to create a custom wrapper for it then that will clobber the log message metadata and all log messages will appear as though they're coming from your wrapper.

See the [docs](https://hexdocs.pm/logger/Logger.html#module-metadata) for a full list of default metadata keys.

## Plug Metadata

Some libraries in Elixir automatically add to the Logger metadata. For example [`Plug.RequestId`](https://hexdocs.pm/plug/Plug.RequestId.html) automatically adds a unique `request_id` to the Logger metadata for the process handling the request.

By default, a newly generated project will only emit this piece of metadata, based on the config in `config/confix.exs`:

```elixir
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]
```

## JSON Logger

The logging system also has configurable backends and configurable formatters. You can use a package like [LoggerJSON](https://hexdocs.pm/logger_json/LoggerJSON.html) to format logs as JSON, which can be set to print all metadata, if `metadata: :all` is set.
