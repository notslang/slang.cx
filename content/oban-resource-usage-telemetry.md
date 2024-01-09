# Monitoring Oban Worker Memory and CPU Usage

[Oban](https://github.com/sorentwo/oban) is a great tool for running background jobs in Elixir. It also comes with a solid telemetry integration out of the box. However, that telemetry is missing one thing: an easy way to monitor the resource utilization of workers.

As a heavy user of Oban, I needed a way to pinpoint which jobs (out of hundreds in an application) were using up all the memory on a server. This is how I approached that problem.

## Taking Measurements

First, how do we measure resource utilization?

Your Elixir application is made up of many smaller processes running within the Erlang VM. Just as you can query info on OS level processes with a tool like `top`, you can query info on Erlang processes with [`process_info`](https://www.erlang.org/doc/man/erlang.html#process_info-2). Luckly for us, each Oban Worker is a separate process. That means we can use `process_info` to measure it.

Elixir provides a wrapper around this Erlang function called `Process.info/2` which we'll use because it looks nicer. You can try it out for yourself in `iex`. First we find the PID of the main Oban applicaton, then we pass it into the `info` function:

```elixir
iex> Process.whereis(Oban.Application) |> Process.info()
[
  registered_name: Oban.Application,
  current_function: {:erlang, :hibernate, 3},
  initial_call: {:proc_lib, :init_p, 5},
  status: :waiting,
  message_queue_len: 0,
  ...
```

The process info function returns a lot of information, but there are two keys in particular that are useful to us:

- `memory` - the amount of memory, in bytes, that a process occupies
- `reductions` - the number of function calls and BIF calls made within a process

The second one, `reductions`, is not directly equal to the CPU usage of the process. However, we don't have a `cpu_time` key, so number of reductions is as good as we're going to get from process info. More advanced [profiling tools](https://www.erlang.org/doc/efficiency_guide/profiling) are available, but not for passive stats collection.

We can get back just the two keys we care about with:

```elixir
iex> Process.whereis(Oban.Application) |> Process.info([:memory, :reductions])
[memory: 1736, reductions: 442]
```

## What Processes To Measure?

Next, we've got to find the Oban Worker processes that we want to take measurements from.

Internally Oban uses a registry called `Oban.Registry` to enable looking up Oban processes. Using this we can get all the jobs running on a queue by calling `Oban.Registry.whereis(Oban, {:producer, "default"})`. Here the queue we're searching for is `default`.

Inside the process state of each producer is a map containing all the workers that are running along with their PIDs. We can extract that with a call to `:sys.get_state`, using the PID returned by the registry.

There might be a more direct way to get the Oban executors, but if there is I haven't found it and it's not documented.

## Running the Measurements Periodically

The last piece required to get this working is a way to run our measurement code on a regular schedule. Thankfully Elixir comes with a pre-made solution for that: `telemetry_poller`. This package calls a `measurements` function every `peroid` milliseconds. Also, it comes with Phoenix by default!

## Putting it all Together

Putting all the pieces together, I came up with code that looks like this. In a freshly generated Phoenix project named example, the skeleton for this code would be located at `lib/example_web/telemetry.ex`.

```elixir
defmodule ExampleWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp periodic_measurements do
    [
      {Example.Telemetry, :measure_worker_memory, []}
    ]
  end

  def metrics do
    [
      summary("example.workers.memory.total", tags: [:worker])
    ]
  end

  def measure_worker_memory() do
    pid = Oban.Registry.whereis(Oban, {:producer, "default"})

    if is_pid(pid) and Process.alive?(pid) do
      %{running: running} = :sys.get_state(pid)

      Enum.map(running, fn {_ref, {pid, executor}} ->
        measure_memory(executor.job.worker, pid)
      end)
      # drop nils from workers we failed to check
      |> Enum.reject(&is_nil/1)
    else
      []
    end
    |> Enum.group_by(
      fn {worker, _memory} -> worker end,
      fn {_worker, memory} -> memory end
    )
    |> Enum.map(fn {worker, memory_list} ->
      # sum up the amount of memory used by all instances of the worker.
      # result will be zero if there are no active instances
      :telemetry.execute(
        [:example, :workers, :memory],
        %{total: Enum.sum(memory_list)},
        %{worker: worker}
      )
    end)
  end

  defp measure_memory(worker, pid) do
    try do
      memory =
        case Process.info(pid, [:memory]) do
          [memory: memory] -> memory
          _ -> 0
        end

      {worker, memory}
    catch
      # sometimes the process will still exist in the registry after it has
      # exited, causing the above code to fail
      :exit, _ -> nil
    end
  end
end
```

## A Note About Cardinality

In the `metrics` function of the example above, you'll notice that the only tag I'm reporting is the name of the Oban worker module (`:worker`). This means that the memory usage of all runs from the same worker are compiled together when generating statistics.

You may be tempted to emit metrics that are more granular, like tagging by Oban job id so you can see the memory usage of each individual Oban job over time. However, this will cause problems due to the cardinality of your metrics. Cardinality is the number of distinct items in a set. In terms of metrics, the set we're talking about is the set of possible tags for a metric (or the intersection of sets of tags).

So, if your tag is the name of the worker module and you have 100 different worker modules in your system, then you have a cardinality of 100 (pretty reasonable). If your tag is the job id, then your cardinality is equal to the number of jobs that your system runs, which is unbounded and could easily be billions.

Having a very high cardinality becomes a problem in aggregating metrics because each individual tag (or combination of tags) needs to have stats aggregated separately. For example, to get an average we would have to track the count and sum for each combination of tags. With a cardinality of 100, that hardly takes up any memory at all. With an unbounded cardinality your memory usage grows forever.


- implement with telemetry + phoenix live dash, but mention that results can be exported into graphana or datadog
- talk about cardinality of metrics (why you don't want to use job ID as a tag)
- code examples for setting up telemetry
- structure of Oban workers and which processes to monitor
