# Cheap Reporting with Elixir, Oban, and Backblaze

Sometimes a project needs to generate reports, but doesn't have the budget for an appropriately sized database, or fast compute to generate reports, or even enough resources to export large amounts of data on the fly.

This is a strategy I've used a few times on low-budget and no-budget projects to implementing reporting.

My preferred form of "reporting" is to extract relevant fields from records in the database, maybe join on some other tables, maybe generate some stats on a per-record basis, and export the whole thing as a large downloadable CSV. This allows an admin download the report and perform their own ad-hoc analysis through their preferred data analysis tools (Python, R, Excel, Tableau, etc).

That means producing a large export with no sampling since we don't know exactly what the end-user will do with the data.

However, the strategy described in this post still works fine if all you want to do is generate some high-level stats or produce a sample of the data.

There are 3 steps in this setup:

- Run a batch processing job to generate the report
- Store the report
- Download the report from storage on-demand

## Report Generation Job

The first step is to create a background job that will generate our report. For this example, our report will be on the users in the system. The background job will run nightly through Oban and will gather all the data needed for the report. If you want to trade off increased load on your service for fresher data, it can be run hourly.

In this design it's alright if the job is extremely slow. It's running at night during off-peak hours and a user isn't waiting on the job to complete. For this example, I've set an hour long timeout, but it could be even higher if your service is very resource constrained.

```elixir
defmodule MyApp.Oban.ExportUsersToCsv do
  use Oban.Worker,
    queue: :csv_export,
    max_attempts: 1,

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{id: id}) do
    Logger.metadata(job_id: id)
    Logger.info("Starting cron for csv exporter")
    export_users_to_csv()
    :ok
  end

  # ...

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(60)
end
```

