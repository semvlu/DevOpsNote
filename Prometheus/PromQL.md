# PromQL
- Data type atm (ts): float or native histogram
- Native histogram incl.: count, sum, buckets

## Metric Types
- Counter: single mono incr. counter.
- Gauge: single num value qui go up and down.
- Histogram: samples & counts observations in buckets. Buckets config-ed per label: `le`.
    - Base metric name: `<base>`
    - Cumulative counter for the bucket: `<base>_bucket{le="<upper-inclusive-bound>"}`
    - Sum: `<base>_sum`
    - Count: `<base>_count`. Equiv `<base>_bucket{le="+Inf"}`

## Jobs & Instances
`up{job="<job-name>", instance="<instance-id>"}`

## Expr Lang Data Types
Instant vector: set of time series (dim) containing a 1 sample (elem) for each time series (dim), all sharing the *same ts*, i.e. at the same moment.

Range vector: set of time series (dim) containing a range of data points over time for each time series (dim). dim(range-vec) = dim(instant-vec) + 1.

Scalar: float

*P.S.* sample = data point

## Literals
String: escape chars: `\n \t`, etc. processed in single & double quotes: `''` & `""`, but not backticks: ` `` `

Scalar & Time duration: `_` for readability, e.g. `1_000_000`. 20ms, 1h30s 

## Time Series Selector
### Instant Vector
`http_requests_total`: select all time series that have the http_requests_total metric name, returning the most recent sample for each.

Label matcher qua Filtre: `{lbl1="val", lbl2="val"}`
- Match operator: `= !=`, `=~ !~`: regex match / unmatch
- Empty matcher: `{method=""}` will select all time series w/o the label, in casu `method`. But will not select time series w/ the label, e.g. `{method="GET"}`
- Match time series w/ the label: `{job=~".+"}`
- Select metrics w/ prefix `http_requests_`: `{__name__=~"http_requests_.*"}`
```
http_requests_total{environment=~"staging|testing|development",method!="GET"}
```

### Range Vector: `[<time-duration>]`: 30s, 5m, 2h
`http_requests_total{method="GET"}[5m]`

### Offset Modifier
`sum(http_requests_total{method="GET"} offset 5m)`

Negative offset moves forward: `offset -1w` show 1 week after the ts.

### @ Modifier
- Use UNIX ts
- `http_requests_total @ 1609746000`: @ 2021-01-04T07:40:00+00:00
- `start()` & `end()` qua `@` modifier val.


## Operator
### Vector Matching: `on`, `ignore`

Syntax: 
```
<vec expr> <bin-op> [on|ignoring](<lbl list>) <vec expr>

method_code:http_errors:rate5m{code="500"} / 
ignoring(code) method:http_requests:rate5m
```
### Group Modifier
`group_left`: N-to-1

`group_right`: 1-to-N

Syntax:
```
<vec expr> <bin-op> [on|ignoring](<lbl list>) 
[group_left|group_right](<lbl list>) <vec expr>

method_code:http_errors:rate5m / 
ignoring(code) 
group_left method:http_requests:rate5m
```

**Modifiers need to follow the selector immediately**

### Aggregation Operators
`sum()`, `avg()`, `max()`, `min()`

`topk(k,v)`, `bottomk(k, v)`
- `topk(5, memory_consumption_bytes)`

`qunatile(φ, v)`: return the φ-quantile, φ=0.5: mean, 0 <= φ <= 1.

Syntax:
```
<aggr-op>([prm,] <vec expr>) [without|by (<lbl list>)]
```

`without` removes listed/spec. labels from the result vector.

`by` drops labels not listed/spec. labels in the `by` clause.

## Function
`delta(range-vec)`: delta b/w 1e & last elem
- e.g. `delta(cpu_temp_celsius{host="server-1"}[2h])`


### Rate funcs
`rate(range-vec)`: per-sec avg rate of incr. of the time series in the range vector.
- Scenarios: alerting, and graphing of slow-moving counters.

`irate(range-vec)`: per-sec instant rate of incr. of the time series in the range vector. Based on last 2 data points.
- Scenarios: graphing volatile, fast-moving counters.

Rate funcs. only be used w/ counters. 

*N.B.* When combining Rates funcs w/ aggregators, viz. aggr operator (`sum()`) or a func aggr over time (any func w/ suffix `_over_time`): Take Rate funcs first, then aggregate. Otherwise cannot detect counter resets when target restarts. e.g. `sum(rate(errors[5m]))`

---

`<aggregation>_over_time(range-vec)`: `<aggregation>` be any aggr operators.
- e.g. `sum_over_time(range-vec)`: sum of all values time range.


### Histogram funcs
`historgram_avg(instant-vec)` = `histogram_sum(instant-vec) / histogram_count(instant-vec)`

`histogram_count(instant-vec)` & `histogram_sum(instant-vec)`

`histogram_quantile(φ, range-vec)`


## Examples
```
sum(node_memory_MemAvailable_bytes{cluster="local-cluster"}) by (instance)

max(thanos_objstore_bucket_last_successful_upload_time) # Check upload to obj storage (S3, Azure storage)

node_cpu_utilisation_percentage
```