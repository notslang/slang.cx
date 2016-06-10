Back in September of 2014, I started using a time-tracking plugin called [WakaTime](https://wakatime.com). The idea behind it is pretty simple: it sends a heartbeat once every 2 minutes while you're using your editor (or any other application that the plugin is installed in) letting you calculate total time spent on a given project/branch/file. Based on this data, and a few other helpful statistics, WakaTime generates a weekly email to show you what you've been working on and for how long.

All of the editor plugins are free software, while the server that collects the data is a proprietary system. This means that the only logic that users don't get to see is the part that aggregates heartbeats into durations of time spent on projects, and the dashboard stuff. The fact that WakaTime doesn't let me run my own server or manage my own data has been annoying. But thanks to the relatively minimal logic that the server does, and the fact that the API that lets me export all the heartbeats I've sent, I can

```json
{
  "mappings": {
    "heartbeat": {
      "properties": {
        "time": {
          "type": "date",
          "format": "epoch_millis"
        },
        "entity": {
          "type":  "string",
          "index": "not_analyzed"
        },
        "branch": {
          "type":  "string",
          "index": "not_analyzed"
        },
        "branch": {
          "type":  "string",
          "index": "not_analyzed"
        },
        "project": {
          "type":  "string",
          "index": "not_analyzed"
        },
        "language": {
          "type":  "string",
          "index": "not_analyzed"
        },
        "machine_name_id": {
          "type":  "string",
          "index": "not_analyzed"
        },
        "user_agent_id": {
          "type":  "string",
          "index": "not_analyzed"
        },
        "type": {
          "type":  "string",
          "index": "not_analyzed"
        },
        "type": {
          "type":  "string",
          "index": "not_analyzed"
        }
      }
    }
  }
}
```