In your `config.exs` this job can be triggered with [Oban Cron](https://hexdocs.pm/oban/Oban.Plugins.Cron.html).

```elixir
config :my_app, Oban,
  repo: MyApp.Repo,
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       # Every day at 12:01 PM UTC
       {"1 12 * * *", MyApp.Oban.ExportUsersToCsv},
     ]}
  ],
  queues: [
    csv_export: 1,
  ]
```

For the `export_users_to_csv`, I recommend using streaming through `Repo.stream` so you don't need to hold all your results in memory at once.

```elixir
def export_users_to_csv do
  columns = ~w(id name email inserted_at)

  query = Accounts.query_users()
  stream = Repo.stream(query)

  Repo.transaction(
    fn ->
      stream
      |> Stream.map(fn user ->
        # this is a good point to enrich the row with additional data, rename
        # fields, or calculate stats
      end)
      |> CSV.build_csv_stream(columns)
      |> upload_csv_stream("users.csv")
    end,
    timeout: :infinity
  )
end
```

The CSV module I'm calling is a thin wrapper around [`nimble_csv`](https://hex.pm/packages/nimble_csv).

```elixir
defmodule MyApp.CSV do
  alias NimbleCSV.RFC4180, as: CSV

  def build_csv_stream(collection, columns) do
    header = Enum.map(columns, &Atom.to_string/1)
    content = maps_to_csv_rows(collection, columns)

    Stream.concat([header], content)
    |> CSV.dump_to_stream()
  end

  defp extract_fields_in_order(map, columns) do
    columns
    |> Enum.map(&Map.fetch!(map, &1))
  end

  defp maps_to_csv_rows(collection, columns) do
    collection
    |> Stream.map(fn row ->
      extract_fields_in_order(row, columns)
    end)
  end
end

```

For the `upload_csv_stream` function, I recommend streaming into a compressor to further reduce the size of your data. The [stream_gzip](https://hex.pm/packages/stream_gzip) library works well. This way the only content that you're storing in memory is the already gzipped CSV, ready for uploading.
CSVs tend to have high compression ratios since they're plain text with lots of repeated content. Also, the results from the database are being streamed, so only a few rows are held in memory at a time. This means that the memory footprint of the job is kept quite small.

If the size of your final compressed report exceeds the size of available memory, you could stream the file to your storage provider as it is created using a multi-part upload.

```elixir
defp upload_csv_stream(content, filename) do
  content
  |> StreamGzip.gzip()
  |> Enum.into("")
  |> B2.upload_file(filename <> ".gz")
end
```

## Report Storage

The next step is to take the generated data and put it in the cheapest storage available. We don't need redundancy since this isn't a database backup or important content. If the data center storing these files burns down then they can be regenerated.

At time of writing, [Backblaze](https://www.backblaze.com/) is the cheapest S3 compatible storage I've found and the first 10GB is free. I never went over that threshold for any of my projects.

If you are running your entire service on a single server with non-ephemeral storage attached (like a VPS with a disk or a physical server) then you may not even need an object storage provider. Just write your report directly to the disk and skip this step. In my case I'm often dealing with applications running on a PaaS, like Fly or Heroku, so I need a separate place to store the content.

I used [b2_client](https://github.com/keichan34/b2_client) for connecting to Backblaze, but B2 provides an S3 compatible API, so it might be better to use a different library, like [ReqS3](https://github.com/wojtekmach/req_s3).

```elixir
defmodule MyApp.B2 do
  defp get_config do
    Application.get_env(:my_app, MyApp.B2)
  end

  defp get_auth do
    if has_config?() do
      config = get_config()
      {:ok, auth} = B2Client.backend().authenticate(config[:key_id], config[:application_key])
      {:ok, bucket} = B2Client.backend().get_bucket(auth, config[:bucket])
      {:ok, auth, bucket}
    else
      {:error, :b2_not_configured}
    end
  end

  def upload_file(contents, path) do
    with {:ok, auth, bucket} <- get_auth() do
      B2Client.backend().upload(auth, bucket, contents, path)
    end
  end

  def download_file(path) do
    with {:ok, auth, bucket} <- get_auth() do
      {:ok, contents} = B2Client.backend().download(auth, bucket, path)
      contents
    end
  end
end
```

Config in `runtime.exs` looks like this:

```elixir
config :my_app, MyApp.B2,
  key_id: System.get_env("B2_KEY_ID"),
  application_key: System.get_env("B2_APPLICATION_KEY"),
  bucket: System.get_env("B2_BUCKET")
```

## Download On-Demand

The final step is to implement an endpoint that reads the report back out of Backblaze, when the user clicks the "download report" button.

Since the report is pre-computed the download starts right away and finishes quickly. The user doesn't have to wait for the several-minute long reporting job to run and it doesn't matter if the database is slow. The trade-off is getting data that is slightly out of date.

```elixir
defmodule MyAppWeb.ReportController do
  use MyAppWeb, :controller

  action_fallback MyAppWeb.FallbackController

  def users(conn, _) do
    send_file_from_b2(conn, "users.csv")
  end

  defp send_file_from_b2(conn, filename) do
    conn = send_csv_chunked(conn, filename)
    content = B2.download_file(filename <> ".gz")

    [content]
    |> StreamGzip.gunzip()
    |> Enum.reduce_while(conn, fn chunk, conn ->
      case Plug.Conn.chunk(conn, chunk) do
        {:ok, conn} ->
          {:cont, conn}

        {:error, :closed} ->
          {:halt, conn}
      end
    end)
  end

  defp send_csv_chunked(conn, filename) do
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header(
      "content-disposition",
      "attachment; filename=\"#{filename}\""
    )
    |> send_chunked(200)
  end
end
```

If you choose not to compress the file before upload, or don't mind having to manually decompress it after downloading, you can redirect them to a presigned download URL. This means the user will download directly from Backblaze, which means the contents of the file don't have to pass back through your service at all to be downloaded.

```elixir
def get_presigned_download_url(path, duration_seconds) do
  with {:ok, auth, bucket} <- get_auth() do
    url = "#{auth.api_url}/b2api/v2/b2_get_download_authorization"
    headers = [{"Authorization", auth.authorization_token}]

    body = %{
      bucketId: bucket.bucket_id,
      fileNamePrefix: path,
      validDurationInSeconds: duration_seconds
    }

    with {:ok, body} <- Jason.encode(body),
         {:ok, 200, _, client} <- :hackney.request(:post, url, headers, body),
         {:ok, response} <- :hackney.body(client),
         {:ok, response} <- Jason.decode(response) do
      "#{auth.download_url}/file/#{bucket.bucket_name}/#{path}?Authorization=#{Map.get(response, "authorizationToken")}"
    end
  end
end
```
